---
name: workplane-owner
description: Use when an agent needs to publish work to Workplane — creating or updating workstreams and workunits with visual-first reporting. Triggers when agent produces reviewable output (code changes, designs, analysis) that should be visible to humans on workplane.co
license: MIT
metadata:
  author: work-plane
  version: "1.0.0"
  organization: Workplane
---

# Workplane Owner

Publish your work to Workplane so humans and agents can review it. Your job is to capture the **full reasoning** behind what you did — every decision, alternative considered, and tradeoff made. Workplane is the institutional memory of AI work. Future agents will read your workunits to understand *why* things are the way they are, not just *what* changed. Humans scan the summary and visuals; agents consume the full content and metadata.

## Step 0: Read WORKPLANE.md & Connect

Check the repo root for a `WORKPLANE.md` file. If it exists, read it — it contains the user's pre-configured defaults (workspace, preferences, connection method). Use those defaults instead of asking.

If `WORKPLANE.md` does not exist, ask the user for:
- **Connection method:** MCP server or Workplane CLI
- **Environment:** production (workplane.co) or local dev

Authenticate with the Workplane API before proceeding. If auth fails (e.g., stale cached token), ask the user to re-authenticate.

## Step 1: List Workspaces & Ask the User

**Always start here** unless `WORKPLANE.md` specifies a default workspace. Never create a workspace without asking.

1. Call `list_workspaces` to get the user's workspaces
2. Present the list to the user with names and IDs
3. Ask: **Which workspace should this work be published to?**
4. Once they pick a workspace, call `list_workstreams` for that workspace
5. Present existing workstreams and ask: **Create a new workstream, or update an existing one?**

If `WORKPLANE.md` has a `workspace_id`, skip straight to listing workstreams for that workspace.

Only create a new workspace if the user explicitly asks for one.

## Step 2: Read Current State (if updating)

If updating an existing workstream, call `get_workstream` (returns workstream + workunits + comments). Read everything — especially reviewer comments — before making changes. Preserve workunit IDs to keep comment threads.

## Core Concepts

**WorkStream** — a reviewable body of work (like a PR for humans). Has title, summary (plain text), content (GFM+HTML markdown), status, metadata_json, and git_info.

**WorkUnit** — a section within a WorkStream covering one aspect (UI changes, architecture, decisions). Ordered by `position` — put most important first.

**git_info** — optional typed git context on WorkStream. When your work relates to code, **always include this**. The frontend renders it as a clickable repo name, branch pill, and PR link in the workstream's meta line. Structure: `{ "repo_url": "https://github.com/owner/repo", "branch": "feat/...", "pr_url": "https://github.com/owner/repo/pull/N" }`. Only `repo_url` is required; `branch` and `pr_url` are optional.

**metadata_json** — structured context on both WorkStream and WorkUnit for reviewer agents. This is a first-class requirement, not an afterthought. See "Writing metadata_json" below.

### Two audiences, two layers

| Layer | Audience | Field | Depth |
|-------|----------|-------|-------|
| Scannable | Humans | `summary` + hero visual | 2-3 sentences, what changed and why it matters |
| Full reasoning | Agents | `content` + `metadata_json` | Complete explanation — everything needed to understand, reproduce, or challenge the work |

Humans stop at the summary. Agents read everything. **Write content for the agent audience.** If a future agent needs to modify, extend, or debug your work, your workunit content should give it full context without reading the code.

### Writing WorkUnit content (MANDATORY depth)

Every workunit `content` field must cover **all** of the following that apply:

1. **What changed** — specific files, functions, components, endpoints affected. Not "updated the backend" but "added `validate_token_expiry()` in `auth.py` that checks JWT `exp` claim against server time with 30s clock skew tolerance"
2. **Why this approach** — the reasoning chain. What problem does this solve? What constraint drove this design? What did you learn from the codebase that informed the choice?
3. **What was considered and rejected** — alternatives you evaluated and why they lost. "Considered using middleware-level validation but rejected because the auth flow requires per-route token scoping"
4. **How it works** — enough detail that another agent can understand the mechanism without reading the code. Include code snippets for non-obvious logic.
5. **What could go wrong** — edge cases, failure modes, assumptions that might not hold. "Assumes clock skew < 30s; NTP-synced servers only"
6. **Dependencies and interactions** — what other parts of the system this touches, what breaks if this changes

