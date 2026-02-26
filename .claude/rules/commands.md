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

**/plan-read** — loads plan and handoffs from an issue to continue work

**/plan-validate** — loads the plan (invokes `/plan-read`), validates against the codebase, interviews the engineer if needed, and outputs a structured report for the planning agent

**/plan-update** — updates a GitHub issue with revised plan content from the conversation

**/plan-handoff** — posts a technical handoff comment synthesising implementation from the conversation

## Pre-plan analysis

**/team-pre-planner** — spawns an analysis team (three system-assigned analysts plus a sceptic) to explore the codebase and analyse an intention before plan creation

## Code review

**/agent-code-review** — spawns a review team (three system-assigned reviewers plus a sceptic) to analyse changes before PR creation

## Pull requests

**/pr-create** — creates a GitHub pull request from current branch commits

**/pr-response** — responds to PR review comments based on work done in the conversation
