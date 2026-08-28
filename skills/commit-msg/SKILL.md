---
name: commit-msg
description: >
  Write a clear, human-sounding git commit message for the staged changes,
  following common open source conventions and matching the repo's own style.
  Terse by default: one-line bullets for user impact, a `For devs` section for
  the internal changes, and trailers linking the issues and PRs involved.
allowed-tools: Bash Read Grep Glob
---

# Commit Message Writer

Write a commit message for the staged changes. Keep it short, make it sound like a person wrote it, and reference the relevant code, issues, and docs.

## Steps

1. Gather context (run in parallel):
   - `git diff --cached` and `git diff --cached --stat` for the staged changes
   - `git log --oneline -10` to match the repo's style
   - `git status` to catch anything that should have been staged

2. If the diff is big and mixed, offer to split it. Flag it when two or more are true: more than ~10 files or ~300 lines, multiple change types (`feat` + `fix` + `docs`), or unrelated areas (`src/auth/` and `ci/`). When flagged, name the logical groups and ask whether to make separate commits (propose a `git reset` then `git add` plan per group) or one combined commit. Skip this for small, focused diffs.

3. Draft the message:

```
<type>(<scope>): <imperative summary, max 72 chars>

- <what changed, in user terms, one line, no period>
- <another one>

For devs:
- <internal change, one line>
- <another one>

<trailers>
```

4. Show the draft and let the user commit.

## Rules

**Subject:** imperative ("add", not "added"), max 72 chars, no trailing period, lowercase after the prefix. It should finish the sentence "If applied, this commit will ___".

**Types:** `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. The scope in parens is optional; drop it when the change is cross-cutting.

**Body:** bullets, not paragraphs. Each bullet is a title: one line, no trailing period, no second sentence. If a bullet wants to explain itself, cut it down or drop it, the diff carries the detail. Skip the body entirely for a trivial change the subject already covers. Three to six bullets is a normal commit; a dozen usually means it should have been two commits.

**Top bullets are user terms:** what someone using this can now do, what behaves differently, what breaks. Lead with impact, not with the file that changed. Prefix a breaking one with `BREAKING:` and use `feat!:` / `fix!:` in the subject.

**`For devs:`** holds the changes that only matter to someone working on the code: new modules, refactors, dependency and version bumps, config, test and CI changes, migrations. Same one-line rule. Drop the section when the change is purely user-facing, and drop the user bullets when it's purely internal (then the whole body is just the dev list, no heading needed).

**Tone:** casual and direct, like a teammate listing what landed. No filler, no restating the diff.

**Reference everything:** wrap identifiers, paths, flags, and commands in backticks (`parse_config()`, `--dry-run`, `src/auth.py`). Point at docs or an external link when they explain the why. Note that `#123` and @mentions only render on GitHub, so keep them in trailers, not the bullets.

**No em-dashes or en-dashes.** Use a comma, colon, parentheses, or a new sentence instead, and "to" or a hyphen for ranges. If a draft picks one up, replace it before showing. Hyphens in compound words (`auto-detect`) are fine.

**Never hard-wrap.** One line per bullet so it reflows to the reader's viewport.

**Never add `Co-authored-by` for AI.** The human who asked for the change is the author.

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

```
feat(api): add rate limiting to public endpoints

- Public endpoints now cap at 100 req/min per IP, `429` with `Retry-After` when exhausted
- Tune the cap with `RATE_LIMIT_RPM`
- Authenticated endpoints are unchanged

For devs:
- New token-bucket `ratelimit` middleware in `internal/middleware/ratelimit.go`
- Redis-backed counters, so limits hold across replicas
- Wired into the public router in `cmd/api/router.go`

Fixes #342
Refs #319
Refs acme/gateway-config#88
```

```
fix: prevent panic on nil config during startup

- Starting without a config file falls back to defaults and logs a warning instead of crashing

Fixes #57
```

```
refactor(auth): drop the session cache layer

For devs:
- Removes `SessionCache`, token lookups now hit `TokenStore` directly
- Deletes the `redis` dependency from `auth/`
- Rewrites the 12 cache tests as store tests

Refs #204
```
