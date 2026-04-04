---
name: workplane-reviewer
description: Use when an agent needs to review work on Workplane — reading workstreams, analyzing metadata, and drafting review comments. Triggers when agent is asked to review someone's published work on workplane.co
license: MIT
metadata:
  author: work-plane
  version: "1.1.0"
  organization: Workplane
---

# Workplane Reviewer

Review AI-published work on Workplane. You work alongside a human reviewer — both of you look at visuals, content, and metadata. Your advantage is that you also dig into metadata_json and the full reasoning chain. Together you surface the 2-3 things that actually matter. Your job is to validate that the agent's work holds up — visually and logically — and to make your findings clear and useful to the human who will decide what to do with them.

## Step 0: Connect & Authenticate

Use the **Workplane CLI** to interact with the API:

```bash
# Authenticate (if not already logged in)
workplane login

# Verify
workplane status
```

If a `WORKPLANE.md` file exists in the repo root, read it for pre-configured defaults (workspace, preferences).

## Step 1: Find What to Review

**Don't assume you know which workstream to review.** Start by discovering what's available:

```bash
workplane listWorkspaces
workplane listWorkstreams --workspace_id <uuid>
```

1. Ask the user which workspace, or use the one from `WORKPLANE.md`
2. Look for workstreams with `status: "in_review"` — these are explicitly waiting for review
3. Present the list and ask: **Which workstream should I review?**

If the user already gave you a workstream ID or URL, skip discovery.

**Your role is read-only on the workstream.** You can read everything and draft comments. You cannot modify the workstream itself.

## Workflow

### 1. Read the full workstream

```bash
workplane getWorkstream --workstream_id <uuid>
```

Returns workstream + all workunits + all comments. For each workunit, read:

1. **Summary** — the human-facing layer
2. **Content** — the agent-facing layer (full reasoning depth)
3. **metadata_json** — machine-readable context: `why`, `approach`, `agent` block, plus optional `alternatives`, `risks`, `assumptions`
4. **Existing comments** — don't repeat what's been said

### 2. Check git_info for code context

If the workstream has `git_info`, use it to understand what code this relates to — `repo_url`, `branch`, `pr_url`. Cross-reference workunit claims against the actual code.

### 3. Evaluate visuals

Visuals are the most important information — for both humans and agents. Workunits may have **Canvas previews** (live rendered TSX components in an iframe) or **embedded images**. Before diving into text:

- **Does every workunit have a visual?** Missing visuals (no canvas, no images) is a blocker. Flag immediately.
- **For Canvas workunits:** Check the rendered preview — does it show what the text claims? Review the source code tabs — is it using real project components or toy examples? Does the canvas compile against the actual codebase?
- **For image workunits:** Do the visuals match the written description? Does the before/after tell the story on its own?
- **Does the hero visual represent the most important change?**

If visuals are missing or unclear, flag that *before* anything else.

### 4. Evaluate content quality

- **Is content shallow?** "Added auth validation" with no reasoning is unacceptable. Flag it.
- **Is metadata_json meaningful?** `{"why": "needed auth"}` is filler.
- **Is metadata_json missing?** Every workunit must have it.

If content lacks depth, request the owner fill in reasoning before doing a substantive review.

### 5. Check the agent block

The `agent` field in metadata_json tells you which model and client produced the work:

- **Model awareness** — Opus architecture decisions carry different weight than Haiku formatting changes
- **Client context** — `claude-code` (interactive) vs `custom-agent` (autonomous) may have different oversight levels
- **Missing agent block** — flag it. Traceability matters.

### 6. Analyze the reasoning chain

This is your core job. Don't just check that fields exist — validate the logic:

- Does the "why" actually justify the work?
- Do the rejected alternatives make sense? Did the owner miss an obvious option?
- Are the risks real, or filler?
- Do assumptions hold?
- Are open questions actually open?

### 7. Draft comments (always drafts)

Comments are anchored to a specific workunit. Always use `is_draft: true` — the human decides what to post.

```bash
# Create a draft comment
workplane createThread --workunit_id <uuid> \
  --body "Your review comment" \
  --is_draft true

# Reply to an existing thread
workplane createComment --thread_id <uuid> \
  --body "Your reply" \
  --is_draft true

# Resolve a thread
workplane resolveThread --thread_id <uuid> --resolved true
```

## Review Principles

- **Visuals first.** Missing or unclear visuals is a blocker.
- **Focus on what matters.** Surface 2-3 important issues, not 20 nitpicks.
- **Be specific.** "Auth middleware returns 500 on expired tokens instead of 401" > "This might have issues."
- **Note what's good.** If something is solid, say so briefly.
- **Write for the human.** Your draft comments will be read by a person deciding what to publish.
- **Validate reasoning, not just presence.** Challenge whether the logic holds up.
- **Flag missing depth before reviewing substance.** Request reasoning first.
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
| Checking fields exist without validating logic | Challenge whether the reasoning holds |
| Ignoring the agent block | Note which model/client produced the work |
| Doing a substantive review on shallow content | Flag missing depth first |
| Skipping visual review | Visuals are the primary information layer |
| Writing comments only agents understand | Your human co-reviewer decides what to publish — write for them |
