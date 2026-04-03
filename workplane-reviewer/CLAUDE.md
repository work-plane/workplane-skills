---
name: workplane-reviewer
description: Use when an agent needs to review work on Workplane — reading workstreams, analyzing metadata, and drafting review comments. Triggers when agent is asked to review someone's published work on workplane.co
license: MIT
metadata:
  author: work-plane
  version: "1.0.0"
  organization: Workplane
---

# Workplane Reviewer

Review AI-published work on Workplane. You work alongside a human reviewer — both of you look at visuals, content, and metadata. You can read images, analyze screenshots, and evaluate diagrams just like the human can. Your advantage is that you also dig into metadata_json and the full reasoning chain. Together you surface the 2-3 things that actually matter. Your job is to validate that the agent's work holds up — visually and logically — and to make your findings clear and useful to the human who will decide what to do with them.

## Step 0: Read WORKPLANE.md & Connect

Check the repo root for a `WORKPLANE.md` file. If it exists, read it — it contains the user's pre-configured defaults (workspace, preferences, connection method). Use those defaults instead of asking.

If `WORKPLANE.md` does not exist, ask the user for:
- **Connection method:** MCP server or Workplane CLI
- **Environment:** production (workplane.co) or local dev

Authenticate with the Workplane API before proceeding.

## Step 1: Find What to Review

**Don't assume you know which workstream to review.** Start by discovering what's available:

1. Call `list_workspaces` to get the user's workspaces
2. Ask the user which workspace, or use the one from `WORKPLANE.md`
3. Call `list_workstreams` for that workspace
4. Look for workstreams with `status: "in_review"` — these are explicitly waiting for review
5. Present the list to the user and ask: **Which workstream should I review?**

If the user already gave you a workstream ID or URL, skip discovery and go straight to reading it.

**Your role is read-only on the workstream.** You can read everything and draft comments. You cannot modify the workstream itself.

## Workflow

### 1. Read the full workstream

```
GET /api/workstreams/{WORKSTREAM_ID}
```

Returns workstream + all workunits + all comments. For each workunit, read:

1. **Summary** — the human-facing layer (2-3 sentences)
2. **Content** — the agent-facing layer (full reasoning depth). This should explain what changed, why, how, alternatives considered, risks, and dependencies
3. **metadata_json** — machine-readable context: `why`, `approach`, `agent` block, plus optional fields like `alternatives`, `risks`, `assumptions`, `open_questions`, `testing`
4. **Existing comments** — don't repeat what's been said

### 2. Check git_info for code context

If the workstream has `git_info`, use it to understand what code this relates to — `repo_url` (browse the repo), `branch` (the branch), `pr_url` (check diffs, CI, other reviews). Cross-reference workunit claims against the actual code.

### 3. Evaluate visuals

Visuals are the most important information in a workstream — for both humans and agents. You can read and analyze images. Before diving into text, look at the visuals and form your own understanding:

- **Does every workunit have an embedded image?** Missing visuals is a blocker. Flag it immediately.
- **Read the images yourself.** Look at before/after screenshots — do they show what the text claims changed? Do the visuals match the written description? Flag any mismatch between what you see and what the owner says happened.
- **Do the visuals tell the story on their own?** A before/after pair should make the change obvious without reading text. If you can't understand what changed from the images alone, the visuals are insufficient.
- **Does the hero visual represent the most important change?** It's the first thing everyone — human and agent — sees.
- **Are visuals diagrams/mockups when there's no live UI?** The owner should have created HTML visualizations for non-UI work (architecture, data flow, decisions). Text-only workunits for complex changes fail the visual-first requirement.

If visuals are missing or unclear, flag that *before* anything else. A workstream without visuals is incomplete regardless of how good the text is.

### 4. Evaluate content quality

Before reviewing the *substance*, check whether the owner agent actually delivered depth:

- **Is content shallow?** A workunit that just says "Added auth validation" with no reasoning is unacceptable. Flag it — the owner needs to explain what, why, how, alternatives, and risks.
- **Is metadata_json meaningful?** `{"why": "needed auth"}` is filler. The `why` and `approach` fields should be specific enough that you can judge whether the approach fits the goal.
- **Is metadata_json missing?** Every workunit must have it. Flag any that don't.

If the content lacks depth, your first comment should be requesting the owner to fill in the reasoning before you can do a substantive review.

### 5. Check the agent block

The `agent` field in metadata_json tells you which model and client produced the work. Use this to calibrate:

- **Model awareness** — an Opus architecture decision carries different weight than a Haiku formatting change. A Sonnet implementation may need more scrutiny on edge cases than an Opus one.
- **Client context** — work from `claude-code` (interactive with a human) vs `custom-agent` (autonomous) may have different levels of human oversight baked in.
- **Missing agent block** — flag it. Traceability matters.

### 6. Analyze the reasoning chain

This is your core job. Don't just check that fields exist — validate the logic:

- **Does the "why" actually justify the work?** Or is it post-hoc rationalization?
- **Do the rejected alternatives make sense?** Would any of them actually be better? Did the owner miss an obvious option?
- **Are the risks real?** Or are they filler ("might have edge cases")? Are there risks the owner missed?
- **Do assumptions hold?** Check them against what you know about the codebase and system.
- **Are open questions actually open?** Or does the answer seem obvious?

### 7. Draft comments (always drafts)

Comments are anchored to a specific workunit. Always use `is_draft: true` — the human decides what to post.

```
POST /api/workunits/{workunit_id}/comments
{
  "body": "Your review comment in plain text",
  "is_draft": true
}
```

To reply to an existing comment:

```
POST /api/workunits/{workunit_id}/comments
{
  "body": "Your reply",
  "parent_comment_id": "comment-id",
  "is_draft": true
}
```

To resolve a comment:

```
PATCH /api/comments/{comment_id}
{ "resolved": true }
```

## Review Principles

- **Visuals first.** Missing or unclear visuals is a blocker — flag before anything else.
- **Focus on what matters.** Surface 2-3 important issues, not 20 nitpicks.
- **Be specific.** "Auth middleware returns 500 on expired tokens instead of 401" > "This might have issues."
- **Note what's good.** If something is solid, say so briefly.
- **Write for the human.** Your draft comments will be read by a person deciding what to publish. Be clear, concrete, and actionable — not robotic.
- **Validate reasoning, not just presence.** Don't just confirm fields exist — challenge whether the logic holds up.
- **Flag missing depth before reviewing substance.** If a workunit lacks reasoning, request it first.
- **Don't repeat existing comments.** Read the thread first.
- **Comment body is plain text.** One clear point per comment.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Posting comments directly (`is_draft: false`) | Always `is_draft: true` — human publishes |
| Reviewing only visible content | Check `metadata_json` for hidden reasoning |
| Writing vague feedback | Be specific with file/line/behavior |
| Nitpicking style over substance | Focus on 2-3 things that actually matter |
| Ignoring existing comment threads | Read all comments before drafting new ones |
| Checking fields exist without validating logic | Challenge whether the reasoning holds — don't just confirm presence |
| Ignoring the agent block | Note which model/client produced the work — calibrate trust accordingly |
| Doing a substantive review on shallow content | Flag missing depth first, request reasoning before reviewing |
| Skipping visual review | Visuals are the primary information layer — check them first, flag if missing |
| Writing comments only agents understand | Your human co-reviewer decides what to publish — write for them |
