---
name: fastapi-ec2-deploy
description: >
  Set up production deployment for a FastAPI (or any Python ASGI) backend as a Docker image on a single AWS EC2 instance, built and shipped by GitHub Actions on every push to the main branch, with Postgres kept outside Docker so no data is lost between deploys. Use this whenever someone asks how to deploy, host, ship, or "put on a server" a Python API, wants CI/CD for a backend, asks about EC2 plus Docker plus GitHub Actions in any combination, or asks where the database should live for a small deployment. Also use it when they only ask for a Dockerfile or a deploy workflow for a FastAPI app, since those pieces only work when designed together. Covers exploring the repo first, the Dockerfile, compose, nginx and TLS, the deploy and backup scripts, the AWS resources (ECR, IAM, OIDC, SSM), the workflow, the first deploy, and the optional Vercel frontend wiring.
---

# FastAPI on EC2 with Docker and GitHub Actions

The target shape is deliberately boring: one EC2 box, one backend container on host networking, Postgres and nginx installed on the host, TLS from certbot, images in ECR, deploys triggered by GitHub Actions and executed on the box over SSM. It costs about $20 a month, survives redeploys without touching data, and every piece can be inspected with ssh and curl. Reach for something fancier only when the user has a reason.

Work through the phases in order. Each one produces something checkable before the next starts, which is what makes the final "why is it not working" question answerable.

## Before you start: access

Each phase needs different access. Check it when the phase begins, not all up front, and never log in on the user's behalf: logins are interactive and belong to the user, so tell them the command to run.

| Needed for | Check | Expect | If not |
|---|---|---|---|
| Phase 3 smoke test | `docker info` | Server section present | Start Docker Desktop, Colima, or the daemon |
| Phase 4 AWS resources | `aws sts get-caller-identity` | The account the user means, an identity that can create IAM roles | `aws login`, `aws sso login`, or `aws configure`; confirm the account ID with the user before creating anything |
| Phase 4 GitHub environment | `gh auth status` and `gh api repos/<org>/<repo> --jq .permissions.admin` | Logged in, `true` | `gh auth login`; environments and their secrets need admin on the repo |
| Pushing the workflow file | `gh auth status` scopes | `workflow` scope, if pushing over HTTPS with the gh token | `gh auth refresh -s workflow` |
| Phase 5 server | `aws ssm start-session --target <instance-id>`, or ssh with the key | A shell on the box | Install the Session Manager plugin for the CLI, or use the key the instance launched with |
| Phase 4 region | `aws configure get region` | The region agreed in Phase 2 | Pass `--region` or export `AWS_REGION` |
| Frontend on Vercel (optional) | `vercel whoami` | The team that owns the project | `vercel login`, or do it in the dashboard |

The wrong AWS account is the expensive mistake here: a bootstrap run creates IAM roles wherever the credentials point. Show the account ID and identity ARN to the user and get a yes before Phase 4.

## Phase 1. Explore before designing

Nothing in the later phases is safe to write until these facts are known. Read the code; do not guess from the framework name.

1. **Entry point and server.** Where is the ASGI app (`app.main:app` or similar)? Is the package manager uv, poetry, or pip with a lockfile? Which Python version does `pyproject.toml` require? The Dockerfile base image and install step follow from this.
2. **Configuration.** How does the app read settings? Look for pydantic-settings, an env prefix, a `.env.example`. Every setting with a placeholder default (JWT secret, database URL) becomes a line in the server's env file.
3. **Runtime files on disk.** Grep for `Path(__file__)`, `parents[N]`, `os.path.dirname` and any folder the app reads at request time (content, templates, uploads, review queues). Those folders must be inside the image or on a mounted volume, and code that walks up from `__file__` to find the repo root breaks if the image flattens the layout. Mirror the repo layout inside the image when you see this pattern.
4. **Migrations.** Alembic, or something else? Where does it read the database URL from? The deploy script runs migrations as a one-shot container before restarting.
5. **Tests and their dependencies.** Do tests need a live Postgres (a migration test usually does)? What connection defaults do they assume? CI needs a Postgres service and matching `PGUSER`/`PGPASSWORD` env vars when tests connect as the OS user.
6. **Repo layout.** Monorepo with the backend in a subfolder? Then the Docker build context is the repo root and the Dockerfile lives next to the backend. Any sibling folder the app reads from must be in that context.
7. **Frontend, if any.** Does it call the API with relative `/api/...` paths or an absolute base URL? Cookies or bearer tokens? This decides between same-origin rewrites and CORS. See `references/frontend.md`.
8. **What already exists.** Existing Dockerfiles, workflows, CI, `.dockerignore`, and the commit style on main, so new files match.

