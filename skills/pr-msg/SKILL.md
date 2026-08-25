---
name: pr-msg
description: >
  Write a clear, human-sounding pull request title and description from the
  commits and diff between the current branch and the repo's base branch.
  Terse by default: bolded headings and bullets over prose paragraphs.
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

If there's a template, use it as the scaffold and fill every section honestly (write `N/A` rather than padding, don't delete sections). Otherwise, brief wins. A reviewer skims the description and then reads the diff, so the body is a map, not the territory. Default to bolded headings with bullets under them, not prose paragraphs:

```markdown
**What this adds or changes**, one line, user impact first if it's user-facing
- A concrete change, with `paths`, flags and identifiers in backticks
- Another one

**The next thing**
- ...

Testing: what you actually ran, in one line.

Fixes #123
```

Keep it tight:

- One fact per bullet. If a bullet wants a second sentence, that sentence belongs in the commit message.
- Group by concern, not commit by commit, and don't re-tell the commits. Link them, or let the reviewer open them.
- Skip the `## Summary` / `## Changes` / `## Testing` heading scaffold unless a template asks for it or the PR is genuinely large. On a normal PR it's more structure than content.
- No version numbers or internal milestone names (`v1.4.0`, "the Q3 slice"). They date the description and mean nothing to a reviewer from outside the project.
- Don't restate the diff. Add only what it can't show: why, the trade-off, what you ruled out.
- Add a "Breaking changes" section when something breaks, with the before/after and the migration path. That one is worth the space.
- One line per bullet, no hard wrapping.

Prose paragraphs are the exception, not the default. Use one only when a decision genuinely needs the argument spelled out, and keep it to a few lines.

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
- **Shorter is better.** When you're deciding whether a sentence earns its place, it doesn't. The commits and the diff carry the detail.
- **Never add `Co-authored-by` for AI.** The human authors the PR. If `CONTRIBUTING` requires disclosing AI assistance, add a short line saying so.
- **The repo's conventions win on form, not on length.** Check recent merged PRs (`gh pr list --state merged --limit 10 --json title,body`, add `--repo` on a fork) for title style and any required sections. Don't inherit their length: a repo with a history of long prose descriptions is a habit to break, not a convention to match.

## Example

Title:

```
feat(api): add token-bucket rate limiting to public endpoints
```

Body:

```markdown
**Per-IP rate limiting on `/api/v1/public/`**, 100 req/min, token-bucket. Authenticated endpoints are unchanged.
- New `ratelimit` middleware in `internal/middleware/ratelimit.go`, Redis-backed so it holds across replicas
- Wired into the public router in `cmd/api/router.go`
- Configurable via `RATE_LIMIT_RPM`; returns `429` with a `Retry-After` header when exhausted

Testing: 9 unit tests for burst, steady-state and clock skew. `hey -n 1000 -c 50 https://staging/api/v1/public/ping` starts 429ing at the expected threshold, p99 held at 42ms against a 38ms baseline.

Fixes #741
Refs #712
```
