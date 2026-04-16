---
name: pr-msg
description: >
  Write a well-structured pull request title and description by inspecting all
  commits and the diff between the current branch and the repo's base branch.
  For forks, compares against `upstream` (when present) instead of `origin`.
  Follows open source conventions drawn from the Git project, Linux kernel,
  Kubernetes/CNCF, and GitHub's linking syntax. Respects any
  `.github/pull_request_template.md` the repo ships with.
allowed-tools: Bash Read Grep Glob
---

# Pull Request Message Writer

Draft a PR title and description for the current branch. The skill inspects
every commit on this branch that is not on the base branch, reads the diff,
matches the repo's existing style, and produces a title and body that a
maintainer can review without re-reading the code.

Do **not** open the PR. Present the draft. The user decides whether to run
`gh pr create` (or equivalent) and may edit first.

## Steps

### 1. Gather context

Run in parallel:

- `git rev-parse --abbrev-ref HEAD` — current branch. Abort if `HEAD` or the
  current branch is the base branch itself (nothing to PR).
- **Resolve the base remote** (fork-aware — mirrors `sync-upstream`):
  - `git remote` to list remotes.
  - If `upstream` exists → source remote is `upstream` (this is a fork; the
    PR will almost certainly target `upstream`, not `origin`).
  - Else if `origin` exists → source remote is `origin`.
  - Else → stop and tell the user there's no remote to diff against.
  - Additional fork signal: `git config --get remote.origin.url` vs.
    `remote.upstream.url` — if they differ and `upstream` is set, treat this
    as a fork. If only `origin` is set but its URL clearly points at a fork
    (e.g. the user's own GitHub namespace while the repo's `CODEOWNERS` /
    package manifest references a different org), surface that observation
    and ask whether an `upstream` should be added — don't guess.
- **Resolve the base branch** on the chosen remote:
  - Prefer `<remote>/HEAD`: `git symbolic-ref refs/remotes/<remote>/HEAD`
    → strip prefix to get the default branch name.
  - Or query it live: `git remote show <remote> | sed -n 's/^  HEAD branch: //p'`.
  - Fallback probe order: `main`, `master`, `develop`, `trunk` — pick the
    first that exists as `<remote>/<name>`.
  - If the current branch has an obvious pair (e.g. `release-1.30`), confirm
    with the user before defaulting.
  - Confirm the resolved `<remote>/<base>` with the user before proceeding
    if the match is non-obvious (e.g. a feature branch being diffed against
    `upstream/main` when `upstream` has many release branches).
- `git fetch <remote> --quiet` when a network is available — best effort;
  don't block on failure.
- From here on, **`<base>` means `<remote>/<base-branch>`** (e.g.
  `upstream/main`). All the commands below use this resolved ref.