Summarise the findings back to the user in a few lines before writing anything. The decisions below hinge on them, and users often correct a wrong assumption at this point (the wrong instance architecture, a folder you did not know was read at runtime, a database that must not move).

## Phase 2. Decide the shape with the user

Present these as recommendations with the reason, then let the user choose:

- **Database on the host, not in Docker, not RDS** for a small internal app. Deploys replace a container and never see the data directory. RDS is the upgrade path when backups, failover, or a second box matter more than $15 a month.
- **One container, host networking.** `network_mode: host` means `localhost:5432` works with no bridge network or `pg_hba.conf` changes, and nginx on the host proxies to `127.0.0.1:8000`. Bind uvicorn to 127.0.0.1 so the app is never exposed directly.
- **Image tagged with the commit SHA and `latest`.** Rollback is redeploying an older SHA. Keep the last 20 in ECR with a lifecycle rule.
- **Deploy over SSM, not SSH.** No key in GitHub secrets, no port 22 needed for CI. The instance role grants SSM; the GitHub role may only send commands to that one instance.
- **OIDC for GitHub to AWS.** No long-lived access keys anywhere.
- **Migrations run on every deploy.** Alembic is a no-op at head, and "only if needed" logic is more code than the thing it guards.
- **A database dump before every migration, kept 14 days on the box, plus a nightly dump to a write-only S3 bucket.** Cheap insurance against a destructive migration.
- **Frontend**: same-origin rewrite from the hosting platform to the API when the client uses relative paths (zero code changes, no CORS); otherwise a build-time API URL plus `CORS_ORIGINS` on the backend. Details in `references/frontend.md`.

Also settle: the API hostname, the AWS region, and instance architecture. GitHub runners build amd64 images; pick an x86 instance type (t3.small is plenty for a small API) or add `platforms: linux/arm64` with QEMU to the build, which is slower. Mixing these up produces an `exec format error` at first deploy.

## Phase 3. Write the files

Copy the templates from `assets/` and adapt them to the findings from Phase 1. Placeholders in the templates are `<app>` for the service name, `<api-hostname>`, and `<region>`. Keep names generic and never bake in account IDs, instance IDs, hostnames, or secrets: those belong in the GitHub environment, the server's env file, or the DNS zone.

| File | Purpose | Notes |
|---|---|---|
| `assets/Dockerfile` | Backend image | Build from repo root. Uses uv; swap the install lines for pip or poetry as found. Copies runtime data folders. Mirrors repo layout if code derives paths from `__file__`. |
| `assets/Dockerfile.dockerignore` | Build context filter | BuildKit reads `<Dockerfile>.dockerignore` next to the Dockerfile, so a monorepo needs no root `.dockerignore`. Exclude tests, venvs, `.env`. |
| `assets/docker-compose.yml` | What runs on the box | Host networking, `env_file`, `restart: unless-stopped`, image from `${APP_IMAGE}`. |
| `assets/deploy.sh` | Runs on the box | ECR login via instance role, pull, pre-deploy `pg_dump`, migrate, `up -d`, health poll, prune. Takes the full image reference as its one argument. |
| `assets/nginx.conf` | Site config | Plain port 80 proxy; certbot rewrites it for TLS. |
| `assets/app.env.example` | Server env file | One line per setting found in Phase 1, plus the backup bucket. |
| `assets/workflow.yml` | GitHub Actions | Test jobs on PRs and pushes; build, push, and deploy on push to main. |

Rules that came from real failures:

- Build the image locally from the repo root and run a smoke test before committing: import the app, check the runtime folders resolve, run `alembic upgrade head` against a throwaway Postgres container, curl the health endpoint. The layout bug in Phase 1 item 3 only shows up here.
- Use `paths:` filters on the workflow so unrelated pushes do not redeploy.
- Gate the deploy job on `environment: production`. The OIDC trust policy is scoped to that environment name, and required reviewers can be added later without touching the workflow.
- The SSM step must poll `get-command-invocation` in a loop and print the command's stdout and stderr at the end. `aws ssm wait command-executed` gives up after about 100 seconds, which a deploy with an image pull can exceed, and without the output every failure reads as "exit code 254".
- Write a `deploy/README.md` with the one-time setup, the layout on the box, and the rollback command. The user will follow it months later without this conversation.

Add a short pointer to the deploy README from the project's main README.

## Phase 4. AWS resources

Follow `references/aws-setup.md`. It has the console steps and `scripts/aws-bootstrap.sh`, an idempotent CLI script that creates the ECR repo, the backup bucket, the instance role, the GitHub OIDC role, and sets the GitHub environment values in one run. Run it only with the user's explicit go-ahead: it creates IAM roles in their account.

