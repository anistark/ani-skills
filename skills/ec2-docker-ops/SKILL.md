---
name: ec2-docker-ops
description: >
  Day-two runbook for a Dockerised backend on an EC2 box behind nginx, deployed from GitHub Actions over SSM: diagnose why the site is down or a deploy failed, read the right logs, redeploy or roll back to a previous image tag, rerun a failed workflow, fix SSM registration, renew TLS, free disk. Use this whenever someone says the API is down, returns 502 or 404, the deploy job went red, "it worked yesterday", asks how to roll back, or wants to check that production is healthy, even if they do not mention Docker, nginx, or SSM. Start with scripts/check-stack.sh before touching anything.
---

# Operating a Dockerised backend on EC2

The stack has seven layers and a failure lives in exactly one of them. Find the layer first, then act. Guessing and restarting things loses the evidence.

```
DNS -> TLS -> nginx -> container -> app -> database
                 ^ deploy pipeline (GitHub Actions -> ECR -> SSM -> deploy.sh)
```

## Before you start: access

Diagnosis is only as good as what you can see. `check-stack.sh` prints an Auth section first: whether `gh` is logged in and what it can do on `--repo`, and which AWS account and identity the CLI is using. Read it before the rest, because a red pipeline or SSM line under a failed login says nothing about production.

- **GitHub**: `gh auth status`. Reading runs needs read on the repo; `gh run rerun` needs write.
- **AWS**: `aws sts get-caller-identity` must show the account that owns the instance. SSM checks need `ssm:DescribeInstanceInformation`; running commands needs `ssm:SendCommand`. An expired session shows up as expired or missing credentials: the user runs `aws login`, `aws sso login`, or `aws configure`.
- **The box**: `aws ssm start-session --target <instance-id>` (needs the Session Manager plugin for the CLI) or ssh with the instance's key. Every procedure in Step 3 needs one of these.

Never log in on the user's behalf. Tell them the command, and if a check cannot run for lack of access, say so in the report rather than dropping it silently.

## Step 1. Gather, do not touch

Run `scripts/check-stack.sh` from a machine with the tools it can find (it skips checks whose tool or argument is missing):

```sh
check-stack.sh --host <api-hostname> --app <app> [--instance <id> --region <r>] [--repo <org/repo> --workflow <file>] [--ssh user@host --key ~/.ssh/key]
```

It reports DNS, http and https health, certificate expiry, the latest workflow run, SSM ping status, the image tag actually running, and container status. Read the whole report before forming a theory. Then `references/troubleshooting.md` maps each symptom to its cause.

## Step 2. Reading the layers

| Observation | Layer | Look at |
|---|---|---|
| Name does not resolve or resolves to an old IP | DNS | Zone record, Elastic IP association |
| https fails, http works | TLS | `certbot certificates`, DNS must resolve first |
| nginx welcome page or 404 | nginx | Site enabled? default removed? `nginx -t` |
| 502 | container | `docker compose ps`, `docker compose logs --tail 100 backend` |
| 500 or app error body | app | Same logs; env file values; migration state `alembic current` |
| App up but writes fail | database | `sudo -u postgres psql`, disk space, role ownership |
| Deploy job red | pipeline | Which step: credentials, build, or SSM; see below |

## Step 3. Procedures on the box

All paths assume `/opt/<app>` with `deploy.sh`, `docker-compose.yml`, `<app>.env`, and `.env` holding the current `APP_IMAGE`.

- **Logs**: `cd /opt/<app> && sudo docker compose logs -f --tail 200 backend`
- **Which image is live**: `cat /opt/<app>/.env` and `docker ps --format '{{.Image}} {{.Status}}'`
- **Redeploy the same image** (config change, stuck container): `sudo ./deploy.sh $(grep APP_IMAGE .env | cut -d= -f2)`
- **Roll back**: `sudo ./deploy.sh <registry>/<repo>:<older-sha>`. Tags are commit SHAs; `git log --oneline main` on the repo gives candidates. Migrations are not rolled back by this; if the bad release migrated, restore the pre-deploy dump from `/opt/<app>/backups/` into a fresh database first (see the `postgres-s3-backup` skill).
- **Env change**: edit `<app>.env` with sudo, then redeploy the same image. Changing the secret key logs every user out; say so before doing it.
- **Disk full**: `docker system df`, `docker image prune -af` (deploy.sh already prunes dangling images), old dumps in `backups/`, `journalctl --vacuum-size=200M`.
- **Certificate**: `sudo certbot renew --dry-run`; the timer is `systemctl status certbot.timer`.
- **nginx**: `sudo nginx -t && sudo systemctl reload nginx`. Never restart while unsure; reload keeps the old config if the new one is broken.

## Step 4. Pipeline failures

`gh run list --workflow <file> -R <org/repo> --limit 5`, then `gh run view <id> --json jobs` to see which step failed, then `--log-failed`.

- **configure-aws-credentials**: OIDC trust mismatch or the secret missing on the environment. See the troubleshooting table.
- **build-push**: usually a Dockerfile change; reproduce with a local build from the repo root.
- **SSM step, `InvalidInstanceId`**: agent not registered. On the box `sudo snap restart amazon-ssm-agent`, then `aws ssm describe-instance-information` until `PingStatus` is `Online`.
- **SSM step ran but deploy.sh failed**: the step prints the script's stdout and stderr; the error is there. Fix on the box, then `gh run rerun <id> --failed`.

A rerun re-executes only the failed job and reuses the built image when the build job already passed.

## Step 5. Close the loop

After any fix, run `check-stack.sh` again and confirm every line is green, then tell the user what was wrong in one sentence and what would have caught it earlier. Add anything new to the troubleshooting table.

## Keeping this skill current

Cloud CLIs, GitHub Actions and package names move faster than this file. Treat any mismatch between what this skill says and what a tool does as a signal, not noise: an unknown flag or subcommand, a deprecation warning in a command or workflow log, an action warning about its Node runtime, a console page or setting that is not where the skill says, a package that no longer exists, or a login hint naming a different command.

When that happens:

1. Stop guessing. Fetch the current official documentation for that tool (sources below) or the action's latest release, not a blog post or memory.
2. Finish the task with the documented current form and tell the user in one line what changed.
3. At the end, propose an improvement to this skill: the file, the old text, the new text, the source URL, and the date checked. Do not edit the skill's files without the user's go-ahead. A plugin install is overwritten on update, so for those suggest a pull request or issue on https://github.com/anistark/ani-skills instead of a local edit.

Sources for this skill:

- AWS CLI reference: https://docs.aws.amazon.com/cli/latest/reference/ (ssm, sts, ecr)
- SSM Agent and Session Manager: https://docs.aws.amazon.com/systems-manager/
- gh CLI manual: https://cli.github.com/manual/ (`gh run`, `gh auth`)
- Docker and Compose CLI: https://docs.docker.com/reference/cli/docker/
- certbot: https://eff-certbot.readthedocs.io
- nginx: https://nginx.org/en/docs/

Fixes to `scripts/check-stack.sh` and new rows for `references/troubleshooting.md` go in the same proposal. A new failure that took more than one step to diagnose is always worth a troubleshooting row.
