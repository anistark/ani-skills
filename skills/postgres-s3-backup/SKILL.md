---
name: postgres-s3-backup
description: >
  Set up, verify, and restore nightly Postgres backups to S3 from a Linux server, using pg_dump, cron, and a write-only IAM policy so a compromised box cannot delete its own history. Use this whenever someone asks to back up a database, protect data on a server, schedule dumps, restore from a backup, test that backups actually work, or asks "what happens if the box dies", even if they do not say S3 or pg_dump. Also use it for the pre-migration dump that a deploy pipeline should take. Works for Postgres on the host or in a container, on EC2 or anywhere with AWS credentials.
---

# Postgres backups to S3

A backup that has never been restored is a hope, not a backup. This skill sets up the nightly dump, proves the upload, and leaves a tested restore procedure behind. Keep the whole thing small enough to read in one screen: `pg_dump | gzip | aws s3 cp`, a cron line, and an IAM policy.

## Find out first

- Where Postgres runs (host package, container, RDS) and how to reach it. `pg_dump` must be on the machine running the script and match the server's major version or newer.
- How the app stores its connection string. The script reads `DATABASE_URL` from the app's env file; SQLAlchemy URLs carry a driver suffix (`postgresql+psycopg://`) that `pg_dump` rejects, so the script strips it.
- What credentials the machine has: an instance role on EC2, or an access key in `~/.aws` elsewhere. Prefer roles.
- Existing bucket, retention needs, and whether anyone has ever restored.

## Before you start: access

This skill uses two AWS identities on purpose, and each step needs the right one.

| Who | Used for | Check | Expect |
|---|---|---|---|
| The server | Nightly upload | `aws sts get-caller-identity` on the box | The instance role, for example `assumed-role/<app>-instance/...` |
| The operator | Creating the bucket, listing, restoring | `aws sts get-caller-identity` locally | The account that owns the bucket, with S3 admin rights |
| The database | Dumping and restoring | `psql "postgresql://<user>@<host>/<db>" -tAc 'show server_version'` with the password from `PGPASSWORD` or `~/.pgpass` and `pg_dump --version` | A connection, and a `pg_dump` major version at or above the server's |

If the operator's session is expired or missing, the user runs `aws login`, `aws sso login`, or `aws configure`; never log in for them. If `get-caller-identity` on the box shows a user access key instead of a role, raise it: long-lived keys on a server are what the write-only role design avoids.

## Set up

1. **Bucket.** Names are global; use `<app>-backups` or fall back to `<app>-backups-<account-id>`. Block public access. Lifecycle rule expiring objects after 30 days, longer if the user has a compliance reason. Versioning is optional.
2. **Permissions.** The writing identity gets `s3:PutObject` on `arn:aws:s3:::<bucket>/*` and nothing else. Listing and reading are deliberately denied from the server, so verification happens from an operator's credentials. Tell the user this before they go looking for the object from the box and hit `AccessDenied`.
3. **Script.** Copy `assets/backup.sh` next to the app's env file, adjust `ENV_FILE` and the object prefix, `chmod +x`. It reads `DATABASE_URL` and `BACKUP_BUCKET` from that env file, so the bucket name lives in one place.
4. **Cron.** `/etc/cron.d/<app>-backup` with `0 3 * * * root /opt/<app>/backup.sh`. The system clock is usually UTC; say what local time that is. Cron's `PATH` is minimal, so the script must find `aws` and `pg_dump` in `/usr/bin`.
5. **Prove it.** Run the script by hand once, exit code 0 with strict mode means the upload happened. Then list the bucket from operator credentials and confirm the object and its size. A 20 byte object is an empty database, which is a finding.

## Restore

Use `scripts/restore-backup.sh`. It downloads a chosen dump (or the latest) and restores it into a database the operator names. Restore into a fresh database first, inspect, and only then swap it in; never pipe a dump over the live database while the app is running.

```sh
read -rs PGPASSWORD && export PGPASSWORD    # or an entry in ~/.pgpass
restore-backup.sh <bucket> <prefix> latest postgresql://<user>@localhost:5432/<app>_restore
```

Keep the password out of the URL: command-line arguments are visible in `ps` to every user on the machine and land in shell history. `backup.sh` and the deploy script already move the password from the env file's URL into `PGPASSWORD` before calling `pg_dump`; the restore script does the same but warns, because by then its own arguments have exposed it.

Do a restore drill right after setup while the data is small and the stakes are zero. Record the command and the time it took in the deploy README.

## Pre-deploy dumps

A deploy that runs migrations should also dump the database first, to local disk, kept for two weeks. It costs seconds and turns a destructive migration into a five minute rollback. The `fastapi-ec2-deploy` skill's deploy script does this; if the user has a different pipeline, add the same three lines before their migration step.

## Pitfalls

- `pg_dump: connection ... FATAL: role does not exist`: the script runs as root and peer auth picked the OS user; use the URL with a password, not a bare `pg_dump <db>`.
- Empty dumps after a Postgres upgrade: `pg_dump` older than the server.
- The bucket lifecycle rule expires objects, it does not stop new uploads, so a broken cron goes unnoticed. Suggest a monthly glance at the bucket or an S3 event notification if the user wants alerting.

## Keeping this skill current

Cloud CLIs, GitHub Actions and package names move faster than this file. Treat any mismatch between what this skill says and what a tool does as a signal, not noise: an unknown flag or subcommand, a deprecation warning in a command or workflow log, an action warning about its Node runtime, a console page or setting that is not where the skill says, a package that no longer exists, or a login hint naming a different command.

When that happens:

1. Stop guessing. Fetch the current official documentation for that tool (sources below) or the action's latest release, not a blog post or memory.
2. Finish the task with the documented current form and tell the user in one line what changed.
3. At the end, propose an improvement to this skill: the file, the old text, the new text, the source URL, and the date checked. Do not edit the skill's files without the user's go-ahead. A plugin install is overwritten on update, so for those suggest a pull request or issue on https://github.com/anistark/ani-skills instead of a local edit.

Sources for this skill:

- pg_dump and psql: https://www.postgresql.org/docs/current/app-pgdump.html and https://www.postgresql.org/docs/current/app-psql.html
- `aws s3 cp` and `aws s3api`: https://docs.aws.amazon.com/cli/latest/reference/s3/
- S3 lifecycle rules and Block Public Access: https://docs.aws.amazon.com/AmazonS3/latest/userguide/
- IAM policy for the write-only role: https://docs.aws.amazon.com/IAM/latest/UserGuide/

Postgres major upgrades are the most common drift here: when the server version changes, re-check that the `pg_dump` on the box matches before trusting the next nightly dump.
