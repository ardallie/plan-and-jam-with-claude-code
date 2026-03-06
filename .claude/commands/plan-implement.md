# Implement a plan from a GitHub issue

## Usage

- `/plan-implement` — uses the issue number from conversation context
- `/plan-implement <issue>` — implements the plan from the specified issue (e.g., `85`)

## Context

Run this after the plan has been created (`/plan-create`) and optionally validated (`/plan-validate`). The issue description contains the plan; comments may contain handoffs from prior sessions.

## Task

1. Load the plan by invoking `/plan-read` via the Skill tool (use `skill: "plan-read"` and pass the issue number as `args` if provided).
2. Parse the plan into discrete, ordered work items.
3. Implement each work item sequentially:
   - Make the changes.
   - If the repository has a build or test step, verify the changes compile and pass relevant tests.
   - Report progress before moving to the next item.
4. Summarise what was implemented and note any items skipped or deferred.

## Requirements

- Follow the plan as written. Do not make unrelated changes.
- Do not commit to Git — leave changes for user review.
- If an item is ambiguous or appears incorrect, use the `AskUserQuestion` tool to clarify before proceeding.
- If a work item fails (does not compile, breaks tests), report the failure and ask how to proceed rather than guessing a fix.

## Error handling

- If the issue number cannot be determined, report this and stop.
- If the issue does not exist or is inaccessible, report the error.
