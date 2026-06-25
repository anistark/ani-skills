---
name: pr-msg
description: >
  Write a clear, human-sounding pull request title and description from the
  commits and diff between the current branch and the repo's base branch.
  Fork-aware: diffs against `upstream` when it exists, otherwise `origin`.
  Respects any `.github/pull_request_template.md` the repo ships with.
allowed-tools: Bash Read Grep Glob
---

# Pull Request Message Writer

Draft a PR title and body for the current branch. Don't open the PR, just show the draft and let the user run `gh pr create` (and edit first if they want).

## Steps

### 1. Gather context

Run in parallel:

- `git rev-parse --abbrev-ref HEAD` for the current branch. Stop if it's the base branch (nothing to PR).
- Pick the base remote: `upstream` if it exists (this is a fork, so the PR targets upstream), else `origin`, else stop and say there's no remote to diff against.
- Resolve the base branch on that remote: try `git symbolic-ref refs/remotes/<remote>/HEAD`, or `git remote show <remote>`, falling back to `main`, `master`, `develop`, or `trunk`. Confirm with the user when it isn't obvious. From here, `<base>` means `<remote>/<branch>`.
- `git fetch <remote> --quiet` (best effort, don't block on failure).
- `git log <base>..HEAD` for the commits and their messages (the best source of "why").
- `git diff <base>...HEAD --stat` and `git diff <base>...HEAD` for the changes (summarize a huge diff mentally, don't dump it into the body).
- `git log --oneline -20 <base>` to match the repo's title style.
- Look for a PR template (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/`, `docs/pull_request_template.md`) and `CONTRIBUTING.md` for required sections, DCO, or release-note rules.

Stop if the branch has zero commits ahead of base.

### 2. Sanity-check

Flag these before drafting, but skip the prompt for clean, focused branches:

- Unrelated changes that should be separate PRs (name the groups, ask before continuing).
- Giant diff (~500+ lines or ~20+ files): offer to keep the body high-level with pointers.
- Merge commits (`git log --merges <base>..HEAD`): note them, the user may want to rebase first.
- Suspicious paths (`.env`, `*.pem`, `credentials.*`, large binaries, vendored churn).

### 3. Title

Match the repo's style from `git log <base>`: conventional commits (`type(scope): summary`), subsystem prefixes (`drivers/net: fix foo`), or free-form. Either way: imperative, 50 to 72 chars, no trailing period, describe the change not the files. For a single-commit branch the commit subject is usually the title already, so don't rewrite it for the sake of it. For breaking changes use `feat!:` or say so plainly.

### 4. Body

If there's a template, use it as the scaffold and fill every section honestly (write `N/A` rather than padding, don't delete sections). Otherwise keep it short:

```markdown
## Summary

What this does and why, in a sentence or two. Lead with user impact if it's user-facing.

## Changes

- The concrete changes, grouped by concern, not commit-by-commit
- Reference files and modules with backticks, and link the code where it helps

## Testing

How you actually verified it: commands run, tests added, screenshots for UI. "Tests pass" on its own is noise.

## Related

Fixes #123
```

Skip any section that doesn't apply. Add a "Breaking changes" section only when something breaks, with the before/after and the migration path.

Write one line per paragraph and per bullet, no hard wrapping. Keep it casual and direct, like you're walking a reviewer through it. Don't restate the diff, add the context it can't show (why, trade-offs, what you ruled out).

**Reference everything:** link the issue or design doc that triggered the work, link code (GitHub permalinks or backticked paths), and link external docs or specs you relied on. Use GitHub's closing keywords (`Closes`, `Fixes`, `Resolves`) for issues that should auto-close on merge (default branch only), and `Refs` or `Related to` to reference without closing. Cross-repo: `Fixes owner/repo#123`.

### 5. Release notes

If the repo uses them (a Kubernetes release-note block, Keep a Changelog, `.changeset/`), fill in or suggest the entry, but don't edit the changelog yourself without a go-ahead. If there's no convention, don't invent one.

### 6. Present the draft

Show the title on one line, the body in a fenced block they can copy verbatim, and any heads-up you didn't stop for. Add a command they can run:

```sh
gh pr create --base <base-branch> --title "<title>" --body-file -
```

For a fork, target upstream explicitly (derive `<upstream-owner>/<repo>` from `git remote get-url upstream`):

```sh
gh pr create --repo <upstream-owner>/<repo> --base <base-branch> --head <user>:<branch> --title "<title>" --body-file -
```

Don't run `gh pr create` yourself unless asked. If the branch was rebased after it was pushed, mention they'll need `git push --force-with-lease` (don't run it for them).

## House rules

- **No em-dashes or en-dashes.** Use a comma, colon, parentheses, or a new sentence, and "to" or a hyphen for ranges. Replace any the draft picks up. Hyphens in compound words (`auto-detect`) are fine.
- **Never hard-wrap the body.** One line per paragraph and bullet so it reflows to the reader's viewport.
- **Never add `Co-authored-by` for AI.** The human authors the PR. If `CONTRIBUTING` requires disclosing AI assistance, add a short line saying so.
- **The repo's conventions win.** Check recent merged PRs (`gh pr list --state merged --limit 10 --json title,body`, add `--repo` on a fork) to match body structure and length.

## Example

Title:

```
feat(api): add token-bucket rate limiting to public endpoints
```

Body:

```markdown
## Summary

Adds per-IP rate limiting (100 req/min, token-bucket) to everything under `/api/v1/public/`. Authenticated endpoints are unchanged.

## Changes

- New `ratelimit` middleware in `internal/middleware/ratelimit.go`, backed by Redis so it's shared across replicas
- Wired into the public router in `cmd/api/router.go`
- Configurable via `RATE_LIMIT_RPM`, returns `429` with a `Retry-After` header when exhausted

## Testing

- Added 9 unit tests for burst, steady-state, and clock-skew behavior
- `hey -n 1000 -c 50 https://staging/api/v1/public/ping`: 429s start at the expected threshold, p99 held at 42ms (baseline 38ms)

## Related

Fixes #741
Refs #712
```
