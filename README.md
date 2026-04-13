# Agentic Skills by Ani

A collection of reusable AI agent skills (slash commands) for [Claude Code](https://claude.ai/code) and compatible agents.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[![AgentHub](https://agenthub.nullorder.org/badge.svg)](https://agenthub.nullorder.org)

## Quick Start

Two install paths — pick whichever fits. They trade off discoverability against
how the skill is invoked.

| Path | How to install | How to invoke | When to use |
|------|----------------|---------------|-------------|
| **AgentHub** (plugin) | `/plugin marketplace add nullorder/agenthub` → `/plugin install ani-skills@agenthub` | `/ani-skills:<skill-name>` | One-click install, versioned updates. Skill names are namespaced under the plugin. |
| **Manual** (standalone) | `git clone` + `just install-all` (or `cp`/`ln -s` — see below) | `/<skill-name>` | Short, unnamespaced names. Updates are pull-and-relink. |

### AgentHub

Install the [AgentHub](https://agenthub.nullorder.org) marketplace, then install
this plugin:

```sh
/plugin marketplace add nullorder/agenthub
/plugin install ani-skills@agenthub
/reload-plugins
```

Skills are invoked with the plugin namespace prefix — e.g. `/ani-skills:commit-msg`.
Claude Code always namespaces plugin skills to prevent conflicts between plugins;
the prefix is the plugin's `name` field and cannot be removed while using the
plugin system.

**Pulling in new skills later.** New skills added to this repo are not pushed
to your machine automatically — the plugin is cached at install time. To
refresh:

```sh
/plugin marketplace update agenthub   # re-fetch the catalog + plugin source
/plugin update ani-skills@agenthub    # apply any changes to this plugin
/reload-plugins                        # re-scan and register new skills
```

Agenthub points at this repo's default branch, so pushing here is sufficient
— no version bump or marketplace PR is needed when adding a new skill.
Bumping `version` in `.claude-plugin/plugin.json` is still good practice for
release hygiene and changelogs.

### Manual

Install everything with the justfile:

```sh
git clone https://github.com/anistark/ani-skills.git
cd ani-skills
just install-all          # symlinks every skill into ~/.claude/skills/
# or: just install commit-msg   # one skill at a time
```

Or without `just` — copy or symlink a single skill into your project or global
config:

```sh
# Global (available in all projects)
cp -r skills/<skill-name> ~/.claude/skills/<skill-name>
# or: ln -s $(pwd)/skills/<skill-name> ~/.claude/skills/<skill-name>

# Project-level (available in this project only)
cp -r skills/<skill-name> .claude/skills/<skill-name>
```

Then invoke with the plain name: `/<skill-name>` (e.g. `/commit-msg`).

## Skills

| Skill | Category | Description |
|-------|----------|-------------|
| [commit-msg](skills/commit-msg/) | development | Write well-structured git commit messages |
| [sync-upstream](skills/sync-upstream/) | productivity | Sync current branch with upstream/origin, resolving conflicts interactively |

## Structure

```sh
skills/
  <skill-name>/
    SKILL.md          # Skill definition (required)
    templates/        # Supporting templates (optional)
    examples/         # Usage examples (optional)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding new skills.

## License

[MIT](LICENSE)
