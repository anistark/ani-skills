# ani-skills justfile

# List all skills
list:
    @find skills -name "SKILL.md" | sort | while read f; do \
        dir=$(dirname "$f"); \
        name=$(basename "$dir"); \
        category=$(basename "$(dirname "$dir")"); \
        echo "  $category/$name"; \
    done

# Validate all skills have required frontmatter (name + description)
validate:
    @echo "Validating skills..." && \
    fail=0; \
    for f in $(find skills -name "SKILL.md"); do \
        name=$(head -10 "$f" | grep "^name:"); \
        desc=$(head -10 "$f" | grep "^description:"); \
        if [ -z "$name" ] || [ -z "$desc" ]; then \
            echo "  FAIL: $f (missing name or description)"; \
            fail=1; \
        else \
            echo "  OK: $f"; \
        fi; \
    done; \
    [ "$fail" -eq 0 ] && echo "All skills valid." || (echo "Some skills failed validation." && exit 1)

# Count skills
count:
    @echo "$(find skills -name "SKILL.md" | wc -l | tr -d ' ') skills"

# Install a skill globally: just install development/commit-msg
install path:
    @mkdir -p ~/.claude/skills && \
    name=$(basename "{{path}}") && \
    ln -sf "$(pwd)/skills/{{path}}" ~/.claude/skills/"$name" && \
    echo "Installed $name → ~/.claude/skills/$name"

# Install all skills globally (replaces existing)
install-all:
    @mkdir -p ~/.claude/skills && \
    find skills -name "SKILL.md" | while read f; do \
        dir=$(dirname "$f"); \
        name=$(basename "$dir"); \
        ln -sf "$(pwd)/$dir" ~/.claude/skills/"$name"; \
        echo "Installed $name → ~/.claude/skills/$name"; \
    done && \
    echo "Done. $(find skills -name "SKILL.md" | wc -l | tr -d ' ') skills installed."

# Uninstall a skill: just uninstall commit-msg
uninstall name:
    @rm -f ~/.claude/skills/{{name}} && \
    echo "Uninstalled {{name}}"
