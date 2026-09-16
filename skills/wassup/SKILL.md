---
name: wassup
description: >
  Project status check and "what should I work on next" recommender. Reads the
  regular places (README, CONTRIBUTING, CHANGELOG, docs/, plan(s)/, roadmap,
  open GitHub issues and PRs, recent commits) to work out the project's current
  state. Flags anything out of sync between code, docs and plans and names one
  specific thing to fix first. If everything is in sync, suggests three next
  tasks: least effort highest impact, most profitable, and longest pending. If
  nothing is left, researches similar projects and proposes a new feature.
allowed-tools: Bash Read Grep Glob WebSearch WebFetch
---

# Wassup

Answer one question for the user: "where is this project at, and what should I
do next?" Read widely, then report briefly. The output is a short status note,
not a survey.

## Steps

### 1. Gather the current state

Run these in parallel. Skip anything that does not exist without complaint.

**Repo basics**

```bash
git rev-parse --abbrev-ref HEAD
git status --porcelain
git log --oneline -30
git log -1 --format=%cd
git tag --sort=-creatordate | head -5
```

**Docs and planning.** Read whichever of these are present:

- `README.md`, `CONTRIBUTING.md`, `AGENTS.md` / `CLAUDE.md`, `CHANGELOG.md`
- `docs/` (skim the index or top level files, not every page)
- `plan/`, `plans/`, `planning/`, `roadmap.md`, `ROADMAP.md`, `TODO.md`,
  `.github/ROADMAP.md`
- Package manifest for the declared version (`package.json`, `Cargo.toml`,
  `pyproject.toml`, `.claude-plugin/plugin.json`, `go.mod`, etc.)

**GitHub, if `gh` is available and the repo has a remote:**

```bash
gh repo view --json name,description,defaultBranchRef,latestRelease
gh issue list --state open --limit 50 --json number,title,labels,createdAt,updatedAt,comments
gh pr list --state open --limit 30 --json number,title,isDraft,createdAt,updatedAt,reviewDecision
gh release list --limit 5
```

If `gh` fails (not installed, not authenticated, no remote), note it in one
line and continue with local sources only.

**Code shape.** Take a quick inventory of what actually exists: the top level
tree, the list of modules / commands / skills / endpoints, whatever the unit of
the project is. This is what the docs get compared against.

### 2. Check that everything is in sync

Compare what the docs and plans *say* against what the code and repo *are*.
Look for these specific kinds of drift:

| Check | Where to look |
|-------|---------------|
| README index vs. what exists | README tables or lists vs. the directory tree |
| Declared version vs. latest tag / release | manifest vs. `git tag` / `gh release list` |
| CHANGELOG vs. recent commits | unreleased section vs. `git log` since last tag |
| Plan items marked open that are already shipped | `plan(s)/` checkboxes vs. code and commits |
| Plan items marked done that are not in code | same, reversed |
| Open issues that recent commits already fixed | issue titles vs. commit messages |
| Open PRs that are stale, conflicting, or already superseded | `gh pr list` ages and review state |
| Docs describing commands, flags or files that no longer exist | grep the docs for names, check they resolve |
| CONTRIBUTING steps that do not match the actual tooling | justfile / Makefile / CI vs. the described flow |

**If anything is out of sync:** stop here and report it. Keep the list to the
three to five most important items. For each one say what is out of sync, the
two places that disagree, and the concrete edit that fixes it. Then pick
**one** to start with and say why (usually the cheapest one that unblocks the
others, or the one a new contributor would trip over first). Do not go on to
step 3; a project with drifting docs should fix that before picking up new
work.

**If everything is in sync:** say so in one line and continue.

### 3. Suggest three things to pick up

Pull candidates from the plans, open issues, TODO / FIXME comments in code,
and open PRs waiting on the maintainer. Pick exactly three, one per lane:

1. **Least effort, highest impact.** Something finishable in a sitting that
   visibly improves the project: a small feature already scoped in a plan, a
   frequently hit bug, a missing doc that answers a recurring question.
2. **Most profitable.** The task that moves the project's actual goal furthest.
   Read the project's own framing to decide what "profitable" means here:
   users, adoption, revenue, stars, reliability, unblocking a dependent
   project. Say which goal you are optimising for.
3. **Longest pending.** The oldest open issue, plan item or TODO that is still
   relevant. Age alone is not enough; if it is stale, say so and pick the
   next oldest that still matters.

For each one give: a title, where it came from (issue number, plan file and
line, file path), a one line reason it belongs in that lane, and a rough
size (small / medium / large). Do not pad. If one lane has no honest
candidate, say so rather than forcing one.

Ask the user which one to take, or none. Do not start work unprompted.

### 4. If there is nothing to pick up

Only reach this step when plans, issues and TODOs are all empty or exhausted.

Search for the project's neighbours: similar tools, competitors, projects
solving the same problem in the same ecosystem. Use the README's own
description as the query, plus the package name and category. Skim two to
four of them and look for capabilities users clearly value there that this
project lacks.

Propose **one** new feature. Describe what it does, why it fits this
project's scope, which neighbour(s) have it, and the smallest useful first
version. Offer to write it up as a plan file or an issue (using
`/report-issue` if that skill is installed).

## Output

Keep the whole report short enough to read without scrolling. Suggested shape:

```
## Status
<branch>, <n> commits since <last tag>, <n> open issues, <n> open PRs.
Last activity: <date>.

## Sync
In sync.            (or a brief list of what drifted)
                    Start with: <one item and why>

## Next up
1. Least effort, highest impact: ...
2. Most profitable: ...
3. Longest pending: ...

Which one?
```

Or, when step 4 applies, replace "Next up" with a single "Proposal" section.

## Rules

- **Read before you judge.** Do not report drift you have not verified in both
  places. Cite file paths and line numbers or issue numbers.
- **Brief over complete.** Three to five sync items, exactly three suggestions,
  one proposal. The user can ask for more.
- **Do not fix anything.** This skill reports and recommends. Making the edits
  is a separate step the user chooses.
- **No web search unless steps 2 and 3 came up empty.** Local sources come
  first.
- **Respect gitignored plans.** If `plan(s)/` is gitignored, still read it; it
  is the maintainer's own context. Just do not suggest committing it.
- **Plain text.** No em dashes or en dashes in the report.
