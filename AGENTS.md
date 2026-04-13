# AGENTS.md — AI Coding Agent Instructions for ani-skills

> Instructions for Claude Code, Cursor, Copilot, and other AI coding agents working on this project.

---

## Project Overview

**ani-skills** is a collection of reusable AI agent skills (slash commands) for Claude Code and compatible agents.

- **Repository:** https://github.com/anistark/ani-skills
- **License:** MIT
- **Distribution:** Available via [AgentHub](https://agenthub.nullorder.org) marketplace

---

## Repository Structure

```sh
ani-skills/
├── README.md              # Hero doc: install, skills index
├── LICENSE                # MIT
├── CONTRIBUTING.md        # How to contribute skills
├── AGENTS.md              # This file — agent instructions
├── .claude-plugin/
│   └── plugin.json        # Plugin manifest (name, version, author)
├── .gitignore             # plans/, .DS_Store, etc.
│
├── skills/                # All skills live here (flat layout)
│   ├── <skill-name>/      # One folder per skill
│   │   ├── SKILL.md       # Required — frontmatter + instructions
│   │   ├── templates/     # Optional supporting templates
│   │   └── examples/      # Optional usage examples
│   └── ...
│
└── plans/                 # Internal only (gitignored)
```

The flat `skills/<skill-name>/` layout is required by the Claude Code plugin
loader — it does not recurse into category sub-folders. Category is tracked in
the README skills table, not in the directory structure.

---

## Skill Format

Every skill is a directory containing at minimum a `SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name
description: What this skill does and when to use it
---

[Markdown instructions for the agent]
```

Optional frontmatter fields:
- `argument-hint` — e.g. `[file-path]` (shown in autocomplete)
- `allowed-tools` — tools the agent can use without asking
- `disable-model-invocation: true` — manual-only invocation
- `context: fork` — run in isolated subagent

---

## Agent Rules

- **Follow user instructions.** The user's explicit requests always take priority. If the user asks for something that conflicts with these guidelines, follow the user.
- **No over-commenting.** Only add useful comments: `NOTE:` and `TODO:` annotations. Don't add inline comments restating what the code does.
- **Don't commit unless explicitly asked.** Never auto-commit.
- **One skill per commit.** Do not modify multiple skills in a single commit.
- **Test before committing.** Verify skills work locally via Claude Code before marking them done.
- **Update the index.** When adding or removing skills, update the skills table in `README.md`.
- **Check `plans/` for context.** Before starting work, check files under `plans/` for roadmaps and design docs that may provide context or constraints.
- **Update plans when completing tasks.** After finishing any task from `plans/`, mark it as done (`[x]`) in the relevant plan file.

---

## Conventions

### Naming

- Skill names: lowercase-with-hyphens (e.g., `code-review`, `tdd-cycle`)

### Quality

- Every `SKILL.md` must have valid frontmatter with at least `name` and `description`
- Keep skill instructions clear, actionable, and under 500 lines
- Front-load descriptions with keywords — first 250 characters matter most for discoverability
- Supporting files (templates, examples) go alongside `SKILL.md` in the same folder

### Categories

Categories are metadata for the README index table, not directory names. Use
them to help users browse. Current categories:

| Category        | Description                                       |
|-----------------|---------------------------------------------------|
| `development`   | Code review, testing, debugging, refactoring      |
| `devops`        | CI/CD, Docker, deployment, infra                  |
| `documentation` | README generation, API docs, changelogs           |
| `productivity`  | Git workflows, project scaffolding, automation    |
| `security`      | Audits, vulnerability scanning, compliance        |
| `data`          | Data analysis, migrations, ETL                    |

---

## Important Paths

| Path | What it is |
|------|-----------|
| `README.md` | Project docs and skills index |
| `CONTRIBUTING.md` | Contribution guidelines and skill format spec |
| `skills/` | All skills, organized by category |
| `plans/` | Internal planning docs (gitignored) |

---

## Gotchas

- **`plans/` is gitignored.** Internal planning docs — don't commit them.
- **Flat `skills/` only.** Never nest skills under category sub-folders — the Claude Code plugin loader won't find them.
- **Skills are self-contained.** Each skill folder should work independently when copied elsewhere.
- **Plugin-invoked names are namespaced.** When installed via the agenthub marketplace, a skill is invoked as `/ani-skills:<skill-name>`. Only standalone installs (e.g., `just install`) surface as plain `/<skill-name>`.