- `git log --oneline <base>..HEAD` — commits that will land.
- `git log <base>..HEAD` — full commit messages (the richest source of "why").
- `git diff <base>...HEAD --stat` — file-level overview.
- `git diff <base>...HEAD` — full diff (truncate or summarise mentally if
  huge; don't dump into the body).
- `git log --oneline -20 <base>` — the base branch's recent history, to match
  title style (conventional-commits vs. free-form, etc.).
- Check for a PR template:
  - `.github/pull_request_template.md`
  - `.github/PULL_REQUEST_TEMPLATE.md`
  - `.github/PULL_REQUEST_TEMPLATE/` directory
  - `docs/pull_request_template.md`
  - `.gitlab/merge_request_templates/`
- Check for `CONTRIBUTING.md` / `CONTRIBUTING` / `.github/CONTRIBUTING.md` — it
  may specify required sections, sign-off, DCO, or release-note blocks.

If the branch has **zero commits** ahead of the base, stop and tell the user.

### 2. Sanity-check the diff

Before drafting, flag concerns to the user:

- **Unrelated changes** — if commits span clearly independent concerns (e.g.
  auth refactor + unrelated docs edit + CI tweak), suggest splitting into
  multiple PRs. Quote the groups. Ask whether to proceed as one PR or stop so
  the user can split.
- **Giant diff** — over ~500 changed lines or ~20 files touched, warn that
  reviewers may push back, and offer to keep the body high-level with pointers
  rather than an exhaustive enumeration.
- **Merge commits** on the branch — if `git log --merges <base>..HEAD` is
  non-empty, note it. The user may want to rebase first (don't do it for
  them).
- **Secrets or generated files** — flag suspicious paths (`.env`, `*.pem`,
  `credentials.*`, large binaries, `node_modules/`, vendored lockfiles with
  unexplained churn).

Ask before drafting if any of these are serious. Skip the prompt for clean,
focused branches.

### 3. Draft the title

**Order of preference** for format:

1. **Repo uses conventional commits** (detected by `git log --oneline -20
   <base>` showing `type(scope): ...` patterns consistently) → match it:

   ```
   <type>(<scope>): <imperative summary>
   ```

2. **Repo uses subsystem prefixes** (Linux-kernel style, e.g.
   `drivers/net: fix foo`, `doc: clarify bar`) → match that style.

3. **Repo is free-form** → short, imperative, no prefix required.

Rules regardless of style:

- **Imperative mood.** "add rate limiter", not "added" or "adds".
- **50–72 characters.** 50 is ideal, 72 is the hard limit (the Git project's
  convention; Linux kernel allows up to ~75). Longer titles truncate in PR
  lists, notifications, and release-notes generators.
- **No trailing period.**
- **Lowercase after the prefix**, unless the first word is a proper noun or
  identifier.
- **Describe the change, not the files.** "refactor token validation" beats
  "update auth.go".
- **No `WIP` / `[WIP]`** unless the user explicitly asks — prefer GitHub's
  draft-PR state for work-in-progress.
- **Breaking changes** — append `!` before the colon when using conventional
  commits (`feat!: drop Node 14 support`), or state it plainly in the title
  otherwise.

If the branch is a **single commit**, the commit subject is usually the right
PR title verbatim. Don't rewrite for the sake of it.

If the branch has **multiple commits**, synthesise — the PR title describes
the net outcome, not any one commit.

### 4. Draft the body

If a PR template exists, **use it as the scaffold**. Fill each section
honestly; leave a section empty (or write `N/A`) rather than padding. Never
delete template sections — maintainers may gate merges on them.

If no template exists, use this structure (omit sections that don't apply):

```markdown
## Summary

<1–3 sentences: what this PR does and why. Written so a reviewer who has
never seen the code can decide in 10 seconds whether to look further.>

## Motivation

<The problem being solved. Present tense — describe the current behaviour
without this change. Link to the issue, bug report, or design doc that
triggered the work. If alternatives were considered and discarded, mention
them briefly.>

## Changes

- <bulleted list of the concrete changes, grouped logically, not
  commit-by-commit>
- <reference file/module names with backticks — `src/auth/middleware.go`>
- <call out non-obvious decisions>

## Testing

<How the change was verified. Commands run, test files added, manual steps,
screenshots for UI. Be specific — "tested locally" on its own is noise.>

## Breaking changes / migration

<Only if applicable. Describe what breaks, who's affected, and the migration
path. Otherwise omit the section entirely.>

## Related

Fixes #123
Refs #456
```

### 5. Section-by-section guidance

**Summary.** First line is the elevator pitch. Avoid restating the title.
Prefer active voice. If the change is user-visible, lead with the user
impact ("Users can now export reports as CSV") before the implementation.

**Motivation / Why.** This is the single most valuable section. Git's own
submission guide makes the point bluntly: "the goal of your log message is
to convey the *why* behind your change to help future developers." Explain
the problem first, then why this solution is better than the alternatives
considered. If the change is driven by a concrete incident, performance
number, compliance requirement, or user request, say so.

**Changes.** Bullet the *behavioural* changes, not the file list (the diff
shows files). Group by concern. Mention intentional non-changes when they
may surprise a reviewer ("does not touch `src/legacy/` — out of scope").

**Testing.** Quantify where possible. "Added 12 unit tests covering the
rate-limiter's burst behaviour; manually verified with `curl` loops at 200
req/s" is useful. "Tests pass" is not. For UI changes, attach or describe
before/after screenshots. For performance claims, include numbers (Linux
kernel convention).

**Breaking changes.** Be explicit. Name the affected API, config key, or CLI
flag. Give the before/after. State the migration path in terms the caller
can execute.

**Related.** Use GitHub's closing keywords for issues that should auto-close
on merge: `Closes`, `Fixes`, `Resolves` (plus `closed` / `fixed` /
`resolved`). They only auto-close when the PR targets the repository's
default branch. For issues to reference without closing, use `Refs`,
`Related to`, or `See`. Cross-repo syntax: `Fixes owner/repo#123`.

### 6. Release notes / changelog

If the repo uses them, fill them in. Common conventions to watch for:

- **Kubernetes-style** (`Does this PR introduce a user-facing change?` +
  a release-note code block). User-facing changes get a past-tense note
  ("Added support for ..."); everything else is `NONE`.
- **Keep a Changelog** (`CHANGELOG.md` with `Added` / `Changed` /
  `Deprecated` / `Removed` / `Fixed` / `Security` sections). Suggest the
  entry; don't edit the changelog without the user's say-so.
- **Changesets** (`.changeset/` folder, common in JS monorepos). Suggest
  running `pnpm changeset` — don't hand-write the file.

Default: if no release-notes convention is visible, don't invent one.

### 7. Sign-off and attribution

- If the repo uses **DCO** (signs visible in `git log`, or `CONTRIBUTING` says
  so), ensure each commit has `Signed-off-by:`. If missing, tell the user;
  don't rewrite history silently.
- **Never add `Co-authored-by` lines for AI agents.** The PR is authored by
  the human.
- Some projects (Kubernetes, others) require disclosing AI-assisted authorship
  in the PR body. If `CONTRIBUTING` mentions this, include a short line
  noting that the PR was drafted with AI assistance.

### 8. Present the draft

Show the user:

1. The drafted **title** on one line.
2. The drafted **body** in a fenced code block so they can copy it verbatim.
3. A short list of any concerns you flagged in step 2 that you *didn't* stop
   for (e.g. "heads-up: one merge commit on the branch — consider rebasing
   before opening").
4. A one-liner they can run if they want to open it via `gh`:

   ```sh
   gh pr create --base <base-branch> --title "<title>" --body-file -
   ```

   **For forks**, the PR must target the upstream repo explicitly — `gh`
   defaults to the remote the branch is pushed to, which is usually `origin`
   (the fork). Use `--repo <upstream-owner>/<repo>` so the PR opens against
   upstream:

   ```sh
   gh pr create \
     --repo <upstream-owner>/<repo> \
     --base <base-branch> \
     --head <your-github-user>:<branch> \
     --title "<title>" \
     --body-file -
   ```

   Derive `<upstream-owner>/<repo>` from `git remote get-url upstream`. Piping
   via `--body-file -` avoids shell-escaping the body. Do not execute
   `gh pr create` yourself unless the user explicitly asks.

## Anti-patterns to avoid

- **Restating the diff.** The body should add context the diff cannot
  convey — motivation, trade-offs, migration notes.
- **Vague titles.** "updates", "fixes", "address review comments", "wip".
- **Padding the template.** If a section doesn't apply, write `N/A` or
  remove it (when the template permits). Don't fabricate testing evidence.
- **Copy-pasting commit messages verbatim.** The PR narrative is usually
  broader than any single commit — synthesise.
- **Hiding breaking changes.** If behaviour changes for existing users, say
  so in the title *and* the body.
- **Agent co-authorship.** Never credit the AI as a co-author or
  co-developer.
- **Auto-opening the PR.** Confirm with the user; they may want to amend
  commits, rebase, or split first.
- **Silent force-push.** If the branch is already pushed and the user rebased
  during the session, surface that `git push --force-with-lease` is needed —
  don't run it.

## Adapting to repo style

The repo's conventions always win. Before finalising, double-check:

- **Title style** — does `git log <base>` show conventional commits, prefixes,
  or free-form? Match it.
- **Body style** — does recent merged-PR history (inspect with
  `gh pr list --state merged --limit 10 --json title,body` if `gh` is
  available; add `--repo <upstream-owner>/<repo>` on a fork) show a
  particular structure? Match it.
- **Required sections** — honour anything `CONTRIBUTING.md` or the PR
  template marks as required (release notes, DCO, checklists).
- **Length norms** — some projects prefer terse bodies with links out to
  design docs; others want the full rationale inline. Read recent PRs on the
  base branch to calibrate.

## Example output

Title:

```
feat(api): add token-bucket rate limiting to public endpoints
```

Body:

```markdown
## Summary

Adds per-IP rate limiting (100 req/min, token-bucket) to all routes under
`/api/v1/public/`. Authenticated endpoints are unchanged.

## Motivation

Unauthenticated endpoints were exhausting the connection pool under bursty
traffic — we saw a 3× spike in 503s during the incident on 2026-03-14
(internal IR-482). A token-bucket limiter keyed on client IP caps the blast
radius without penalising steady-state traffic.

A simpler fixed-window counter was considered but rejected: it admits 2×
the intended rate at window boundaries, which is exactly the pattern that
caused the incident.

## Changes

- New `ratelimit` middleware in `internal/middleware/ratelimit.go`
- Redis-backed token store (shared across replicas behind the LB)
- Wired into the public router in `cmd/api/router.go`
- Default 100 req/min per IP, configurable via `RATE_LIMIT_RPM` env var
- Returns `429 Too Many Requests` with a `Retry-After` header on exhaust

## Testing

- Added 9 unit tests covering burst, steady-state, and clock-skew behaviour
- Integration test against a real Redis in CI
- Manually verified with `hey -n 1000 -c 50 https://staging/api/v1/public/ping`:
  429s begin at the expected threshold; p99 latency for admitted requests
  held at 42ms (baseline: 38ms)

## Related

Fixes #741
Refs #712
```
