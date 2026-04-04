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

### Progressive disclosure — the core design

Workplane is built for **progressive disclosure**. A reviewer should be able to glance at a workstream in 30 seconds and know what happened, OR spend 30 minutes diving into every decision. Your job is to make both paths work:

| Layer | Field | Who reads it | What it needs |
|-------|-------|-------------|---------------|
| **Glance** | WorkStream `summary` | Everyone | 2-3 plain-text sentences. What changed, why it matters, what the outcome is. A busy person reads ONLY this. |
| **Scan** | WorkUnit `title` + `summary` | Most reviewers | Sections start collapsed. The title + summary is all they see. Write it so someone can scan 10 workunits in under a minute and know which ones to expand. |
| **Read** | WorkUnit `content` | Interested reviewers | The full story — what changed, why, how, what else was considered. Rich markdown with visuals, code snippets, tables. This is where the depth lives. |
| **Inspect** | `metadata_json` | Reviewer agents | Machine-readable reasoning: why, approach, alternatives, risks, assumptions. Agents consume this to validate the work programmatically. |

**Every layer must stand on its own.** The summary must be useful without reading content. The content must be useful without reading metadata_json. Each layer adds depth, not corrections to the layer above.

### Writing summaries (CRITICAL — this is what people actually read)

The `summary` field is **plain text, 2-3 sentences**. It's the single most important thing you write because most reviewers stop here. A good summary answers: what did you do, why, and what's the outcome?

**Bad:** "Updated authentication" — says nothing actionable.

**Good:** "Reordered JWT validation to check token expiry before issuer, fixing stale sessions on custom domain deployments. Added 30s clock skew tolerance. All existing tests pass, one new test added."

WorkUnit summaries follow the same rule. They show when the section is collapsed — the reviewer decides whether to expand based on this alone.

### Writing WorkUnit content (MANDATORY depth)

Content is where you go deep. This is GFM+HTML markdown — use its full power. Every workunit `content` field must cover **all** of the following that apply:

1. **What changed** — specific files, functions, components, endpoints. Not "updated the backend" but "added `validate_token_expiry()` in `auth.py` that checks JWT `exp` claim against server time with 30s clock skew tolerance"
2. **Why this approach** — the reasoning chain, constraints, what you learned from the codebase that informed the choice
3. **What was considered and rejected** — alternatives and why they lost. "Considered middleware-level validation but rejected because the auth flow requires per-route token scoping"
4. **How it works** — enough detail for another agent to understand without reading code. Include code snippets for non-obvious logic
5. **What could go wrong** — edge cases, failure modes, assumptions that might not hold
6. **Dependencies and interactions** — what other parts of the system this touches, what breaks if this changes

**A workunit with shallow content defeats the purpose of Workplane.** The whole point is that someone can drill into any section and get the full picture. "Added token validation to the auth flow" is unacceptable — that tells a reviewer nothing they couldn't get from a git diff subject line.

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

## Step 3: Add Visuals (MANDATORY — before any update)

Every workunit MUST have visuals. **Use Canvas for live previews** — it's better than screenshots because reviewers see interactive, rendered components directly in the browser.

### Option A: Canvas (preferred)

Write TSX components, compile them against your project's real dependencies, and publish as a live preview. Reviewers see the rendered output in an iframe — no screenshots needed.

1. **Create a directory** with your TSX source files:

```
my-canvas/
├── App.tsx        # entry component
└── helpers.ts     # optional supporting files
```

2. **Publish with the CLI:**

```bash
workplane publishCanvas \
  --directory ./my-canvas \
  --title "Auth flow redesign" \
  --workspace-id <uuid> \
  --workstream-id <uuid>    # optional — creates one if omitted
```

The CLI auto-detects your project root (via `vite.config.ts`), compiles with Vite against your real `node_modules` and Tailwind config, and uploads the result. The reviewer sees a live rendered preview with source code viewer and version history.

**What to canvas:**
- UI changes — before/after states as components
- Architecture diagrams — render with a charting library
- Data flows — interactive visualizations
- Mockups — build them in TSX with your real design system

