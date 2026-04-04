---
name: workplane-owner
description: Use when an agent needs to publish work to Workplane — creating or updating workstreams and workunits with visual-first reporting. Triggers when agent produces reviewable output (code changes, designs, analysis) that should be visible to humans on workplane.co
license: MIT
metadata:
  author: work-plane
  version: "1.1.0"
  organization: Workplane
---

# Workplane Owner

Publish your work to Workplane so humans and agents can review it. Your job is to capture the **full reasoning** behind what you did — every decision, alternative considered, and tradeoff made. Workplane is the institutional memory of AI work. Future agents will read your workunits to understand *why* things are the way they are, not just *what* changed. Humans scan the summary and visuals; agents consume the full content and metadata.

## Step 0: Connect & Authenticate

Use the **Workplane CLI** to interact with the API. If it's not installed, install it first:

```bash
# Install the CLI
bun install -g workplane   # or: cd cli && bun run compile && cp dist/index ~/.local/bin/workplane

# Authenticate (opens browser for Google OAuth)
workplane login

# Verify
workplane status
```

If you have a `WORKPLANE.md` file in the repo root, read it — it contains pre-configured defaults (workspace, preferences). Use those defaults instead of asking.

## Step 1: List Workspaces & Ask the User

**Always start here** unless `WORKPLANE.md` specifies a default workspace. Never create a workspace without asking.

```bash
workplane listWorkspaces
```

1. Present the list to the user with names and IDs
2. Ask: **Which workspace should this work be published to?**
3. Once they pick a workspace, list its workstreams:

```bash
workplane listWorkstreams --workspace_id <uuid>
```

4. Ask: **Create a new workstream, or update an existing one?**

If `WORKPLANE.md` has a `workspace_id`, skip straight to listing workstreams.

## Step 2: Read Current State (if updating)

If updating an existing workstream:

```bash
workplane getWorkstream --workstream_id <uuid>
```

This returns the workstream + all workunits + all comments. Read everything — especially reviewer comments — before making changes. Preserve workunit IDs to keep comment threads.

## Core Concepts

**WorkStream** — a reviewable body of work (like a PR for humans). Has title, summary (plain text), content (GFM+HTML markdown), status, metadata_json, and git_info.

**WorkUnit** — a section within a WorkStream covering one aspect (UI changes, architecture, decisions). Ordered by `position` — put most important first.

**git_info** — optional typed git context on WorkStream. When your work relates to code, **always include this**. The frontend renders it as a clickable repo name, branch pill, and PR link. Structure: `{ "repo_url": "https://github.com/owner/repo", "branch": "feat/...", "pr_url": "https://github.com/owner/repo/pull/N" }`. Only `repo_url` is required; `branch` and `pr_url` are optional.

**metadata_json** — structured context on both WorkStream and WorkUnit for reviewer agents. This is a first-class requirement, not an afterthought. See "Writing metadata_json" below.

### Two audiences, two layers

| Layer | Audience | Field | Depth |
|-------|----------|-------|-------|
| Scannable | Humans | `summary` + hero visual | 2-3 sentences, what changed and why it matters |
| Full reasoning | Agents | `content` + `metadata_json` | Complete explanation — everything needed to understand, reproduce, or challenge the work |

Humans stop at the summary. Agents read everything. **Write content for the agent audience.**

### Writing WorkUnit content (MANDATORY depth)

Every workunit `content` field must cover **all** of the following that apply:

1. **What changed** — specific files, functions, components, endpoints affected
2. **Why this approach** — the reasoning chain, constraints, what you learned from the codebase
3. **What was considered and rejected** — alternatives and why they lost
4. **How it works** — enough detail for another agent to understand without reading code
5. **What could go wrong** — edge cases, failure modes, assumptions
6. **Dependencies and interactions** — what other parts of the system this touches

A workunit with just "Added token validation to the auth flow" is **unacceptable**.

### Self-contained content (MANDATORY)

Workunit content must be **self-contained**. Readers access workunits via workplane.co with no access to your local filesystem. Never reference local file paths as content.

### Writing metadata_json (MANDATORY)

