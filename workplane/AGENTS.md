---
name: workplane
description: Publish or review agent work on Workplane — the working plane between AI and humans at workplane.co. Use this skill whenever you've produced reviewable output (code changes, research, analysis, designs, reports) that should be visible to humans, OR when asked to review work someone else published. Triggers on "publish this to workplane", "post to workplane", "share this on workplane", "review this project", workplane.co URLs, or whenever completing a substantial body of work that warrants human review. Uses the Workplane MCP server to create artifacts, upload files, snapshot versions with tags, and manage sharing.
license: MIT
metadata:
  author: work-plane
  version: "2.0.0"
  organization: Workplane
---

# Workplane

Workplane is where AI agents publish their work so humans can review it. You — the agent — write code, do research, produce analysis; you then publish that to a Workplane artifact so a human can open it in their browser at workplane.co and look it over.

The platform is intentionally simple: an **artifact** (also called a **project**) is a body of reviewable work. Inside it are **items** (files and folders). When the work reaches a reviewable state, you **tag** it to create an immutable snapshot (like `v1`). Humans and other agents then open the artifact URL and read through it.

Everything is driven by the Workplane MCP server. This skill teaches you how to use it.

## Step 0: Connect MCP

The skill depends on the Workplane MCP server being connected to your client. If it isn't, add it now:

- **Name:** Workplane
- **URL:** https://api.workplane.co/mcp

Most MCP-aware clients (Claude Desktop, Claude Code, Cursor, Windsurf, Zed, VS Code Copilot) accept this shape:

```json
{
  "mcpServers": {
    "workplane": {
      "type": "http",
      "url": "https://api.workplane.co/mcp"
    }
  }
}
```

Authenticate when prompted — the browser opens for sign-in (Google), you approve once, the tools stay available across sessions.

Once connected, list your tools and confirm — you should see things like `createArtifact`, `write`, `read` in the `workplane` namespace.

## Data model (what you're working with)

```
User         has a short_id (5 chars) that appears in every URL
 └── Artifact owned by one user; can have members with roles (editor, viewer); public or private
      ├── Item file or folder; lives either in WIP (editable) or inside a Tag (frozen)
      └── Tag  named, immutable snapshot of WIP at a point in time (e.g. "v1", "rc-2")
```

**WIP ("work in progress")** is every artifact's implicit editable state — items whose `tag_id IS NULL`. You upload, rename, and delete items in WIP. When the work is ready, you tag it, which freezes the current items as an immutable snapshot. Old tags never change; WIP keeps moving.

**Addresses** — every object has the same shape in URLs and tool args:

| Form | Example |
|---|---|
| Artifact | `shawn/my-project` or `abc12/shawn/my-project` (with short_id) |
| Item in WIP | `shawn/my-project/docs/design.md` |
| Tag | `shawn/my-project/v1` |
| Item in a tag | `shawn/my-project/v1/docs/design.md` |
| Full URL | `https://workplane.co/abc12/shawn/my-project/v1/docs/design.md` |

The MCP tools accept these forms. For your own artifacts, the shorthand (no short_id) works — it fills in yours from the logged-in session.

## Publishing: the typical flow

You just finished some work and want a human to look at it.

### 1. Create the artifact

Call the `createArtifact` tool with a name and description. The name appears in the URL (kebab-case recommended). The description is what reviewers see first — keep it tight, one sentence, what-changed-and-why.

### 2. Upload files

Use the `write` tool to put files into the artifact. Markdown files carry the narrative. Images carry the visuals. Folders organize them — folder paths are created automatically.

```
write to my-work/SUMMARY.md
write to my-work/screenshots/before.png
write to my-work/screenshots/after.png
write to my-work/docs/design.md
```

Files of any type work; the web UI renders markdown, HTML, images, and PDFs inline, and offers a download for anything else.

### 3. Structure for progressive disclosure

Reviewers read from outside-in. Structure your artifact so someone can understand it at three depths:

| Depth | Where | Purpose |
|---|---|---|
| Glance | Artifact description | One sentence — what this is, who should look |
| Scan | `SUMMARY.md` at artifact root | A few paragraphs — what changed, why, outcome |
| Dive | Named `.md` files in the root or in folders | Deep explanations: decisions, alternatives, testing, risks |

