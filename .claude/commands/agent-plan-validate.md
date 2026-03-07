# Run an agent team plan validation

## Usage

- `/agent-plan-validate` — uses issue number from conversation context
- `/agent-plan-validate <issue>` — validates plan from the specified issue number
- `/agent-plan-validate <file>` — validates plan from a local file
- Text after the issue/file argument is passed to all validators as additional instructions

## Context

Use after plan creation and before implementation. Spawns a validation team to review the plan from multiple angles, verify assumptions against the codebase, and surface issues. The output is a structured validation report. For lighter single-agent validation, use `/plan-validate`.

## Task

Eight phases executed in order.

### Phase 1 — Load plan

Parse the arguments:

- **File paths provided** — test each whitespace-delimited token as a file path in order. The first token that does not resolve to a readable file ends the file list — that token and everything after it is passed to all validators as additional instructions. Read each valid file and concatenate their contents as the plan text.
- **Numeric token** — if the first token is not a valid file path but is numeric, treat it as a GitHub issue number. Fetch via:

```bash
gh issue view <number> --json body,title --jq '.title + "\n\n" + .body'
```

Everything after the issue number is passed to all validators as additional instructions.

- **No arguments** — look for an issue number in the conversation context (e.g., from a prior `/plan-read`). If found, fetch it using the command above. If not found, report this and stop.

If a file path resolves but is not readable, report the error and stop. If the fetched plan text is empty, report this and stop.

Store the plan text for distribution to agents.

### Phase 2 — Explore codebase

Perform targeted exploration driven by the plan content. Build a context package:

- Repository overview (top-level listing, key config files)
- Relevant files mentioned or implied by the plan (read in full)
- Related patterns (existing implementations similar to what the plan describes)
- Dependency map (modules adjacent to or affected by the proposed changes)

Read all files explicitly referenced in the plan — these have no cap. Cap additional exploratory reads (files discovered but not mentioned in the plan) at 40; if the cap is reached, note this in the Context files section and list the areas skipped. Prioritise entry points and interfaces.

Record which files were read — the report includes them in the Context files section as a single numbered list.

### Phase 3 — Create validation team

Create the team via `TeamCreate` with a unique name by appending a short random suffix (e.g., `plan-validate-a3f9`).

Before spawning validators, extract a verification checklist from the plan: every modified type, interface, or function signature, and their consumers identified during Phase 2 exploration.

Spawn three validators (two specialists, one sceptic) via the Task tool (`subagent_type: "general-purpose"`, `model: "sonnet"`), passing the team name. Each validator receives: the plan text (verbatim), the context package, the verification checklist, their role description, any additional instructions from the user, and the validator instructions below.

Two validators receive specialisations chosen by the system based on the plan content. The main agent assigns two complementary roles that together cover the validation criteria. Example specialisations: architecture reviewer, dependency analyst, implementation feasibility assessor, API design reviewer, test strategy assessor, security reviewer, consumer impact analyst, file-level implementation reviewer.

The third is the **sceptic** — it challenges the plan's premise and assumptions, proposes simpler alternatives, identifies unstated assumptions, checks whether the problem is correctly framed, and flags scope risks.

Each validator must:

1. Explore the codebase independently to verify claims and discover context beyond the parent's package
2. For each file the plan modifies, read the current implementation in full. Verify that existing functions, predicates, and control flow remain correct under the proposed changes. Flag logic the plan does not mention that would break or silently produce wrong results.
3. Report findings grouped by these criteria:
   - **Clarity** — Are steps unambiguous? Could another agent implement without guessing?
   - **Accuracy** — Do referenced files, functions, and patterns exist? Verify with codebase exploration.
   - **Completeness** — Are edge cases addressed? Dependencies identified? Scope well-bounded?
   - **Feasibility** — Can this be implemented with current architecture? Hidden complexities?
4. Prefix findings that require user input with `[Question]` within their category — these drive the interview phase
5. Reference specific files and line numbers
6. Distinguish facts (verified in codebase) from assessments (analytical judgement)
7. Note areas reviewed and found correct, stating what was checked and why it needs no changes
8. Report which verification checklist items were covered, so the consolidation phase can identify gaps
9. List any files read beyond the context package, so they can be merged into the report's context file list
10. Do not edit, create, or delete files
11. Send findings to the team lead via `SendMessage`

### Phase 4 — Collect validations

Wait for all three validators to respond via the team messaging system. If a validator fails or does not respond within the platform's default task timeout, proceed with available results and note the missing validator in the report.

### Phase 5 — Generate report

Consolidate all validator findings into a single report. Apply these rules:

- Deduplicate: if multiple validators flagged the same issue, merge into one finding. When merging, use the most critical assessment.
- Cross-reference validator coverage against the verification checklist. List uncovered items in the "Not verified" subsection.
- No per-validator attribution. The developer does not need to know which agent found what.
- Omit sections that have no findings, including "Approved without changes".
- No summary section, no recommendation line.

Output the report between `---` separators:

```
---

# Plan validation report

## Validators

1. [name] — [specialisation]
2. [name] — [specialisation]
3. [name] — Sceptic

## Findings

### Clarity [omit if empty]

[consolidated findings — each with description and file:line references]

### Accuracy [omit if empty]

[consolidated findings — each with what was claimed, what was found, and file:line evidence]

### Completeness [omit if empty]

[consolidated findings — each with description and file:line references]

### Feasibility [omit if empty]

[consolidated findings — each with description and file:line references]

### Approved without changes [omit if empty]

[areas reviewed and found correct — aggregated across all validators]

### Not verified [omit if empty]

[checklist items — modified interfaces or consumers — that no validator covered]

## Clarifications [omit if no interview]

[user responses from interview]

## Context files

[Single deduplicated numbered list of all files read during validation — by the
parent agent in Phase 2 and by validators. No grouping by source, no validator
attribution. Omit files listed in the plan but not found or not readable —
note these separately.]

# Next steps for the planning agent

1. Enter plan mode, address the findings, and update the plan
2. Once approved, run `/plan-update` to push the revised plan to the GitHub issue

Do not proceed with implementation. Do not ask the user whether to proceed — just run `/plan-update`.

---
```

### Phase 6 — Save report

Write the report to `.claude/reports/plan-validate-{date}-{id}.md`, where `{date}` is the current date in `YYYY-MM-DD` format and `{id}` is the same random suffix used for the team name (e.g., `plan-validate-2026-03-07-a3f9.md`).
Create the `.claude/reports/` directory if it does not exist.

### Phase 7 — Clean up

Send `shutdown_request` to all validators. Wait briefly for acknowledgements, then proceed to `TeamDelete` — do not block indefinitely on unresponsive validators.

### Phase 8 — Interview

If the report contains no `[Question]`-prefixed findings, skip this phase. The command ends after Phase 7.

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

Overwrite the same file path used in Phase 6. Output the updated report in full. This is the final output of the command.

## Constraints

- Do not ask follow-up questions after the report
- The report (or updated report after interview) is the final output — nothing follows
- Do not execute the next steps in the report — they are for the planning agent

## Error handling

- If no issue number can be determined and no file is provided, report this clearly and stop
- If the issue does not exist, report the error and stop
- If a file path resolves but is not readable, report the error and stop
- If the plan text is empty, report this and stop
- If `gh` or `git` commands fail, report the error and stop
- If a validator fails or times out, note the missing validator in the report and proceed with available results
- If there are permission issues, report them and stop
