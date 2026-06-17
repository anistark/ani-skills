---
name: report-issue
description: >
  File a GitHub issue well, for both reactive bug reports and user-requested
  features. Proactively prompt to report a bug, limitation, or improvement when
  one surfaces (draft / create / skip). When the user asks to file an issue for
  a feature, refactor, or research finding, author a well-structured issue or a
  multi-phase epic with natively linked sub-issues. Grounds claims in code
  permalinks and web sources, checks for duplicates, applies existing repo
  labels, and follows house style (concise dash-free titles, "Tracked by #N"
  cross-refs, no hard-wrapped prose, no em/en dashes).
allowed-tools: Bash AskUserQuestion Read Grep Glob WebSearch WebFetch
---

# Issue Reporter

This skill files GitHub issues well in two modes. Reactively: whenever a bug,
limitation, missing feature, or clearly broken behavior is encountered (while
reading code, running commands, or investigating a problem), offer to file an
issue before moving on. On request: when the user asks to create an issue for a
feature, refactor, research finding, or roadmap-sized effort, author a
well-structured issue or a multi-phase epic with linked sub-issues.

**In reactive mode, invoke proactively.** If you notice something reportable
during a session (e.g. an error message points to a library bug, a config
option is undocumented, a CI step is broken for unrelated reasons), invoke this
skill rather than just mentioning it in passing.

---

## When to Invoke

Invoke this skill when **any** of the following are true:

