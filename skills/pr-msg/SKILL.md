---
name: pr-msg
description: >
  Write a clear, human-sounding pull request title and description from the
  commits and diff between the current branch and the repo's base branch.
  Terse by default: bolded headings and bullets over prose paragraphs.
  Fork-aware: diffs against `upstream` when it exists, otherwise `origin`.
  Respects any `.github/pull_request_template.md` the repo ships with.
  Spots visual changes (UI, styling, motion, terminal output) and suggests
  the screenshot, GIF or video that would show them to a reviewer.
allowed-tools: Bash Read Grep Glob
---

# Pull Request Message Writer

Draft a PR title and body for the current branch. Don't open the PR, just show the draft and let the user run `gh pr create` (and edit first if they want).

## Steps

### 1. Gather context

Resolve the base first, in this order, since each step needs the one before:

1. `git rev-parse --abbrev-ref HEAD` for the current branch.
2. Pick the base remote: `upstream` if it exists (this is a fork, so the PR targets upstream), else `origin`, else stop and say there's no remote to diff against.
3. Resolve the base branch on that remote: try `git symbolic-ref refs/remotes/<remote>/HEAD`, or `git remote show <remote>`, falling back to `main`, `master`, `develop`, or `trunk`. Confirm with the user when it isn't obvious. Stop if the current branch is the base branch (nothing to PR). From here, `<base>` means `<remote>/<branch>`.
4. `git fetch <remote> --quiet` (best effort, don't block on failure).

Then run the rest in parallel:

- `git log <base>..HEAD` for the commits and their messages (the best source of "why").
- `git diff <base>...HEAD --stat` and `git diff <base>...HEAD` for the changes (summarize a huge diff mentally, don't dump it into the body).
- `git log --oneline -20 <base>` to match the repo's title style.
- `gh pr list --state merged --limit 10 --json title,body` (add `--repo <upstream-owner>/<repo>` on a fork) for the title style and any sections recent PRs always carry. Best effort: skip it when `gh` isn't installed or the remote isn't on GitHub, and go by `git log` alone.
- Look for a PR template (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/`, `docs/pull_request_template.md`) and `CONTRIBUTING.md` for required sections, DCO, or release-note rules.

Stop if the branch has zero commits ahead of base.

### 2. Sanity-check

Flag these before drafting, but skip the prompt for clean, focused branches:

- Unrelated changes that should be separate PRs (name the groups, ask before continuing).
- Giant diff (~500+ lines or ~20+ files): offer to keep the body high-level with pointers.
- Merge commits (`git log --merges <base>..HEAD`): note them, the user may want to rebase first.
- Suspicious paths (`.env`, `*.pem`, `credentials.*`, large binaries, vendored churn).

### 3. Check for visual changes

A diff can't show how something looks or moves. When the change is one a reviewer has to see to judge, suggest the capture that shows it. It's visual when the hunks change what a person sees:

- **Styling and layout:** CSS, Sass, Tailwind classes, styled-components, theme or design tokens, breakpoints.
- **Rendered markup:** JSX/TSX, Vue, Svelte, HTML or email templates, SwiftUI and UIKit views, storyboards, Compose or Android layout XML, Flutter widgets.
- **Assets:** icons, images, fonts, illustrations.
- **Motion and state:** animations, transitions, hover and focus styles, loading, empty and error states, drag and drop.
- **Terminal output:** CLI formatting, colours, progress bars, TUI screens.
- **Generated visuals:** charts, PDFs, canvas or WebGL output, docs site pages.

Judge by the hunks, not the file extension. A `.tsx` change confined to a hook, types or data fetching isn't visual, and a one-line padding tweak is. A bug fix counts when the bug was something you could see. Skip this step for tests, backend work and refactors that render the same.

Pick the medium by what the reviewer needs to see:

- **Screenshot** for a static look: layout, spacing, colour, copy, a new screen or component. Before and after side by side when existing UI changed, after only when it's new.
- **GIF** for short motion or a single interaction (a hover, a transition, a toast, a loading state). Around 10 seconds or less: it plays inline and loops. One clip of the new behaviour is enough, add a before clip only when the comparison is the point.
- **Video** (`.mp4` or `.mov`) for a multi-step flow, anything with sound, or anything longer than about 15 seconds.
- **Terminal output:** paste it in a fenced block when it's plain text, screenshot it when colour or alignment is the point, and use a GIF for an interactive TUI.

Then make the ask specific:

- Name the screen, the state and the steps, taken from the diff: "the settings page with the sidebar collapsed", not "add screenshots". When the diff has no call site (a shared component), take the screen from the commits, or say "any screen that shows it".
- Add variants only where the diff touches them: light and dark for theme changes, each width whose rendering changed for responsive ones, each platform for cross-platform UI. Ask for the smallest set that covers the change, and leave out any view that renders the same as before.
- If the branch already carries the evidence (updated visual-regression snapshots such as `__image_snapshots__/` or Playwright's `*-snapshots/`), point the reviewer at those instead: GitHub renders image diffs in the Files tab.

This is a suggestion. Never block the draft on it, and never write the body as if the media were already attached.

### 4. Title

Match the repo's style from `git log <base>`: conventional commits (`type(scope): summary`), subsystem prefixes (`drivers/net: fix foo`), or free-form. Either way: imperative, 72 chars at most (aim for around 50, shorter is fine), no trailing period, describe the change not the files. For a single-commit branch the commit subject is usually the title already, so don't rewrite it for the sake of it. For breaking changes use `feat!:` or say so plainly.

### 5. Body

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

**Testing line:** report only what was actually run, taken from the commits, the conversation, or checks you ran yourself. When nothing says, don't guess and don't write "not run" on the author's behalf: leave `Testing: TODO` in the body and flag it in the heads-up, so they fill it in or drop the line.

**Visual changes:** when step 3 found one, add a section after the last group of change bullets and before `Testing:`, with one slot per capture, each an HTML comment saying what goes there. Use the template's own screenshots or demo section when it has one.

```markdown
**Screenshots**

| Before | After |
| --- | --- |
| <!-- settings page at 375px wide, base branch --> | <!-- same view, this branch --> |
```

For a GIF or video, a `**Demo**` heading over a single slot does it: `<!-- GIF, ~5s: drag a card between columns -->`.

**Reference everything:** link the issue or design doc that triggered the work, link code (GitHub permalinks or backticked paths), and link external docs or specs you relied on. Use GitHub's closing keywords (`Closes`, `Fixes`, `Resolves`) for issues that should auto-close on merge (default branch only), and `Refs` or `Related to` to reference without closing. Cross-repo: `Fixes owner/repo#123`.

### 6. Release notes

If the repo uses them (a Kubernetes release-note block, Keep a Changelog, `.changeset/`), fill in or suggest the entry, but don't edit the changelog yourself without a go-ahead. If there's no convention, don't invent one.

### 7. Present the draft

Show the title on one line, the body in a fenced block they can copy verbatim, and any heads-up you didn't stop for. Add a command they can run:

```sh
gh pr create --base <base-branch> --title "<title>" --body-file -
```

For a fork, target upstream explicitly (derive `<upstream-owner>/<repo>` from `git remote get-url upstream`):

```sh
gh pr create --repo <upstream-owner>/<repo> --base <base-branch> --head <user>:<branch> --title "<title>" --body-file -
```

`--body-file -` reads the body from stdin, so say how it gets there in one line under the command: paste the body and press Ctrl-D, or pipe it in from the clipboard (`pbpaste |` on macOS, `wl-paste |` or `xclip -o |` on Linux).

If step 3 found a visual change, say so next to the draft, briefly. Always cover:

- What to capture, in which medium, and where its slot is in the body.
- What to keep out: crop to the changed area, no real user data, tokens or emails in frame.
- How it gets in: `gh` can't upload attachments, so create the PR, then edit the description on github.com and drop each file in at its slot (or add `--web` to the command and do it before submitting).
- The way out: delete the section if they'd rather skip it, so an empty table doesn't ship.

Mention GitHub's size cap only when suggesting a GIF or video, and only the one that applies: 10 MB for a GIF, and for video 10 MB on free plans or 100 MB on paid ones.

Don't run `gh pr create` yourself unless asked. If the branch was rebased after it was pushed, mention they'll need `git push --force-with-lease` (don't run it for them).

## House rules

- **No em-dashes or en-dashes.** Use a comma, colon, parentheses, or a new sentence, and "to" or a hyphen for ranges. Replace any the draft picks up. Hyphens in compound words (`auto-detect`) are fine.
- **Never hard-wrap the body.** One line per paragraph and bullet so it reflows to the reader's viewport.
- **Shorter is better.** When you're deciding whether a sentence earns its place, it doesn't. The commits and the diff carry the detail.
- **Never add `Co-authored-by` for AI.** The human authors the PR. If `CONTRIBUTING` requires disclosing AI assistance, add a short line saying so.
- **The repo's conventions win on form, not on length.** Take title style and any required sections from the recent merged PRs gathered in step 1. Don't inherit their length: a repo with a history of long prose descriptions is a habit to break, not a convention to match.

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

## Example with a visual change

Title:

```
feat(settings): collapse the sidebar to an icon rail on phones
```

Body:

```markdown
**Sidebar collapses to an icon rail below 768px**, so the settings form gets the full width on phones.
- New `collapsed` variant in `components/Sidebar.tsx`, switched at the `md` breakpoint
- Labels move into tooltips on the rail, icons keep their order

**Screenshots**

| Before | After |
| --- | --- |
| <!-- settings page at 375px wide, base branch --> | <!-- same view, this branch --> |

Testing: checked at 375px, 768px and 1280px in Chrome and Safari. Component tests cover both variants.

Closes #88
```

Heads-up shown next to the draft:

```
This changes how the settings page looks on phones, so before/after screenshots at 375px wide would help the reviewer. The body has a table with a slot for each. Crop to the sidebar and form, and keep real account data out of frame. `gh` can't upload files: create the PR, then edit the description on github.com and drop them in. Delete the table if you'd rather skip it.
```
