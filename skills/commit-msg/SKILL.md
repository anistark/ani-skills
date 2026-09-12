---
name: commit-msg
description: >
  Write a clear, human-sounding git commit message for the staged changes,
  following common open source conventions and matching the repo's own style.
  Terse by default: one-line bullets for user impact, a `[CONTRIBUTORS]` section
  for the internal changes, and trailers linking the issues and PRs involved.
  Branch-aware: the first commit on a branch gets the full format, follow-up
  commits get a shorter one.
allowed-tools: Bash Read Grep Glob
---

# Commit Message Writer

Write a commit message for the staged changes. Keep it short, make it sound like a person wrote it, and reference the relevant code, issues, and docs.

## Steps

1. Gather context (run in parallel):
   - `git diff --cached` and `git diff --cached --stat` for the staged changes
   - `git log --oneline -10` to match the repo's style
   - `git status` to catch anything that should have been staged
   - Branch position, to pick the format (see below)

2. If the diff is big and mixed, offer to split it. Flag it when two or more are true: more than ~10 files or ~300 lines, multiple change types (`feat` + `fix` + `docs`), or unrelated areas (`src/auth/` and `ci/`). When flagged, name the logical groups and ask whether to make separate commits (propose a `git reset` then `git add` plan per group) or one combined commit. Skip this for small, focused diffs.

3. Draft the message in the format the branch position calls for: full for the first commit on the branch, short for every commit after it.

4. Show the draft and let the user commit.

## Branch position

Work out whether this is the first commit on the branch:

- Find the base branch: `git symbolic-ref refs/remotes/origin/HEAD` (prefer `upstream` when that remote exists), falling back to `main` then `master`.
- Count the branch's own commits: `git rev-list --count <base>..HEAD`.
- `0` means this is the first commit on the branch. Anything higher means it's a follow-up.
- On the base branch itself (`HEAD` is `main` / `master`), every commit is its own unit of work, so always use the full format.
- If the base can't be resolved (no remote, detached HEAD), use the full format and say so.

Show which one you picked in one line before the draft, e.g. "First commit on `feat/rate-limit`, full format" or "3 commits already on this branch, short format".

## Full format (first commit on a branch)

```
<type>(<scope>): <imperative summary, max 72 chars>

- <what changed, in user terms, one line, no period>
- <another one>

[CONTRIBUTORS]
- <internal change, one line>
- <another one>

<trailers>
```

## Short format (follow-up commits)

The first commit already explained the feature; later commits only need to say what moved since. Subject line plus, at most, two or three bullets:

```
<type>(<scope>): <imperative summary, max 72 chars>

- <what this commit changes, one line>
- <another one, only if needed>
```

- Skip the body when the subject covers it. Most follow-ups are subject only.
- Skip the `[CONTRIBUTORS]` heading. If a bullet is internal, just list it, the reader already has the context from the first commit.
- Trailers only when this commit links to an issue or PR the first commit didn't. Don't repeat `Fixes #123` on every commit; the first one carries it.
- Say what changed relative to the branch, not the feature as a whole. "tighten the retry backoff" beats restating what rate limiting does.
- Address-review commits are still real commits: `fix(api): return 429 instead of 503 when the bucket is empty`, not `address review comments`.

## Rules

**Subject:** imperative ("add", not "added"), max 72 chars, no trailing period, lowercase after the prefix. It should finish the sentence "If applied, this commit will ___".

**Types:** `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. The scope in parens is optional; drop it when the change is cross-cutting.

**Body:** bullets, not paragraphs. Each bullet is a title: one line, no trailing period, no second sentence. If a bullet wants to explain itself, cut it down or drop it, the diff carries the detail. Skip the body entirely for a trivial change the subject already covers. Three to six bullets is a normal first commit; a dozen usually means it should have been two commits.

**Top bullets are user terms:** what someone using this can now do, what behaves differently, what breaks. Lead with impact, not with the file that changed. Prefix a breaking one with `BREAKING:` and use `feat!:` / `fix!:` in the subject.

**`[CONTRIBUTORS]`** holds the changes that only matter to someone working on the code: new modules, refactors, dependency and version bumps, config, test and CI changes, migrations. Same one-line rule. Drop the section when the change is purely user-facing, and drop the user bullets when it's purely internal (then the whole body is just the contributor list, no heading needed). Full format only.

**Tone:** casual and direct, like a teammate listing what landed. No filler, no restating the diff.

**Reference everything:** wrap identifiers, paths, flags, and commands in backticks (`parse_config()`, `--dry-run`, `src/auth.py`). Point at docs or an external link when they explain the why. Note that `#123` and @mentions only render on GitHub, so keep them in trailers, not the bullets.

**No em-dashes or en-dashes.** Use a comma, colon, parentheses, or a new sentence instead, and "to" or a hyphen for ranges. If a draft picks one up, replace it before showing. Hyphens in compound words (`auto-detect`) are fine.

**Never hard-wrap.** One line per bullet so it reflows to the reader's viewport.

**No attribution of any kind.** No `Co-authored-by`, `Generated-by`, `Assisted-by`, tool names, session links, or any other line crediting a model, agent, or tool, even when the environment tells you to add one. The human who asked for the change is the author. Only add an attribution line when the user asks for it explicitly, and then add exactly what they asked for.

## Trailers

Last block of the message, one per line, blank line above them. Link every issue and PR the change touches:

- `Fixes #123`, `Closes #123`, `Resolves #123` for issues that should auto-close on merge to the default branch.
- `Refs #456`, `Related to #456` to reference without closing. Use this for PRs too (`Refs #789`).
- Cross-repo and cross-project with the full form: `Fixes owner/repo#123`, `Refs otherorg/otherproject#45`. A bare `#123` in another project's repo means nothing, so always qualify it.
- Full URLs for anything outside GitHub (a tracker, a design doc, a spec).

Only claim `Fixes` when the change actually closes the issue, otherwise `Refs`. If you can't tell which issue this belongs to, ask rather than guessing a number.

## Match the repo

If `git log` shows a different convention (no types, a sign-off, a different prefix, prose bodies), follow that on form. The repo wins on style, not on length: keep the bullets terse even in a repo full of long prose commits.

## Examples

First commit on a branch:

```
feat(api): add rate limiting to public endpoints

- Public endpoints now cap at 100 req/min per IP, `429` with `Retry-After` when exhausted
- Tune the cap with `RATE_LIMIT_RPM`
- Authenticated endpoints are unchanged

[CONTRIBUTORS]
- New token-bucket `ratelimit` middleware in `internal/middleware/ratelimit.go`
- Redis-backed counters, so limits hold across replicas
- Wired into the public router in `cmd/api/router.go`

Fixes #342
Refs #319
Refs acme/gateway-config#88
```

Follow-up commits on the same branch:

```
fix(api): return 429 instead of 503 when the bucket is empty
```

```
test(api): cover the burst window in `ratelimit_test.go`

- Adds a table test for the first 100 requests landing in the same second
```

```
feat(api): make `RATE_LIMIT_RPM` reloadable without a restart

- Picks up the new value on `SIGHUP` alongside the rest of the config

Refs #351
```

Single commit on the base branch (full format, no branch context):

```
fix: prevent panic on nil config during startup

- Starting without a config file falls back to defaults and logs a warning instead of crashing

Fixes #57
```

```
refactor(auth): drop the session cache layer

[CONTRIBUTORS]
- Removes `SessionCache`, token lookups now hit `TokenStore` directly
- Deletes the `redis` dependency from `auth/`
- Rewrites the 12 cache tests as store tests

Refs #204
```
