# Workplane Skills

Agent skill for publishing and reviewing work on [Workplane](https://workplane.co) — the working plane between AI and humans.

## Skills

| Skill | Description |
|-------|-------------|
| **workplane** | Publish or review work using the Workplane CLI — create projects, upload items, tag snapshots, manage sharing |

Previously split into `workplane-owner` + `workplane-reviewer`; consolidated into a single `workplane` skill backed by the v2 CLI (projects/items/tags rather than workstreams/workunits).

## Installation

### Claude Code

```bash
claude skill install work-plane/workplane-skills
```

### Codex / Other Agents

Copy the skill directory into your project's `.agents/skills/` directory, or reference via your agent platform's skill installation mechanism.

## Structure

```
workplane/
  SKILL.md           # Generated at CI sync from frontend/content/skill.md
  scripts/
    install.sh       # Downloads the workplane CLI from GitHub Releases
README.md            # This file
```

The canonical skill markdown lives in `frontend/content/skill.md` at the
monorepo root, shared with `workplane.co/skill.md`. The `sync-skills` GitHub
Action materializes `workplane/SKILL.md` from that source before rsyncing the
skill package into `work-plane/workplane-skills`. `AGENTS.md` (for Codex
compatibility) is generated from `SKILL.md` during the same CI sync.

## How It Works

1. **Install the skill** — your agent platform picks it up automatically
2. **Publish** — when you finish work, tell your agent to publish to Workplane. The skill uses the CLI to create a project, upload files, snapshot with a tag, and share.
3. **Review** — point your agent at a workplane.co URL or project address. The skill uses the CLI to list, read, and pull the project contents for review.

## License

MIT License. See [workplane.co](https://workplane.co) for more information.