- A command fails with an error that looks like a bug in a dependency, tool,
  or upstream project (not the user's own code).
- You discover a missing feature, confusing API, or poor default in a library
  or tool the user is working with.
- A test, lint rule, or CI check fails due to a problem that the user does not
  own and cannot fix locally.
- The user explicitly says "we should file an issue", "this is a bug", or
  "someone should report this".
- You notice an inconsistency in docs, an undocumented breaking change, or
  behavior that contradicts the project's own documentation.
- The user explicitly asks to create or file an issue for a feature,
  enhancement, refactor, research finding, or roadmap-sized effort. This is the
  on-request mode: go straight to grounding and drafting, no proactive prompt
  needed.

Do **not** invoke for:
- Issues in the user's own code that they are actively fixing.
- Informational notes with no actionable upstream target.
- Duplicate reports the user has already filed.

---

## Steps

### 1. Detect the target repository

Run in parallel:

- `git remote -v` — list all remotes.
- `gh repo view --json nameWithOwner,url 2>/dev/null` — confirm the current
  repo if `gh` is authenticated.

Determine the target repo:
- If the issue is in the **current repo**: use the repo detected from `origin`
  (or `upstream` if this is a fork and the issue belongs to the upstream project).
- If the issue is in an **external dependency**: extract the repo from the
  error message, package manifest (`package.json`, `pyproject.toml`,
  `go.mod`, `Cargo.toml`, etc.), or ask the user.
- If no repo can be determined, ask the user: "Which repo should this be filed
  against? (e.g. `owner/repo`)"

### 2. Gather supporting context

Collect only what is relevant to the issue — do not dump everything:

- The exact error message or behavior, with the command that triggered it.
- Relevant file paths, line numbers, or stack traces.
- The version or commit of the affected package/tool (check lock files,
  `--version` flags, or `git log` of the dep).
- Any workaround the user has already applied.
- Related issues or PRs already known (search with
  `gh issue list --repo <owner/repo> --search "<keywords>" --limit 5`).

### 3. Check for duplicates

Before drafting, run:

```bash
gh issue list --repo <owner/repo> --state open --search "<2-3 keywords from the issue>" --limit 5
```

If a likely duplicate is found:
- Show the user the matching issue title and URL.
- Ask: "This looks like it might already be reported as #NNN — does that cover
  your case, or is this distinct?"
- If it's a duplicate, offer to add a comment (`gh issue comment`) instead of
  a new issue and stop here.

### 4. Draft the issue

Draft a title and body using the format below.

**Title format:**

```
<type>: <concise description in sentence case, max 72 chars>
```

Where `<type>` is one of:
- `bug` — wrong or broken behavior
- `enhancement` — missing feature or improvement
- `docs` — documentation gap or inaccuracy
- `question` — genuine ambiguity that warrants a response from maintainers

Examples:
- `bug: panic on nil config when HOME is unset`
- `enhancement: allow custom timeout in connect() options`
- `docs: --dry-run flag not documented in CLI reference`

**Body sections** (include only the relevant ones):

```markdown
## Description

[1-3 sentences: what is wrong, what was expected instead]

## Steps to Reproduce

1. [Minimal step to trigger the issue]
2. ...

## Actual Behavior

[What happens]

## Expected Behavior

[What should happen]

## Environment

- Tool/library version: x.y.z
- OS: macOS / Linux / Windows
- [Any other relevant context: Go version, Node version, etc.]

## Additional Context

[Stack traces, links to related issues, workarounds]
```

Omit sections that do not apply (e.g. no "Steps to Reproduce" for a docs
issue). Keep the body factual and concise: maintainers read many issues.

For an **enhancement or feature**, use this shape instead of the bug template:

```markdown
## Summary

[What and why, in 2-4 sentences. Name the current state and the change.]

## Current state

- [How it works today, with permalinks to the relevant code.]

## Proposed change

- [What to build or alter.]

## Acceptance criteria

- [Observable outcomes that mean "done".]

## References

- [External sources, specs, prior art.]
```

For a **roadmap-sized effort, use an epic**: a tracking issue whose phases
become sub-issues (see "Epics and sub-issues" below).

```markdown
## Summary

[The overall goal and why it is a multi-step effort.]

## Current state

- [Grounded in code, with permalinks.]

## Design decisions

- [Key choices and rationale: defaults, compatibility, user-facing behavior.]

## What needs implementing (high level)

1. [Layer one]
2. [Layer two]

## Affected surfaces

- `path/to/file`: what changes here.

## Proposed phasing

- [ ] Phase 0: ...
- [ ] Phase 1: ...

## References

- [Sources.]
```

### Ground every claim

Before drafting any of these, ground the facts:

- Cite real code as `file_path:line`, and in the body link a GitHub permalink
  pinned to the current commit SHA
  (`https://github.com/<owner>/<repo>/blob/<sha>/<path>#L<n>`; get the SHA from
  `git rev-parse --short HEAD`). Link, do not paste long snippets.
- For anything external (spec status, release dates, version support), do web
  research and add a "References" section with the sources. Do not assert
  version facts from memory.

### 5. Prompt the user

Ask the user using **exactly three options**:

```
I found something worth filing as a GitHub issue against <owner/repo>.

What would you like to do?
  1. show me a draft
  2. go ahead
  3. skip
```

Wait for the user's response. Accept plain numbers (`1`, `2`, `3`),
the option text, or obvious synonyms ("draft", "create", "no").

### 6. Act on the user's choice

**Option 1 — "show me a draft":**

Display the draft as a formatted code block:

```
Title: <title>

Body:
---
<body>
---
```

After showing the draft, ask: "Want me to go ahead and create this, edit
anything, or skip?" Handle the follow-up the same way (go ahead / edit / skip).
If the user requests edits, apply them and show the revised draft before
creating.

**Option 2 — "go ahead":**

Run:

```bash
gh issue create \
  --repo <owner/repo> \
  --title "<title>" \
  --body "<body>"
```

Add `--label "bug"` / `--label "enhancement"` / `--label "documentation"` if
the label exists on the repo (check with
`gh label list --repo <owner/repo> --limit 50` first; skip the flag silently
if the label is not present).

On success, show the user the issue URL returned by `gh issue create`.
On failure, show the error and offer to copy the draft to the clipboard or
display it for manual filing.

**Option 3 — "skip":**

Acknowledge briefly ("Noted — skipping the issue.") and continue the session
without creating anything. Do not bring it up again unless the user asks.

---

## Epics and sub-issues

When an effort spans distinct phases or workstreams, make the main issue an
epic and split each phase into its own sub-issue. Create the children, then
link them natively so a progress tree renders on the parent.

```bash
# Parent (epic) and child node IDs
PARENT=$(gh issue view <epic#> --repo <owner/repo> --json id -q .id)
CHILD=$(gh issue view <child#> --repo <owner/repo> --json id -q .id)

# Native sub-issue link (gh has no first-class flag, so use GraphQL)
gh api graphql -H "GraphQL-Features: sub_issues" \
  -f query='mutation($p:ID!,$c:ID!){addSubIssue(input:{issueId:$p,subIssueId:$c}){subIssue{number}}}' \
  -f p="$PARENT" -f c="$CHILD"
```

If the native API is unavailable, fall back to a task list: rewrite the epic
body's checklist to reference child numbers (`- [ ] #123 ...`), which GitHub
renders with live status.

Guidance:

- Confirm with the user which phases to create now and the linking method
  before creating a batch.
- Only write detailed sub-issues for phases understood now. Later phases that
  depend on earlier design should be brief stubs ("scope TBD, refined after
  #<n>") so they do not go stale.
- Each child opens with `Tracked by #<epic>` and ends with a `Depends on` line
  naming its prerequisite issue by number.
- Keep ordering in the epic checklist and the sub-issue tree, not in titles.

---

## Format Rules

- **Be minimal**: do not pad the body with generic text. Every sentence should
  add information a maintainer could not infer from the title alone.
- **Be reproducible**: always include steps if the issue is a bug. A report
  without steps to reproduce is hard to act on.
- **Be version-specific**: vague reports ("it broke") are routinely closed.
  Include exact versions and OS when relevant.
- **No speculation**: stick to observed behavior. Do not suggest a fix unless
  you are confident and it belongs in the issue.
- **No markdown in the title**: no backticks, asterisks, or links in the title
  line — only plain text.
- **Link don't embed**: if there is relevant existing code, link to it (GitHub
  permalink) rather than inlining long snippets.
- **Concise titles, no phase prefix**: sentence case, plain text. Do not prefix
  sub-issue titles with "Phase X"; ordering lives in the epic checklist and the
  sub-issue tree.
- **Cross-reference children with `Tracked by #<n>`** (not "Parent epic" or
  "Part of").
- **Never hard-wrap the body**: write one line per paragraph and per list item
  so the raw source reflows to the reader's viewport.
- **No em-dashes or en-dashes**: use a colon, comma, parentheses, or a new
  sentence for a separating dash; use "to" or a hyphen for a numeric range
  (e.g. "bytes 4 to 7"). Hyphens in compound words (`auto-detect`,
  `wasm32-wasip1`) are fine.

---

## Anti-patterns to Avoid

- **Filing against the wrong repo**: double-check you are filing against the
  upstream project, not the user's fork.
- **Overly broad issues**: one issue per problem. If multiple unrelated issues
  surfaced, prompt the user once per issue, not all at once.
- **Leaking private details**: if the error message or stack trace contains
  file paths, hostnames, tokens, or other private information, redact before
  filing.
- **Duplicate noise**: always search for duplicates first. Two minutes of
  searching saves maintainers hours of triage.
- **Nagging**: if the user says skip, accept it and move on. Do not re-prompt
  in the same session.
- **Auto-filing without asking**: never create an issue without explicit user
  confirmation (option 2 or follow-up "go ahead").
- **Asserting external facts from memory**: research release dates, spec
  status, and version support, and cite the sources.
- **Detailed stubs for unknown phases**: do not over-specify sub-issues whose
  scope depends on earlier work not yet done.
- **House-style slips**: hard-wrapped issue bodies or em/en dashes both violate
  the format rules above.

---

## Example Interaction

**Scenario:** `npm install` fails with an error from a dependency's postinstall
script; the user is not the author of that dependency.

---

*Claude detects the error and invokes this skill automatically:*

> I found something worth filing as a GitHub issue against `some-org/some-lib`.
>
> What would you like to do?
> 1. show me a draft
> 2. go ahead
> 3. skip

*User types:* `1`

> **Title:** `bug: postinstall script fails on Node 22 with ERR_MODULE_NOT_FOUND`
>
> **Body:**
> ```
> ## Description
>
> The postinstall script in v3.4.1 crashes on Node 22 with
> `ERR_MODULE_NOT_FOUND` when `node_modules/.bin` is not yet on PATH.
> Node 18 and 20 are unaffected.
>
> ## Steps to Reproduce
>
> 1. Use Node 22.x
> 2. Run `npm install some-lib@3.4.1` in a clean directory
> 3. Observe postinstall failure
>
> ## Actual Behavior
>
> ```
> Error [ERR_MODULE_NOT_FOUND]: Cannot find module 'esbuild'
>   at postinstall.mjs:12
> ```
>
> ## Expected Behavior
>
> Install completes without error.
>
> ## Environment
>
> - some-lib version: 3.4.1
> - Node: 22.2.0
> - npm: 10.7.0
> - OS: macOS 14.5
> ```
>
> Want me to go ahead and create this, edit anything, or skip?

*User types:* `go ahead`

> Issue created: https://github.com/some-org/some-lib/issues/789
