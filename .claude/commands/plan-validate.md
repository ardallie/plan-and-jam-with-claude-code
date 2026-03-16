# Validate a plan before implementation

## Usage

- `/plan-validate` — uses issue number from conversation context
- `/plan-validate <issue>` — validates the plan from the specified issue number (e.g., `85`)
- `/plan-validate <file1> <file2> ...` — validates the plan from local files
- Text after the last valid file path or issue number is passed as additional instructions

## Context

Use after plan creation and before implementation. 
Reviews the plan against the codebase to verify assumptions and surface issues that are harder to spot in the planning session.
Best run in a fresh session — the planning context is not loaded, so gaps and errors become visible. 
The output is a structured validation report. 

This is a single-agent version of `/agent-plan-validate`.

## Task

Five phases executed in order.

### Phase 1 — Load the plan

Parse the arguments:

- **File paths provided** — test each whitespace-delimited token as a file path in order. The first token that does not resolve to a readable file ends the file list — that token and everything after it is passed as additional instructions. Read each valid file and concatenate their contents as the plan text.
- **Numeric token** — if the first token is not a valid file path but is numeric, treat it as a GitHub issue number. Fetch via:

```bash
gh issue view <number> --json title,body,state,createdAt,comments
```

Parse JSON output: present title, body, and comments chronologically with author and timestamp. Everything after the issue number is passed as additional instructions.

- **No arguments** — if the plan is already in the conversation (from a prior `/plan-read`), use it. Otherwise look for an issue number in conversation context and fetch it using the command above. If not found, report this and stop.

If a file path resolves but is not readable, report the error and stop. If the plan text is empty, report this and stop.

### Phase 2 — Validate

Review the plan against these criteria:

- **Clarity** — Are the steps unambiguous? Could another agent implement this without guessing?
- **Accuracy** — Do referenced files, functions, and patterns actually exist? Verify with codebase exploration.
- **Completeness** — Are edge cases addressed? Are dependencies identified? Is the scope well-bounded?
- **Feasibility** — Can this be implemented with the current architecture? Are there hidden complexities?

Explore the codebase to verify assumptions. Check that referenced files and patterns exist as described. Identify related code that might be affected.

Prefix findings that require user input with `[Question]`. These drive the interview phase.

### Phase 3 — Generate report

Assemble the report content internally. The assembled report text must not appear in conversation until the save phase outputs it.

```
# Plan validation report

## Instructions

1. Read this report file in full
2. Enter plan mode, address the findings, and update the plan
3. Once approved, run `/plan-update` to push the revised plan to the GitHub issue

Do not proceed with implementation until the user explicitly approves.

## Findings

### Clarity [omit if empty]

[findings — each with description and file:line references]

### Accuracy [omit if empty]

[findings — each with what was claimed, what was found, and file:line evidence]

### Completeness [omit if empty]

[findings — each with description and file:line references]

### Feasibility [omit if empty]

[findings — each with description and file:line references]

### Approved without changes [omit if empty]

[areas reviewed and found correct — stating what was checked and why it needs no changes]

## Clarifications [omit if no interview]

[User responses from interview]
```

### Phase 4 — Save and output report

Generate an 8-digit hex suffix (`openssl rand -hex 4 2>/dev/null || date +%s | sha256sum | head -c 8`). Write the report to
`.claude/reports/{yyyyMMdd}-{HHmm}-plan-validate-{suffix}.md`, where `{yyyyMMdd}` and
`{HHmm}` are local machine time (`date +%Y%m%d` and `date +%H%M`).
Create the `.claude/reports/` directory if it does not exist.

Output the report in full.

If the report contains `[Question]`-prefixed findings, proceed to the interview phase.
Otherwise the command ends here.

### Phase 5 — Interview

This phase collects user answers and overwrites the saved report file with updated content. The file save is mandatory — without it, the report lacks interview answers.

**Run the interview tool:**

Use the `AskUserQuestion` tool to present questions interactively. Group questions by priority — blocking questions first, then deferrable. For each question, provide 2-4 answer options that help the user make an informed choice rather than composing an answer from scratch. Draw options from codebase evidence, trade-offs, or reasonable alternatives as appropriate.

If there are more questions than the tool supports per call, batch them across multiple calls — blocking questions in the first batch.

**Collect answers:**

The tool returns the user's selections. The user may also provide free-text via the built-in "Other" option. If the user declines to answer a question, leave it unresolved. If all questions are unresolved, end the interview.

**Update the report** — for each answered question:

- **Findings**: prepend `[Resolved]` to the description and append the user's answer on a new line prefixed with `Answer:`. Do not delete the finding — it serves as audit trail.
- **Clarifications section**: add the answered question and the user's response. If the section did not exist, create it.
- Skipped questions: no changes.

**Save updated report:**

Overwrite the same file path used in the Save report phase. Output the updated report in full.

## Constraints

- Do not execute the report instructions — they are for the planning agent in a subsequent session
- The saved report is the deliverable; the command ends after the final save
- After interview, the saved report file must be overwritten with updated content

## Error handling

- If no issue number can be determined and no file is provided, report this clearly and stop
- If the issue does not exist, report the error and stop
- If a file path resolves but is not readable, report the error and stop
- If the plan text is empty, report this and stop
- If `gh` or `git` commands fail, report the error and stop
- If there are permission issues, report them and stop