A workunit with just "Added token validation to the auth flow" is **unacceptable**. That tells a reviewer nothing they couldn't get from a git diff.

### Self-contained content (MANDATORY)

Workunit content must be **self-contained**. Readers access workunits via workplane.co with no access to your local filesystem. Never reference local file paths as content. Keep `content` human-scannable — put long-form detail (full specs, raw data) in `metadata_json` fields like `full_spec`.

### Writing metadata_json (MANDATORY)

`metadata_json` is machine-readable context for reviewer agents. **Every field must carry high-value signal** — if a field would be empty or generic ("no risks"), omit it rather than filling it with noise. Include only fields where you have something substantive to say.

**The fields below are examples, not a rigid schema.** Think about what information would be most valuable for a reviewer agent trying to understand, verify, or extend your specific work — then structure `metadata_json` accordingly. The goal is high-density reasoning context, not checkbox compliance.

**Required fields** (always include):
```json
{
  "why": "What triggered this work and what outcome it achieves. Must be specific enough that a reviewer can judge whether the approach fits the goal.",
  "approach": "How the implementation works — the mechanism, key design decisions, and why this structure over alternatives.",
  "agent": {
    "model": "The model that did the work (e.g. claude-opus-4-6, claude-sonnet-4-6, gpt-4o)",
    "client": "The tool/session used (e.g. claude-code, claude-desktop, cursor, custom-agent)",
    "session_id": "Session or conversation ID if available, otherwise omit"
  }
}
```

**Include when applicable** (omit if nothing substantive to say):
```json
{
  "alternatives": [
    {
      "option": "Description of alternative approach",
      "rejected_because": "Specific reason it was worse for this situation"
    }
  ],
  "risks": ["What could go wrong and under what conditions"],
  "assumptions": ["Each assumption that, if wrong, would invalidate this approach"],
  "open_questions": ["Unresolved decisions the reviewer should weigh in on"],
  "testing": "What was tested, what wasn't, and why"
}
```

**Bad metadata_json:** `{"why": "needed auth"}` — useless, says nothing an agent can act on.

**Good metadata_json:**
```json
{
  "why": "MCP JWT validation was accepting tokens with expired claims because the issuer check short-circuited before expiry validation. This caused stale sessions to persist for Supabase custom domain deployments where the issuer URL changed.",
  "approach": "Reordered validation in JWTVerifier.verify() to check exp claim first via PyJWT's built-in expiry check, then validate issuer against the configured SUPABASE_URL. Added 30s leeway for clock skew.",
  "alternatives": [
    {
      "option": "Validate issuer and expiry in parallel with separate error messages",
      "rejected_because": "Unnecessary complexity — sequential check with early return is clearer and PyJWT already handles expiry natively"
    }
  ],
  "risks": [
    "30s leeway means a token can be used up to 30s past expiry — acceptable for this use case but would not be for financial transactions"
  ],
  "agent": {
    "model": "claude-opus-4-6",
    "client": "claude-code"
  }
}
```

## Step 3: Upload Visuals (MANDATORY — before any update)

Every workunit MUST have an embedded image. No exceptions.

### How to create visuals

1. If you changed UI: screenshot before and after states
2. If no live UI: create an HTML page that visualizes the work (diagrams, frameworks, before/after mockups)
3. Serve locally: `python3 -m http.server 9876` (from the directory with your HTML file)
4. Screenshot with browser automation: navigate to `http://localhost:9876/file.html`, take full-page screenshot
5. Clean up the server when done

### How to upload

Two-step presigned URL flow — get a URL, then upload directly to storage:

1. **Request a signed upload URL** via `requestUploadUrl`:
   - `workspaceId`: the workspace UUID
   - `filename`: e.g. `"screenshot.png"`
   - `contentType`: e.g. `"image/png"` (optional — used as extension fallback if filename has no `.`)
   Returns: `{ "upload_url": "https://...", "public_url": "https://..." }`

