---
name: commit-msg
description: >
  Write a well-structured git commit message following open source best practices.
allowed-tools: Bash Read Grep Glob
---

# Commit Message Writer

Write a git commit message for the staged changes following open source best practices.

## Steps

1. **Gather context** — run these in parallel:
   - `git diff --cached` to see staged changes
   - `git diff --cached --stat` for a file-level summary
   - `git log --oneline -10` to match the repo's existing style
   - `git status` to check for anything unstaged that might be missing

2. **Analyze the changes** — understand:
   - What was changed (files, functions, logic)
   - Why it was changed (bug fix, new feature, refactor, docs, etc.)
   - What the impact is (behavior change, breaking change, performance)

3. **Draft the message** using this format:

```
<type>(<scope>): <imperative summary, max 72 chars>

<Body: explain what and why, not how. Wrap at 72 columns.
Describe the problem being solved and why this approach was chosen.
Include impact details if relevant.>

<Trailers>
```

4. **Present the draft** to the user for review before committing.

## Format Rules

### Subject Line

- **Max 72 characters** (50 is ideal, 72 is the hard limit)
- **Imperative mood**: "add feature" not "added feature" or "adds feature"
- **Completion test**: the subject should complete "If applied, this commit will ___"
- **No period** at the end
- **Lowercase** after the type/scope prefix (unless the first word is an identifier)
- **Prefix format**: `type(scope):` — scope is optional

### Types

| Type | When to use |
|------|-------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code restructuring, no behavior change |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `build` | Build system or dependency changes |
| `ci` | CI/CD configuration changes |
| `chore` | Maintenance tasks (deps, tooling, configs) |
| `revert` | Reverting a previous commit |

### Scope

- Optional, in parentheses: `feat(auth): add OAuth2 support`
- Use the component, module, or area affected
- Omit if the change is cross-cutting or the scope is obvious

### Body

- **Separated from subject by a blank line**
- **Wrap at 72 columns** (for terminal and `git log` readability)
- **Explain the "what" and "why"**, not the "how" — the diff shows the how
- **Include context**: what problem does this solve? Why this approach?
- Compare previous vs. new behavior when relevant
- Can be omitted for truly trivial changes (typo fixes, single-line configs)

### Code and Identifiers

- **Inline code**: wrap function names, file paths, flags, commands, and identifiers in single backticks — e.g. `` `parse_config()` ``, `` `--dry-run` ``, `` `src/auth.py` ``.
- **Code blocks**: use fenced blocks with a language hint for multi-line snippets:

  ````
  ```py
  result = parse_config(path, strict=True)
  ```
  ````

  Common hints: `py`, `js`, `ts`, `go`, `rs`, `sh`, `bash`, `json`, `yaml`, `toml`, `sql`, `diff`. Use `text` for plain output.
- Backticks render in GitHub, GitLab, and most `git log` viewers; unquoted identifiers are easy to misread.

### Trailers (appended after body, separated by blank line)

Use only when applicable:

- **Issue references**: `Fixes #123` or `Refs #456`
- **Breaking changes**: `BREAKING CHANGE: description and migration path`
- **Sign-off** (if project uses DCO): `Signed-off-by: Name <email@example.com>`

**Never add `Co-authored-by` lines for AI agents.** The commit is authored by the human who requested it.

## Anti-patterns to Avoid

- **Vague subjects**: "fix stuff", "updates", "address review comments", "WIP"
- **Past tense**: "fixed bug" instead of "fix bug"
- **Describing files**: "change main.py" — say what the change *does*
- **Giant commits**: if the diff touches unrelated things, suggest splitting
- **GitHub syntax in message body**: @mentions and `#123` links belong in PR descriptions, not commit messages (they don't render outside GitHub)
- **Restating the diff**: the body should add context the diff cannot convey
- **Agent co-authorship**: never add `Co-authored-by` lines for AI agents or assistants

## User-Facing Changes

If the commit introduces or modifies anything visible to end users — a new CLI command, API endpoint, config option, UI element, or behavior change — the body **must** describe:

1. **What the user can now do** (or what changed in their experience)
2. **How to use it** — include a concrete example (command invocation, API call, config snippet)
3. **Any breaking changes** to existing usage

Example:

```
feat(cli): add `export` command for saving reports

Users can now export analysis reports to JSON or CSV:

    myapp export --format json --output report.json
    myapp export --format csv --output report.csv

By default, exports include all fields. Use --fields to select specific
columns:

    myapp export --format csv --fields name,status,score

Refs #891
```

## Adapting to Repo Style

If `git log` shows the repo already follows a specific convention (e.g., no types, different prefix style, sign-off required), **match the existing style** rather than forcing the format above. The repo's convention wins.

## Example Output

```
feat(api): add rate limiting to public endpoints

Unauthenticated endpoints were vulnerable to abuse — a single client
could exhaust the connection pool with rapid requests. Add a
token-bucket rate limiter (100 req/min per IP) to all routes under
/api/v1/public.

The limiter uses Redis for distributed counting so it works correctly
behind a load balancer. Existing authenticated endpoints are unchanged.

Fixes #342
```

```
fix: prevent panic on nil config during startup

The server crashed with a nil pointer dereference when started without
a config file. Now falls back to default configuration and logs a
warning instead of panicking.
```

```
refactor(auth): extract token validation into shared middleware

Three separate handlers duplicated the same JWT validation logic with
slight inconsistencies. Consolidate into a single middleware to ensure
consistent behavior and simplify future changes to the auth flow.
```
