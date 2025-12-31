# Synthesise a revised prompt from the conversation

## Usage

- `/plan-prompt` - Displays the revised prompt in the conversation
- `/plan-prompt <issue>` - Posts the revised prompt as a comment to the specified issue (e.g., `85`)

## Context

Use this at the end of a planning session to capture a refined, reusable prompt. The conversation often clarifies requirements, resolves ambiguities, and surfaces concrete examples — this command distils that into a prompt suitable for future use or similar tasks.

When an issue number is provided, the prompt is posted as the first comment on the issue. This preserves the original requirements alongside the plan for future reference.

## Task

### Print the original prompt

Print the user's original prompt verbatim. This must happen first to anchor the rephrasing.

### Synthesise a revised prompt

**Include:**
- Clarifications received during the conversation
- Data structures and schemas (show concrete examples, not placeholders)
- Files to modify and validation steps

**Improve:**
- Logical order and flow
- Clarity and conciseness

**Remove:**
- Rejected alternatives and their analysis
- Redundant examples that convey the same information
- Exploratory questions already answered

### Print the revised prompt

Present the revised prompt in a copyable format.

### Post to issue (if issue number provided)

Post the revised prompt as a comment using `gh issue comment <issue> --body "..."` and return the comment URL to confirm.

## Requirements

- Preserve technical accuracy
- Aim for clarity over brevity
- Present the revised prompt in a copyable format
- When posting to an issue, use a clear header (e.g., "## Revised Prompt")

## Error handling

- If there is no discernible original prompt in the conversation, report this and stop
- If issue number cannot be determined, report this clearly and stop
- If issue does not exist, report the error
- If there are permission issues, report them
