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
6. Submit a PR

## Skill Guidelines

- **One skill per folder** — keep them self-contained
- **Names**: lowercase-with-hyphens
- **Description**: front-load with keywords, max ~250 characters for display
- **Body**: clear, actionable instructions under 500 lines
- **Test locally** before submitting — invoke it via Claude Code to verify it works

## Optional Frontmatter Fields

| Field | Example | Purpose |
|-------|---------|---------|
| `argument-hint` | `[file-path]` | Shows in autocomplete |
| `allowed-tools` | `Bash Read Grep` | Tools the agent can use without asking |
| `disable-model-invocation` | `true` | Manual-only invocation |

## Code of Conduct

Be respectful, be helpful, keep skills focused and useful.
