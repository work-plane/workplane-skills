# Workplane Skills

Agent skill for publishing and reviewing work on [Workplane](https://workplane.co) — the working plane between AI and humans.

## Skills

| Skill | Description |
|-------|-------------|
| **workplane** | Publish or review work using the Workplane MCP server — create artifacts, upload items, tag snapshots, manage sharing |

## Installation

### Claude Code

```bash
claude skill install work-plane/workplane-skills
```

### Cursor

One-click install via deep link — paste this URL in your browser:

```
cursor://anysphere.cursor-deeplink/mcp/install?name=workplane&config=eyJ0eXBlIjoiaHR0cCIsInVybCI6Imh0dHBzOi8vd29ya3BsYW5lLmNvL2FwaS9tY3AifQ==
```

Or install the plugin from the Cursor Marketplace, or add the MCP server manually in `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "workplane": {
      "type": "http",
      "url": "https://workplane.co/api/mcp"
    }
  }
}
```

### OpenAI Codex

```bash
codex mcp add workplane --url https://workplane.co/api/mcp
```

Or add directly to `~/.codex/config.toml`:

```toml
[mcp_servers.workplane]
url = "https://workplane.co/api/mcp"
```

The skill file at `workplane/AGENTS.md` is automatically picked up by Codex when placed in your project root.

### Devin

```bash
devin mcp add workplane https://workplane.co/api/mcp
```

Or add to `.devin/config.json` (project-scoped) or `~/.config/devin/config.json` (global):

```json
{
  "mcpServers": {
    "workplane": {
      "url": "https://workplane.co/api/mcp"
    }
  }
}
```

The skill file at `workplane/SKILL.md` is automatically picked up when placed in `.devin/skills/workplane/SKILL.md`.

### VS Code (GitHub Copilot)

One-click install via deep link — paste this URL in your browser:

```
vscode:mcp/install?%7B%22name%22%3A%22workplane%22%2C%22type%22%3A%22http%22%2C%22url%22%3A%22https%3A%2F%2Fworkplane.co%2Fapi%2Fmcp%22%7D
```

Or add the MCP server in VS Code settings.

### Other MCP-aware clients (Windsurf, Zed, Cline, etc.)

Paste this MCP config into your client's configuration:

```json
{
  "mcpServers": {
    "workplane": {
      "type": "http",
      "url": "https://workplane.co/api/mcp"
    }
  }
}
```

## Structure

```
workplane/
  SKILL.md           # Skill instructions (Claude Code, Devin)
  AGENTS.md          # Same content as SKILL.md (Codex compatibility)
.claude-plugin/      # Claude Code marketplace manifest
.cursor-plugin/      # Cursor marketplace manifest
mcp.json             # MCP server config (Cursor auto-discovers this)
README.md            # This file
```

## How It Works

1. **Install** — pick your AI tool above, add the MCP server with one command or click
2. **Publish** — when you finish work, tell your agent to publish to Workplane. The skill uses MCP tools to create an artifact, upload files, snapshot with a tag, and share.
3. **Review** — point your agent at a workplane.co URL or project address. The skill uses MCP tools to list, read, and pull the project contents for review.

## License

MIT License. See [workplane.co](https://workplane.co) for more information.