Two things bite here:

- **GitHub's immutable subject claim.** Repos that have it enabled present the OIDC subject as `repo:<org>@<org-id>/<repo>@<repo-id>:environment:<env>`, not the plain `repo:<org>/<repo>:environment:<env>`. Query it with `gh api repos/<org>/<repo>/actions/oidc/customization/sub` and put both forms in the trust policy. The symptom is "Not authorized to perform sts:AssumeRoleWithWebIdentity".
- **The SSM agent registers only after it sees the instance role.** Attaching the profile to a running instance is not enough; restart the agent (`sudo snap restart amazon-ssm-agent` on Ubuntu) and confirm with `aws ssm describe-instance-information`. Until then `send-command` fails with "Instances not in a valid state for account".

## Phase 5. Server setup

Follow `references/server-setup.md`. The order matters: packages, Postgres role and database with the app role as owner, files into `/opt/<app>` with execute bits, env file filled and locked to mode 600, nginx site enabled and the default site removed, Elastic IP, DNS, certbot, backup cron. Verify with curl at each step; the reference lists what each status code means.

## Phase 6. First deploy and proof

1. Merge or push to main so the workflow builds and pushes an image. The deploy step will fail until the box is registered with SSM; that is fine, the image is in ECR.
2. On the box, run `deploy.sh` by hand with the `latest` image once. Fix whatever it reports (the `ec2-docker-ops` skill has the symptom table), then create the first admin user or run whatever bootstrap command the app has.
3. Rerun the failed workflow job with `gh run rerun <id> --failed`. When it goes green, confirm on the box that the running container is the SHA-tagged image and that a pre-deploy dump exists. That is the end-to-end proof.
4. Point the frontend at the API and test a real request through it, not just the health endpoint. A 502 from a rewrite usually means the API has no TLS yet.

Report to the user what is proven, what is configured but untested, and what remains. Typical leftovers: admin user, backups (Phase 7), closing port 22 once SSM works.

## Phase 7. Backups

Hand over to the `postgres-s3-backup` skill: it installs the nightly dump script and cron, proves the upload from operator credentials (the instance role is write-only, so listing from the box is denied by design), and runs a restore drill while the data is still small. The pre-deploy dump in `deploy.sh` covers the migration case.

## When things go wrong, then and later

Use the `ec2-docker-ops` skill. Its `check-stack.sh` gives an outside-in report of DNS, TLS, nginx, the container, SSM, and the last workflow run, and its troubleshooting table maps every failure hit while building this: 404 versus 502 from nginx, Postgres schema permissions on 15+, missing execute bits, the OIDC subject mismatch, SSM registration, arm64 versus amd64. Point the user at it for rollbacks too.

## Keeping this skill current

Cloud CLIs, GitHub Actions and package names move faster than this file. Treat any mismatch between what this skill says and what a tool does as a signal, not noise: an unknown flag or subcommand, a deprecation warning in a command or workflow log, an action warning about its Node runtime, a console page or setting that is not where the skill says, a package that no longer exists, or a login hint naming a different command.

When that happens:

1. Stop guessing. Fetch the current official documentation for that tool (sources below) or the action's latest release, not a blog post or memory.
2. Finish the task with the documented current form and tell the user in one line what changed.
3. At the end, propose an improvement to this skill: the file, the old text, the new text, the source URL, and the date checked. Do not edit the skill's files without the user's go-ahead. A plugin install is overwritten on update, so for those suggest a pull request or issue on https://github.com/anistark/ani-skills instead of a local edit.

Sources for this skill:

- AWS CLI reference: https://docs.aws.amazon.com/cli/latest/reference/ (ecr, iam, ssm, s3api, ec2)
- GitHub OIDC with AWS and environments: the "Configuring OpenID Connect in Amazon Web Services" and "Managing environments for deployment" pages on https://docs.github.com
- Actions used in `assets/workflow.yml`: the releases page of each (`actions/checkout`, `astral-sh/setup-uv`, `aws-actions/configure-aws-credentials`, `aws-actions/amazon-ecr-login`, `docker/setup-buildx-action`, `docker/build-push-action`)
- uv in Docker: https://docs.astral.sh/uv/guides/integration/docker/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- certbot: https://eff-certbot.readthedocs.io
- Vercel rewrites: https://vercel.com/docs

One cheap drift check to run every time, before copying `assets/workflow.yml`: `gh api repos/<owner>/<action>/releases/latest --jq .tag_name` for each action above. If a major version moved, read its release notes, use the new major if nothing in this workflow breaks, and include it in the skill improvement you propose.