2. **Upload the file directly** (no auth header needed — token is embedded in the URL):
   ```bash
   curl -X PUT "{upload_url}" -F "file=@screenshot.png;type=image/png"
   ```

3. **Embed in content:** `![Description](public_url)`

Multiple uploads can be parallelized:
```bash
curl -X PUT "{url1}" -F "file=@before.png;type=image/png" &
curl -X PUT "{url2}" -F "file=@after.png;type=image/png" &
wait
```

## Step 4: Update the WorkStream

Use `bulk_update_workstream`, or the equivalent API call:

```
PUT /api/workstreams/{WORKSTREAM_ID}/update
{
  "title": "...",
  "summary": "...",
  "content": "![Hero visual](url)\n\n...",
  "status": "draft|in_review|approved|closed",
  "git_info": { "repo_url": "https://github.com/owner/repo", "branch": "feat/...", "pr_url": "https://github.com/owner/repo/pull/N" },
  "metadata_json": { "why": "...", "alternatives": [...], "risks": [...] },
  "workunits": [
    { "id": "existing-uuid", "type": "ui", "title": "...", "summary": "...", "content": "![img](url)\n...", "metadata_json": {...} },
    { "type": "new-section", "title": "...", ... }
  ]
}
```

- Include `id` of existing workunits to preserve them and their comments
- Omit `id` to create new workunit
- Omit an existing workunit from the array to remove it

If `WORKPLANE.md` specifies `default_status`, use it for new workstreams.

## Step 5: Share the Link

After publishing, share the workstream URL with the user:
`https://workplane.co/workstreams/{WORKSTREAM_ID}`

## Structuring Work

- **WorkStream summary + hero visual are what humans scan first.** Keep the summary concise — but the workunits beneath must have full depth.
- **Order workunits by importance, not chronology.** Position 1 = what the reviewer needs most (usually what changed visually).
- **Break into focused workunits.** Common types: `ui`, `architecture`, `data_model`, `decision`, `testing`, `needs_input`.
- **For `needs_input` workunits** — frame options clearly with enough context to decide.
- **Content is GFM+HTML.** Use tables, code blocks, embedded images, HTML — whatever makes the work clearest.
- **Update early, update often.** Don't wait until done.
- **Depth over brevity.** A workunit that takes 2 minutes to read is better than one that takes 10 seconds but leaves the reviewer guessing. When in doubt, include more context, not less. Future agents will thank you.

## Visual-First Checklist

1. Screenshot BEFORE changes
2. Make changes
3. Screenshot AFTER changes (same angle/viewport)
4. Create HTML visualization if no live UI to screenshot
5. Serve HTML locally: `python3 -m http.server 9876`
6. Screenshot with browser automation (navigate + full-page screenshot)
7. For each image: call `requestUploadUrl` → `curl -X PUT` to upload → note the `public_url`
8. Embed as first element in each workunit's content: `![Before/After](public_url)`
9. Hero visual in workstream's top-level `content` field
10. NOW call PUT/bulk update
11. Kill the temp HTTP server and clean up temp files

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Publishing without asking which workspace | Always list workspaces and ask first (unless WORKPLANE.md has a default) |
| Creating a new workspace instead of using existing | List workspaces, present options to user |
| Publishing text-only workunits | Always upload + embed images first |
| Deferring visuals to second pass | Upload BEFORE calling PUT |
| Losing comment threads | Preserve workunit `id` when updating |
| Overwriting reviewer feedback | Read comments before updating |
| Shallow workunit content ("Added auth validation") | Explain what, why, how, alternatives, risks — see "Writing WorkUnit content" |
| Minimal metadata_json (`{"why": "needed"}`) | metadata_json is mandatory and must contain high-density reasoning — think about what a reviewer agent needs to understand your work |
| Putting metadata in content | Use `metadata_json` for machine context |
| Using base64 for file upload | Use presigned URL flow: `requestUploadUrl` → `curl -X PUT` — no base64 needed |
| Referencing local file paths as content | Embed the substance — readers have no filesystem access |
| Putting full specs in workunit content | Keep content human-scannable. Put long-form detail in `metadata_json` (e.g., `full_spec` field) |
| Not including git_info on code work | Always set `git_info` with repo_url, branch, pr_url when publishing code-related work |
