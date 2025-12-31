# Load context from a GitHub issue

## Usage

- `/plan-resume` - Uses the issue number from conversation context
- `/plan-resume <issue>` - Loads context from the specified issue (e.g., `85`)

## Context

Use this to continue work started in a previous session. The issue contains the plan (description) and any handoff comments documenting progress. After completing work, use `/plan-handoff` to document the session.

## Task

1. Identify the issue number from the argument or search the conversation for a GitHub issue URL or number. If not found, report this and stop.
2. Fetch all data in a single call:
   ```bash
   gh issue view <issue> --json title,body,state,createdAt,comments
   ```
3. Present the data in this order:
   - Issue title and state
   - Issue body (the plan)
   - Comments in chronological order (revised prompt, handoffs, discussion)
4. Summarise the current state and ask how to proceed

## Requirements

- This is read-only — do not modify the issue
- For each comment: include author, timestamp, and full body

## Error handling

- If issue number cannot be determined, report this clearly and stop
- If issue does not exist, report the error
- If there are permission issues, report them
