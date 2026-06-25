---
name: report-issue
description: >
  File a GitHub issue well, for bug reports and user-requested features. Prompts
  to report a bug, limitation, or improvement when one surfaces (draft / create /
  skip). On request, writes a clean issue or a multi-phase epic with natively
  linked sub-issues. Grounds claims in code permalinks and sources, checks for
  duplicates, applies existing repo labels, and follows house style: concise
  plain-text titles, no hard-wrapped prose, no em or en dashes.
allowed-tools: Bash AskUserQuestion Read Grep Glob WebSearch WebFetch
---

# Issue Reporter

Files GitHub issues in two modes:

- **Reactive:** when you hit a bug, limitation, missing feature, or broken behavior while working (reading code, running commands, investigating), offer to file it before moving on. Invoke proactively, don't just mention it in passing.
- **On request:** when the user asks to file an issue for a feature, refactor, research finding, or roadmap-sized effort, go straight to grounding and drafting.

Skip it for bugs in the user's own code that they're already fixing, notes with no actionable target, and things they've already filed.

## Steps

### 1. Find the target repo

Run `git remote -v` and `gh repo view --json nameWithOwner,url 2>/dev/null` in parallel. Use `origin` (or `upstream` if this is a fork and the issue belongs upstream). For an external dependency, get the repo from the error, the package manifest (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`), or ask. If you can't tell, ask which `owner/repo` to file against.

### 2. Gather just what's relevant

The exact error or behavior and the command that triggered it, relevant paths and line numbers, the affected version or commit, and any workaround already applied. Don't dump everything.

### 3. Check for duplicates

```bash
gh issue list --repo <owner/repo> --state open --search "<2-3 keywords>" --limit 5
```

If something matches, show the user its title and URL and ask whether it covers their case. If it does, offer to comment on it (`gh issue comment`) instead of opening a new one, and stop.

### 4. Draft

**Title:** `<type>: <description in sentence case, max 72 chars>`, where type is `bug`, `enhancement`, `docs`, or `question`. Plain text, no markdown.

- `bug: panic on nil config when HOME is unset`
- `enhancement: allow custom timeout in connect() options`

For a **bug**, include only the sections that apply:

```markdown
## Description

What's wrong, and what you expected instead.

## Steps to Reproduce

1. Minimal step to trigger it
2. ...

## Environment

- Tool/library version, OS, and anything else relevant (runtime version, etc.)

## Additional Context

Stack traces, links to related issues, workarounds.
```

For an **enhancement**:

```markdown
## Summary

What and why, in a few sentences. Name the current state and the change.

## Current state

- How it works today, with permalinks to the code.

## Proposed change

- What to build.

## Acceptance criteria

- Observable outcomes that mean done.

## References

- Specs, prior art, external sources.
```

For a **roadmap-sized effort**, use an epic (a tracking issue whose phases become sub-issues, see below):

```markdown
## Summary

The overall goal and why it's a multi-step effort.

## Current state

- Grounded in code, with permalinks.

## Design decisions

- Key choices and rationale.

## Proposed phasing

- [ ] Phase 0: ...
- [ ] Phase 1: ...

## References

- Sources.
```

**Ground every claim.** Cite real code as `file_path:line` and link a permalink pinned to the current SHA (`https://github.com/<owner>/<repo>/blob/<sha>/<path>#L<n>`, SHA from `git rev-parse --short HEAD`). Link, don't paste long snippets. For anything external (spec status, release dates, version support), do the web research and add a References section. Don't assert version facts from memory.

### 5. Prompt the user

```
I found something worth filing as a GitHub issue against <owner/repo>.

What would you like to do?
  1. show me a draft
  2. go ahead
  3. skip
```

Accept numbers, the option text, or obvious synonyms ("draft", "create", "no").

### 6. Act

- **Draft:** show it as a code block (`Title:` then `Body:`), then ask whether to create, edit, or skip. Apply edits and re-show before creating.
- **Go ahead:** `gh issue create --repo <owner/repo> --title "<title>" --body "<body>"`. Add `--label` if the label exists (`gh label list --repo <owner/repo> --limit 50`), skip the flag silently if not. Show the returned URL. On failure, show the error and offer the draft for manual filing.
- **Skip:** acknowledge briefly and move on. Don't bring it up again unless the user asks.

## Epics and sub-issues

When an effort spans phases, make the main issue an epic and split each phase into its own sub-issue, then link them natively so a progress tree renders on the parent:

```bash
PARENT=$(gh issue view <epic#> --repo <owner/repo> --json id -q .id)
CHILD=$(gh issue view <child#> --repo <owner/repo> --json id -q .id)
gh api graphql -H "GraphQL-Features: sub_issues" \
  -f query='mutation($p:ID!,$c:ID!){addSubIssue(input:{issueId:$p,subIssueId:$c}){subIssue{number}}}' \
  -f p="$PARENT" -f c="$CHILD"
```

If the native API isn't available, fall back to a task list in the epic body (`- [ ] #123 ...`), which GitHub renders with live status.

- Confirm which phases to create now and the linking method before creating a batch.
- Write detailed sub-issues only for phases understood now; later ones get brief stubs ("scope TBD, refined after #<n>") so they don't go stale.
- Each child opens with `Tracked by #<epic>` and ends with a `Depends on` line naming its prerequisite.

## House rules

- **Be minimal.** Every sentence should add something the title can't. No padding.
- **Reference everything.** Link code (permalinks), docs, related issues, and external sources instead of inlining long snippets or asserting from memory.
- **Be reproducible and specific.** Bugs need steps and exact versions, vague reports get closed.
- **No em-dashes or en-dashes.** Use a comma, colon, parentheses, or a new sentence, and "to" or a hyphen for ranges. Replace any that slip in. Hyphens in compound words (`auto-detect`) are fine.
- **Never hard-wrap the body.** One line per paragraph and list item so it reflows to the reader.
- **Plain-text titles**, sentence case, no "Phase X" prefix (ordering lives in the epic checklist and the tree). Cross-reference children with `Tracked by #<n>`.
- **File against the right repo** (upstream, not the fork), one issue per problem, redact private details (paths, hostnames, tokens), and never auto-file without explicit confirmation.