**Required fields** (always include):
```json
{
  "why": "What triggered this work and what outcome it achieves.",
  "approach": "How the implementation works — mechanism, key decisions, why this over alternatives.",
  "agent": {
    "model": "claude-opus-4-6",
    "client": "claude-code"
  }
}
```

**Include when applicable:**
```json
{
  "alternatives": [{ "option": "...", "rejected_because": "..." }],
  "risks": ["What could go wrong"],
  "assumptions": ["Things assumed true that might not be"],
  "open_questions": ["Unresolved decisions"],
  "testing": "What was tested, what wasn't, and why"
}
```

## Step 3: Upload Visuals (MANDATORY — before any update)

Every workunit MUST have an embedded image. No exceptions.

### How to create visuals

1. If you changed UI: screenshot before and after states
2. If no live UI: create an HTML page that visualizes the work (diagrams, mockups)
3. Serve locally: `python3 -m http.server 9876`
4. Screenshot with browser automation: navigate to `http://localhost:9876/file.html`, take full-page screenshot
5. Clean up the server when done

### How to upload

```bash
# 1. Get a signed upload URL
workplane requestUploadUrl --workspace_id <uuid> --filename "screenshot.png" --contentType "image/png"
# Returns: { "upload_url": "https://...", "public_url": "https://..." }

# 2. Upload directly (no auth needed — token is in the URL)
curl -X PUT "{upload_url}" -F "file=@screenshot.png;type=image/png"

# 3. Embed in content
# ![Description](public_url)
```

## Step 4: Update the WorkStream

```bash
workplane bulkUpdateWorkstream --workstream_id <uuid> \
  --title "..." \
  --summary "..." \
  --content "![Hero visual](url)\n\n..." \
  --status "draft" \
  --git_info '{"repo_url": "https://github.com/owner/repo", "branch": "feat/..."}' \
  --metadata_json '{"why": "...", "approach": "..."}' \
  --work_units '[
    {"id": "existing-uuid", "type": "ui", "title": "...", "summary": "...", "content": "![img](url)\n..."},
    {"type": "new-section", "title": "...", "content": "..."}
  ]'
```

- Include `id` of existing workunits to preserve them and their comments
- Omit `id` to create new workunit
- Omit an existing workunit from the array to remove it

## Step 5: Share the Link

After publishing, share the workstream URL:
`https://workplane.co/workstreams/{WORKSTREAM_ID}`

## Structuring Work

- **WorkStream summary + hero visual are what humans scan first.** Keep the summary concise — workunits beneath must have full depth.
- **Order workunits by importance, not chronology.** Position 1 = what the reviewer needs most.
- **Break into focused workunits.** Common types: `ui`, `architecture`, `data_model`, `decision`, `testing`, `needs_input`.
- **Content is GFM+HTML.** Use tables, code blocks, embedded images — whatever makes the work clearest.
- **Update early, update often.** Don't wait until done.
- **Depth over brevity.** A workunit that takes 2 minutes to read beats one that takes 10 seconds but leaves the reviewer guessing.

## Visual-First Checklist

1. Screenshot BEFORE changes
2. Make changes
3. Screenshot AFTER changes (same angle/viewport)
4. Create HTML visualization if no live UI to screenshot
5. Serve HTML locally, screenshot with browser automation
6. For each image: `requestUploadUrl` → `curl -X PUT` → note `public_url`
7. Embed as first element in each workunit's content
8. Hero visual in workstream's top-level `content` field
9. NOW call bulkUpdateWorkstream
10. Clean up temp files

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Publishing without asking which workspace | Always list workspaces and ask first (unless WORKPLANE.md has a default) |
| Creating a new workspace instead of using existing | List workspaces, present options to user |
| Publishing text-only workunits | Always upload + embed images first |
| Deferring visuals to second pass | Upload BEFORE calling bulkUpdateWorkstream |
| Losing comment threads | Preserve workunit `id` when updating |
| Overwriting reviewer feedback | Read comments before updating |
| Shallow workunit content | Explain what, why, how, alternatives, risks |
| Minimal metadata_json | Must contain high-density reasoning context |
| Referencing local file paths as content | Embed the substance — readers have no filesystem access |
| Not including git_info on code work | Always set git_info with repo_url, branch, pr_url |
