# Validate a plan before implementation

## Usage

- `/plan-validate` - Uses the issue number from conversation context
- `/plan-validate <issue>` - Validates the plan from the specified issue (e.g., `85`)

## Context

Use this in session 2. A fresh session provides perspective the planning session lacks — assumptions become visible, gaps surface, and ambiguities clarify. This step catches issues before code is written.

## Task

Execute four phases in order.

### Phase 1 — Load the plan

If the plan is already loaded in the conversation (via a prior `/plan-read`), skip this step. Otherwise, invoke `/plan-read` via the Skill tool to fetch the issue:

Use the Skill tool with `skill: "plan-read"` and pass the issue number as `args`.

This keeps issue-fetching logic in one place.

### Phase 2 — Validate

Review the plan against these criteria:

- **Clarity** — Are the steps unambiguous? Could another agent implement this without guessing?
- **Accuracy** — Do referenced files, functions, and patterns actually exist? Verify with codebase exploration.
- **Completeness** — Are edge cases addressed? Are dependencies identified? Is the scope well-bounded?
- **Feasibility** — Can this be implemented with the current architecture? Are there hidden complexities?

Explore the codebase to verify assumptions. Check that referenced files and patterns exist as described. Identify related code that might be affected.

### Phase 3 — Interview

If findings require user input, ask focused questions using AskUserQuestion. Wait for responses. Incorporate answers into the report — inline with findings or as a separate Clarifications section, at your discretion.

If no clarifications are needed, skip this phase.

### Phase 4 — Report

Output the structured report between `---` separators. This is the last text you output — nothing follows the closing separator.

```
---

# Plan validation report

## Instruction

Enter plan mode and address the findings below. Update the plan to
resolve each item. Once done, exit plan mode and run `/plan-update` to
push the revised plan to the GitHub issue.

Do not proceed with implementation until the plan is updated.

If the report identifies no issues requiring plan changes, you may skip
the update and proceed directly with implementation.

## Findings

[Validation results organised by category]

## Clarifications

[User responses from interview, if any. Omit section if none needed.]

---
```

After outputting the report, copy the full report (between and including the `---` separators) to the system clipboard. Check the platform using `uname -s` and use the appropriate command silently via Bash:
- **Windows/MINGW/MSYS**: `clip`
- **Darwin**: `pbcopy`
- **Linux**: `xclip -selection clipboard`, falling back to `xsel -b` if `xclip` is unavailable

## Constraints

- Do not ask follow-up questions after the report ("Should we proceed?", "What would you like to do next?")
- The report is the absolute last text output
- The clipboard command runs silently — no output after the report

## Error handling

- If issue number cannot be determined, report this clearly and stop
- If issue does not exist, report the error
- If there are permission issues, report them
