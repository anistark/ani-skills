---
name: sync-upstream
description: >
  Sync the current branch with the upstream remote (falling back to origin)
  using the standard open-source rebase-and-sync workflow. Detects an
  `upstream` remote and prefers it over `origin`. On merge conflicts, prompts
  the user interactively per file (ours / theirs / manual) and produces a
  clean result.
allowed-tools: Bash Read Edit AskUserQuestion
---

# Sync with Upstream

Bring the current branch up to date with the upstream source-of-truth, using
the conventions fork workflows follow on GitHub/GitLab: if an `upstream`
remote is configured, it wins over `origin`.

## Steps

### 1. Preflight

Refuse to continue if the repo isn't in a safe state. Run in parallel:

- `git status --porcelain` — must be empty (no uncommitted/unstaged changes)
- `git rev-parse --is-inside-work-tree` — confirms we're in a git repo
- `git rev-parse --abbrev-ref HEAD` — capture the current branch (abort if
  detached HEAD)
- `ls .git/MERGE_HEAD .git/REBASE_HEAD .git/rebase-merge .git/rebase-apply 2>/dev/null`
  — must all be absent (no in-progress merge/rebase/cherry-pick)

If any check fails, report the specific problem to the user and stop. Do not
stash or auto-resolve — let the user decide.

### 2. Resolve the sync source

Run `git remote` and check the list:

- If `upstream` exists → source remote is `upstream`
- Else if `origin` exists → source remote is `origin`
- Else → report "no remote to sync from" and stop

Determine the source branch:

- For the target branch name, prefer the current branch's same-named
  counterpart on the source (e.g., `main` → `<source>/main`,
  `feature/x` → `<source>/feature/x`).
- If that branch doesn't exist on the source, fall back to the source's
  default branch. Detect it with:
  `git remote show <source> | sed -n 's/^  HEAD branch: //p'`
- Confirm the resolved `<source>/<source-branch>` with the user before
  proceeding if it's not an obvious match (e.g., local `feature/x` being
  synced against `upstream/main`).

### 3. Fetch

```sh
git fetch <source> --prune
```

Then compare:

- `git rev-list --left-right --count <current>...<source>/<source-branch>`
  — returns `A\tB` where A = local-only commits, B = remote-only commits.

Possible states:

| Local ahead | Remote ahead | State                              | Action                   |
|-------------|--------------|------------------------------------|--------------------------|
| 0           | 0            | Already in sync                    | Report and stop.         |
| 0           | N            | Behind only — fast-forward         | `git merge --ff-only`.   |
| N           | 0            | Ahead only                         | Report. Nothing to sync. |
| N           | M            | Diverged                           | See step 4.              |

### 4. Pick strategy (only when diverged)

Use `AskUserQuestion` to confirm. Default preference is **rebase** — the
open-source convention for keeping feature branches linear. Offer:

- **Rebase** (`git rebase <source>/<source-branch>`) — replay local commits
  on top of upstream. Clean linear history. May require `git push --force-with-lease`
  afterwards if the branch is already pushed.
- **Merge** (`git merge --no-ff <source>/<source-branch>`) — creates a merge
  commit that records the integration. Safer when the branch is shared or
  already pushed.

Record the user's choice. If rebase is chosen and the branch is already
pushed to `origin`, warn the user that a force-push will be needed.

### 5. Execute

Run the chosen command. Capture stdout/stderr.

- **If the command succeeds without conflicts** → skip to step 7.
- **If `CONFLICT` markers appear** → go to step 6.

### 6. Resolve conflicts interactively

Loop until no conflicts remain.

1. Identify conflicted files:
   `git diff --name-only --diff-filter=U`
2. For each file, in turn:
   - Read the file and locate the `<<<<<<<` / `=======` / `>>>>>>>` hunks.
   - Summarise each hunk briefly: what changed on `ours` (local), what
     changed on `theirs` (upstream). Cite the line numbers.
   - Use `AskUserQuestion` with these options:
     - **Keep ours** — apply `git checkout --ours <file>` (or edit to retain
       the local side if only some hunks conflict)
     - **Keep theirs** — apply `git checkout --theirs <file>`
     - **Edit manually** — present the conflicted content and apply the
       user's resolution via `Edit`
     - **Abort** — run `git rebase --abort` or `git merge --abort` and stop
   - Stage the resolved file with `git add <file>`.
3. When no conflicts remain, continue the operation:
   - Rebase: `git rebase --continue`
   - Merge: the merge command completes automatically once `git add` covers
     every conflicted path; finalize with `git commit --no-edit` unless the
     user wants to edit the default merge message.
4. If the next patch during a rebase produces new conflicts, repeat the
   loop.

**Important:** for `ours` / `theirs` semantics, remember that during a
rebase the names are inverted — `ours` is the upstream side being replayed
onto, and `theirs` is the local commit being replayed. Always confirm the
direction with the user before running the `--ours` / `--theirs` shortcut.
When in doubt, edit manually.

### 7. Verify and report

Run:

- `git status` — confirm clean
- `git log --oneline <source>/<source-branch>..HEAD` — show what local
  commits sit on top (if any)
- `git log --oneline -3` — show the tip

Summarise for the user:

- Which source/branch was synced against
- Strategy used (fast-forward, rebase, merge)
- Conflict count and how each was resolved
- Whether a push is needed (and whether it requires `--force-with-lease`)

Do **not** push automatically. Let the user decide when and how.

## Anti-patterns to Avoid

- **Auto-stashing.** Never stash on the user's behalf — if the worktree is
  dirty, stop and tell them.
- **Silent `--theirs`/`--ours`.** These flags behave differently under rebase
  vs. merge. Never apply them without confirming with the user which side is
  which.
- **Force-pushing without confirmation.** If the user's branch is pushed and
  a rebase rewrites it, surface the required `git push --force-with-lease`
  and let them run it.
- **Continuing past an abort.** If the user picks "Abort" at any conflict,
  run the corresponding `--abort` and stop the skill entirely.
- **Guessing the source branch.** If the current branch has no obvious
  counterpart on the source remote, ask — don't default to `main` silently.

## Example Interaction

```
User:      /ani-skills:sync-upstream
Skill:     On branch `feature/export-csv`. Upstream detected
           (github.com/org/project). Will sync against
           `upstream/main`. Continue?
User:      yes
Skill:     Fetched. You have 3 local commits, upstream has 12.
           Branches have diverged. Prefer rebase or merge?
User:      rebase
Skill:     Rebasing... conflict in `src/export.py`.

           ours (upstream, lines 42–48): added `--gzip` flag handler
           theirs (your commit a3f1c2): renamed `output_path` →
           `out_path` in the same block

           Resolution?
User:      keep both — apply upstream's new flag on top of my rename
Skill:     [edits src/export.py to merge both changes, stages, continues]
           Rebase complete. 3 commits replayed on upstream/main.
           Your branch is 3 ahead of `origin/feature/export-csv`.
           Push with: git push --force-with-lease origin feature/export-csv
```