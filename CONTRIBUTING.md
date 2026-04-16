# Contributing

Thanks for your interest in contributing skills!

## Adding a New Skill

1. Create a folder directly under `skills/`: `skills/<your-skill-name>/`
   (The layout is flat — no category sub-folders. Claude Code's plugin loader
   does not recurse into nested directories.)
2. Pick a category tag for the README index (see the list in `AGENTS.md`)
3. Add a `SKILL.md` with this format:

```yaml
---
name: your-skill-name
description: >
  A clear description of what this skill does and when to use it.
---

# Your Skill Name

[Instructions for the AI agent go here]
```

4. Optionally add `templates/` or `examples/` folders alongside `SKILL.md`
5. Update the skills index table in `README.md` (with the category tag)
6. Test the skill locally (see below)
7. Submit a PR

## Testing a skill locally

There are two surfaces to test on, because the repo ships through two install
paths — standalone (symlinks into `~/.claude/skills/`) and the agenthub plugin
(namespaced under `/ani-skills:`).

**Standalone** — fastest iteration:

```sh
just install your-skill-name
# start a new Claude Code session (or /reload-plugins)
/your-skill-name
```

**Plugin mode** — verifies the skill loads the way end users on agenthub will
see it:

```sh
claude --plugin-dir $(pwd)
# then in the session:
/reload-plugins
/ani-skills:your-skill-name
```

`--plugin-dir` loads straight from your working checkout, bypassing the
marketplace cache, so edits are picked up with each `/reload-plugins`.

## Releasing

Publishing a new skill to agenthub users is a **two-PR** flow:

1. **This repo** — merge the skill to `main`, then bump `version` in
   `.claude-plugin/plugin.json` (semver: patch for fixes, minor for new
   skills, major for breaking changes).
2. **agenthub** — open a PR against [nullorder/agenthub](https://github.com/nullorder/agenthub)
   editing `plugins/ani-skills.json` so its `version` matches the new
   value. (Do not edit `.claude-plugin/marketplace.json` there — it's
   auto-generated from `plugins/`.)

Both versions must match. If the plugin's `version` in this repo advances
but the agenthub registry entry still points at the old version, end users
running `/plugin update ani-skills@agenthub` get `"already at the latest
version"` and the new skill never reaches them. The update command is
gated on the marketplace-declared version, not on git HEAD.

Once both PRs merge, end users refresh with:

```sh
/plugin marketplace update agenthub
/plugin update ani-skills@agenthub
/reload-plugins
```

See the README for the full user-side update flow.

## Skill Guidelines

- **One skill per folder** — keep them self-contained
- **Names**: lowercase-with-hyphens
- **Description**: front-load with keywords, max ~250 characters for display
- **Body**: clear, actionable instructions under 500 lines
- **Validate before pushing** — `just validate` checks that every `SKILL.md`
  has the required frontmatter. CI runs a stricter check via
  [`sutras`](https://github.com/anistark/sutras) (`sutras validate --all --path skills/`)
  on every PR to `main`; install locally with `pip install sutras` to preview
  the same output

## Optional Frontmatter Fields

| Field | Example | Purpose |
|-------|---------|---------|
| `argument-hint` | `[file-path]` | Shows in autocomplete |
| `allowed-tools` | `Bash Read Grep` | Tools the agent can use without asking |
| `disable-model-invocation` | `true` | Manual-only invocation |

## Code of Conduct

Be respectful, be helpful, keep skills focused and useful.
