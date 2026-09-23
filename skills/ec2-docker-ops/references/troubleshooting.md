# Symptoms and causes

| Symptom | Cause | Fix |
|---|---|---|
| `IndexError` from `Path(__file__).parents[N]` at import time in the container | Code walks up to the repo root; the image flattened the layout | Mirror the repo layout in the image (`WORKDIR /srv/<repo>/<backend>`), copy sibling folders to the matching place |
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | Trust policy subject does not match; repo likely has the immutable subject claim | Add the `repo:<org>@<id>/<repo>@<id>:environment:<env>` form to the trust policy |
| `Input required and not supplied: role-to-assume` | Secret missing or set at repo level while the job uses an environment | Set it as an environment secret on the named environment |
| `InvalidInstanceId ... Instances not in a valid state for account` | Instance not registered with SSM | Attach the instance profile, restart the agent, wait for `PingStatus: Online` |
| `sudo: cannot execute deploy.sh: Permission denied` | Execute bit lost when copying | `chmod +x` |
| `grep: <app>.env: Permission denied` | File is mode 600 root | Read it with sudo; the deploy script already runs as root |
| `FATAL: database "<app>" does not exist` | Database not created | `CREATE DATABASE <app> OWNER <app>` |
| `permission denied for schema public` on the first migration | Postgres 15+ and the role does not own the database | `ALTER DATABASE ... OWNER TO`, `ALTER SCHEMA public OWNER TO` |
| nginx returns the welcome page | Site not enabled or default site still present | Enable the site, remove the default, reload |
| 502 through nginx | Backend not running or wrong port | `docker compose logs backend`; check the port in compose, nginx, and the health check match |
| Frontend rewrite returns 502 while direct http works | Rewrite targets https and there is no certificate | Run certbot after DNS resolves |
| `exec format error` when the container starts | Image built for amd64, instance is arm64 (Graviton) | Use an x86 instance or add `platforms: linux/arm64` with QEMU to the build |
| `Your session has expired` from the AWS CLI | SSO session timed out | `aws login`; nothing on the server side is affected |
| Backup script exits 0 but listing the bucket is denied | Instance role is write-only by design | Verify from operator credentials or the console |
| Every deploy logs everyone out | The secret key changed | Never regenerate it during deploy; it lives only in the server env file |
| Deploy step shows only "exit code 254" | SSM step did not print command output | Poll `get-command-invocation` and print `StandardOutputContent` and `StandardErrorContent` |
