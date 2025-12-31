# Update a GitHub issue with revised plan

## Usage

- `/plan-update` - Uses the issue number from conversation context
- `/plan-update <issue>` - Updates the specified issue (e.g., `85`)

## Context

Use this after `/plan-validate` when validation reveals significant gaps or inaccuracies that require plan revision. The GitHub issue remains the single source of truth — this command pushes conversation refinements back to the issue.

## Task

1. Identify the issue number from the argument or search the conversation for a GitHub issue URL or number. If not found, report this and stop.
2. Fetch the current issue to get the existing title and body:
   ```bash
   gh issue view <issue> --json title,body
   ```
3. Synthesise the revised plan from the conversation:
   - Incorporate feedback from validation
   - Address identified gaps and inaccuracies
   - Preserve the original structure where unchanged
4. Present the revised plan to the user for approval before updating
5. Once approved, update the issue:
   ```bash
   gh issue edit <issue> --body "$(cat <<'EOF'
   ...revised plan content...
   EOF
   )"
   ```
6. Confirm the update with the issue URL

## Requirements

- Requires user approval before updating — always show the diff or full revised content first
- Preserve formatting and structure from the original plan
- Only modify sections that need revision based on the conversation
- Do not change the issue title unless explicitly discussed

## Error handling

- If issue number cannot be determined, report this clearly and stop
- If no revisions were discussed in the conversation, report this and stop
- If issue does not exist, report the error
- If there are permission issues, report them
