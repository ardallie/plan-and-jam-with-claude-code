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

# Instructions

1. Enter plan mode and address the findings below
2. Resolve each item and update the plan
3. Exit plan mode
4. Run `/plan-update` to push the revised plan to the GitHub issue

Do not proceed with implementation yet.

# Plan validation report

## Findings

[Validation results organised by category]

## Clarifications

[User responses from interview, if any. Omit section if none needed.]

---
```

After outputting the report, copy everything between and including the `---` separators to the system clipboard. 

Detect the platform and run the appropriate command silently via Bash:

```bash
OS=$(uname -s)
case "$OS" in
  MINGW*|MSYS*|CYGWIN*) cat <<'EOF' | clip ;;
  Darwin)                cat <<'EOF' | pbcopy ;;
  Linux)                 cat <<'EOF' | xclip -selection clipboard 2>/dev/null || cat <<'EOF' | xsel -b ;;
esac
<paste the report text here>
EOF
```

Replace `<paste the report text here>` with the full report text. The heredoc preserves formatting and special characters.

## Constraints

- Do not ask follow-up questions after the report ("Should we proceed?", "What would you like to do next?")
- The report is the absolute last text output
- The clipboard command runs silently — no output after the report

## Error handling

- If issue number cannot be determined, report this clearly and stop
- If issue does not exist, report the error
- If there are permission issues, report them
