# Agentic Skills by Ani

A collection of reusable AI agent skills (slash commands) for [Claude Code](https://claude.ai/code) and compatible agents.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Quick Start

### Via AgentHub (recommended for Claude Code)

Install the [AgentHub](https://agenthub.nullorder.org) marketplace plugin, then browse and install skills directly:

```sh
/plugin marketplace add nullorder/agenthub
```

### Manual Install

**Install a single skill** — copy the skill folder into your project or global config:

```sh
# Project-level (available in this project only)
cp -r skills/<category>/<skill-name> .claude/skills/<skill-name>

# Global (available in all projects)
cp -r skills/<category>/<skill-name> ~/.claude/skills/<skill-name>
```

Then invoke it in Claude Code with `/<skill-name>`.

**Use the whole collection** — clone and symlink:

```sh
git clone https://github.com/anistark/ani-skills.git
ln -s $(pwd)/ani-skills/skills/<category>/<skill-name> ~/.claude/skills/<skill-name>
```

## Skills

| Skill | Category | Description |
|-------|----------|-------------|
| [commit-msg](skills/development/commit-msg/) | development | Write well-structured git commit messages |

## Structure

```sh
skills/
  <category>/
    <skill-name>/
      SKILL.md          # Skill definition (required)
      templates/        # Supporting templates (optional)
      examples/         # Usage examples (optional)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding new skills.

## License

[MIT](LICENSE)