**Canvas compiles against your project.** You can import your actual components, use your Tailwind classes, and render with real data. This is not a toy sandbox — it's your real codebase.

### Option B: Image upload (fallback)

For cases where Canvas doesn't fit (e.g., terminal screenshots, external tool output):

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

Use the REST API via curl for updates — it handles complex nested JSON better than CLI flags:

```bash
curl -X PUT "${API_BASE_URL}/api/workstreams/${WORKSTREAM_ID}/update" \
  -H "Authorization: Bearer $(workplane status --token-only)" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "...",
    "summary": "...",
    "content": "![Hero visual](url)\n\n...",
    "status": "draft",
    "git_info": {"repo_url": "https://github.com/owner/repo", "branch": "feat/..."},
    "metadata_json": {"why": "...", "approach": "..."},
    "workunits": [
      {"id": "existing-uuid", "type": "ui", "title": "...", "summary": "...", "content": "![img](url)\n..."},
      {"type": "new-section", "title": "...", "content": "..."}
    ]
  }'
```

Where `API_BASE_URL` is `https://api.workplane.co` (or your local dev URL).

- Include `id` of existing workunits to preserve them and their comments
- Omit `id` to create new workunit
- Omit an existing workunit from the array to remove it

For simpler updates (just fields, no workunits), use the CLI:

```bash
workplane updateWorkstream --workstream_id <uuid> --title "New title" --status "in_review"
```

## Step 5: Share the Link

After publishing, share the workstream URL:
`https://workplane.co/workstreams/{WORKSTREAM_ID}`

## Structuring Work

- **Summary is king.** Most people read only the workstream summary. Make it count — what changed, why, outcome.
- **WorkUnit summaries are what people scan.** Sections start collapsed. Title + summary is all they see. Write summaries that let someone scan 10 sections in a minute.
- **Content is where you go deep.** The person who expands a section wants the full story. Give it to them — code snippets, tables, before/after, reasoning chains.
- **Order workunits by importance, not chronology.** Position 1 = what the reviewer needs most.
- **Break into focused workunits.** Common types: `ui`, `architecture`, `data_model`, `decision`, `testing`, `needs_input`.
- **Content is GFM+HTML.** Use tables, code blocks, embedded images — whatever makes the work clearest.
- **Update early, update often.** Don't wait until done.

## Visual-First Checklist

**With Canvas (preferred):**
1. Create a directory with TSX source files showing the before/after or key visual
2. `workplane publishCanvas --directory ./my-canvas --title "..." --workspace-id <uuid> --workstream-id <uuid>`
3. The canvas renders live in the workunit — no further embedding needed
4. Update workstream content and metadata via the update API

**With images (fallback):**
1. Screenshot before and after states
2. `requestUploadUrl` → `curl -X PUT` → embed `public_url` in content
3. Update workstream via the update API

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Publishing without asking which workspace | Always list workspaces and ask first (unless WORKPLANE.md has a default) |
| Creating a new workspace instead of using existing | List workspaces, present options to user |
| Publishing text-only workunits | Use Canvas (preferred) or upload images — every workunit needs visuals |
| Deferring visuals to second pass | Publish canvas or upload images BEFORE calling the update API |
| Using screenshots when Canvas would work | Canvas gives live interactive previews — use it for UI, diagrams, mockups |
| Losing comment threads | Preserve workunit `id` when updating |
| Overwriting reviewer feedback | Read comments before updating |
| Generic summaries ("Updated auth") | Summaries are what people read — be specific about what, why, and outcome |
| Shallow workunit content | Content is where depth lives — explain what, why, how, alternatives, risks |
| Minimal metadata_json | Must contain high-density reasoning context |
| Same level of detail in summary and content | Summary = glance (2-3 sentences), content = deep dive (full reasoning) |
| Referencing local file paths as content | Embed the substance — readers have no filesystem access |
| Not including git_info on code work | Always set git_info with repo_url, branch, pr_url |
