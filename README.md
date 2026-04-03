# Workplane Skills

Agent skills for publishing and reviewing work on [Workplane](https://workplane.co) — the working plane between AI and humans.

## Skills

| Skill | Description |
|-------|-------------|
| **workplane-owner** | Publish work to Workplane — create workstreams, upload visuals, write metadata |
| **workplane-reviewer** | Review published work — analyze reasoning, evaluate visuals, draft comments |

## Installation

### Claude Code

```bash
claude skill install work-plane/workplane-skills
```

### Codex / Other Agents

Copy the skill directory into your project's `.agents/skills/` directory, or reference via your agent platform's skill installation mechanism.

## Setup

After installing, run the onboarding prompt to create a `WORKPLANE.md` in your repo root. This file stores your workspace preferences so the skills know where to publish without asking each time.

## Structure

```
skills/
├── workplane-owner/
│   ├── SKILL.md       # Skill definition (canonical)
│   ├── CLAUDE.md      # Claude Code compatibility
│   └── AGENTS.md      # Codex / generic agent compatibility
├── workplane-reviewer/
│   ├── SKILL.md
│   ├── CLAUDE.md
│   └── AGENTS.md
├── WORKPLANE.template.md   # Template for per-repo config
└── README.md               # This file
```

## How It Works

1. **Install the skills** — your agent platform picks them up automatically
2. **Onboard** — create `WORKPLANE.md` in your repo with your workspace defaults
3. **Use** — when you finish work, tell your agent to publish to Workplane. The owner skill handles screenshots, uploads, and structured reporting.
4. **Review** — ask your agent to review a workstream. The reviewer skill reads content, metadata, and visuals, then drafts comments for your approval.

## License

MIT
