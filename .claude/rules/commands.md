# Slash commands

Commands must be invoked explicitly; they do not run automatically.

## Architecture

Commands live in `.claude/commands/`. Most commands execute directly. Commands that don't require conversation context may delegate to subagents.

**Subagent limitation:** Subagents start with a clear context — they cannot access the parent conversation. Only delegate to subagents when the command reads from files or APIs rather than conversation history.

**Subagent pattern:**
- Command file (`.claude/commands/{name}.md`) — invocation instructions, spawns subagent
- Agent file (`.claude/agents/{name}.md`) — task instructions for the subagent

## Plan workflow

**/plan-create** — creates a GitHub issue with the plan as description (uses subagent)

**/plan-prompt** — saves a revised prompt as a comment to the issue

**/plan-resume** — loads plan and handoffs from an issue to continue work

**/plan-validate** — validates a plan for clarity, accuracy and completeness before implementation

**/plan-update** — updates a GitHub issue with revised plan content from the conversation

**/plan-handoff** — posts a technical handoff comment synthesising implementation from the conversation

## Pull requests

**/pr-create** — creates a GitHub pull request from current branch commits

**/pr-response** — responds to PR review comments based on work done in the conversation

**/pr-fetch-all-comments** — fetches all PR comments including inline review comments

**/pr-fetch-only-comments** — fetches review and issue comments only (no inline)
