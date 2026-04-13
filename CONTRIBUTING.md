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

Once a skill is reviewed and merged to `main`:

1. Push to `main` (done by the merge).
2. Optionally bump `version` in `.claude-plugin/plugin.json` if you want a
   clean changelog entry. It's cosmetic — agenthub re-fetches live from this
   repo's default branch, so content propagates regardless of the version
   string. Bumping without also updating agenthub's `marketplace.json` will
   cause the registry-displayed version to drift.
3. No agenthub PR is needed unless you're changing marketplace metadata
   (name, description, category, tags).

End users pick up the new skill with:

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
  has the required frontmatter

## Optional Frontmatter Fields

| Field | Example | Purpose |
|-------|---------|---------|
| `argument-hint` | `[file-path]` | Shows in autocomplete |
| `allowed-tools` | `Bash Read Grep` | Tools the agent can use without asking |
| `disable-model-invocation` | `true` | Manual-only invocation |

## Code of Conduct

Be respectful, be helpful, keep skills focused and useful.