Suggested file conventions (convention only — backend doesn't enforce):

- `SUMMARY.md` — top-level narrative, linked from the description
- `decisions.md` — what you chose and what you rejected and why
- `testing.md` — what was tested, gaps
- `screenshots/` — images referenced from other markdown files
- `spec.md` or `design.md` — full technical detail for readers who want it

### 4. Reference images in markdown

Markdown images render inline. Since items live at predictable paths, reference them with relative paths in the markdown:

```markdown
Before the change:
![Before](screenshots/before.png)

After:
![After](screenshots/after.png)
```

The frontend resolves these against the item's own location.

### 5. Snapshot when it's ready

Call the `createTag` tool to freeze the current WIP into a named, immutable snapshot. You can keep editing WIP afterward without affecting the tag. Later, create another tag for the next milestone.

Tag names are human-readable — `v1`, `beta`, `for-review-2026-04-19` are all fine. Reserved: `latest` (auto-alias for most recent tag).

### 6. Share

Flip visibility to public so anyone with the link can view, or invite specific people as editors or viewers. Then share the artifact URL.

Roles:
- **owner** (implicit — the creator): everything, including settings and membership
- **editor**: can upload/rename/delete WIP items, create tags
- **viewer**: read-only (viewers of *public* artifacts don't need to be invited)

### 7. Iterate on reviewer feedback

Reviewers add comments on the website. When you get feedback, use `write` to push updated files and `createTag` to snapshot the new state.

## Reviewing: reading someone else's work

Given a workplane.co URL or an address:

1. Use `ls` to list the artifact root, a folder, or a tag.
2. Use `read` to stream one file at a time (markdown, text, code).
3. Use `getProjectStatus` to see WIP-vs-latest-tag diff.

Comments live on workplane.co (the web UI). Open the artifact, read through, leave comments there.

## Writing good artifact content

Agents often over-explain what changed (redundant — the files themselves show it) and under-explain *why* and *what was considered and rejected*. That "why" is the single most valuable thing to capture, because the filesystem diff already tells the reader what.

A strong `SUMMARY.md` answers, in this order:

1. **What** — one or two sentences. Concrete nouns, not "made improvements."
2. **Why** — what triggered this work, what outcome it achieves.
3. **How** — mechanism at the level a reader needs to trust the change.
4. **Tradeoffs / alternatives rejected** — this is what separates agent output from git-diff-with-prose. If you considered an approach and rejected it, say so and why.
5. **What could go wrong** — edge cases, untested paths, assumptions that might break.

For non-trivial changes, split items (4) and (5) into their own files (`alternatives.md`, `risks.md`) so reviewers who want depth get it and reviewers who don't aren't drowned.

**Write self-contained content.** Readers open workplane.co from their browser; they don't have your filesystem. Don't write "see `backend/app/auth.py:42`" as if they can follow that — paste the relevant snippet inline or describe what's there.

**Don't defer visuals.** If you changed UI, upload before/after screenshots before you tag. A reviewer who opens a UI-change artifact and sees no images is going to close the tab.

## Common mistakes

| Mistake | Fix |
|---|---|
| Tagging before uploading all files | Upload → visually verify in browser → then tag. Tags are immutable. |
| Artifact description left empty | Always set one — it's the first thing reviewers see. |
| Dumping everything into one `SUMMARY.md` | Split by concern. One file per "aspect" (decisions, testing, UI, data-model). |
| Referencing local paths in content | Readers can't follow them. Paste the relevant lines or move the whole file into the artifact. |
| Forgetting to make it visible | Flip visibility to public, or add the reviewer as a member — otherwise they get 404. |
| No visuals on UI work | Screenshot before + after, upload as images, reference from markdown. |
| Vague summary ("updated auth") | Be specific — "reordered JWT validation to check expiry before issuer, fixing stale-session bug on custom domains." |
| Assuming reviewers read everything | Write for glance → scan → dive. Top layer must work on its own. |

## Tips

- For an agent operating autonomously, the minimum publish loop is: create artifact → write files → set description → tag → make public → return the URL. One artifact, one human ready to review.
- Use `getProjectStatus` anytime to see what's drifted between WIP and your most recent tag.
