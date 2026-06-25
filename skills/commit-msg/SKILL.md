---
name: commit-msg
description: >
  Write a clear, human-sounding git commit message for the staged changes,
  following common open source conventions and matching the repo's own style.
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

<Why the change exists and what it does, not how. One line per paragraph,
no hard wrapping. Reference the issue, code, and docs.>

<trailers>
```

4. Show the draft and let the user commit.

## Rules

**Subject:** imperative ("add", not "added"), max 72 chars, no trailing period, lowercase after the prefix. It should finish the sentence "If applied, this commit will ___".

**Types:** `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. The scope in parens is optional; drop it when the change is cross-cutting.

**Body:** optional for trivial changes. Explain why, not how (the diff shows how). Write one line per paragraph and let it reflow, don't hard-wrap. Compare old vs new behavior when it helps.

**Tone:** casual and direct, like a teammate explaining the change. No filler, no restating the diff.

**Reference everything:** wrap identifiers, paths, flags, and commands in backticks (`parse_config()`, `--dry-run`, `src/auth.py`). Link the issue with `Fixes #123` or `Refs #456` in the trailers. Point at docs or an external link when they explain the why. Note that `#123` and @mentions only render on GitHub, so keep them in trailers, not the prose.

**No em-dashes or en-dashes.** Use a comma, colon, parentheses, or a new sentence instead, and "to" or a hyphen for ranges. If a draft picks one up, replace it before showing. Hyphens in compound words (`auto-detect`) are fine.

**Never add `Co-authored-by` for AI.** The human who asked for the change is the author.

## User-facing changes

If the change adds or alters something users see (a CLI command, API, config option, behavior), say what they can now do, show a quick example, and call out anything that breaks.

## Match the repo

If `git log` shows a different convention (no types, a sign-off, a different prefix), follow that instead. The repo wins.

## Examples

```
feat(api): add rate limiting to public endpoints

Unauthenticated routes could exhaust the connection pool under bursty traffic, so add a token-bucket limiter (100 req/min per IP) to everything under `/api/v1/public`. Counting goes through Redis so it still holds up behind a load balancer. Authenticated endpoints are untouched.

Fixes #342
```

```
fix: prevent panic on nil config during startup

Starting without a config file crashed with a nil pointer deref. Now it falls back to defaults and logs a warning instead.
```
