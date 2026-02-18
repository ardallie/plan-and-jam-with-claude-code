# Run a pre-plan analysis

## Usage

- `/team-pre-planner` — uses the most recent actionable user message as the brief
- `/team-pre-planner <file1> <file2> ...` — reads files as the brief
- Text after the last valid file path is passed to all analysts as additional instructions

## Context

Use this before entering plan mode. It spawns an analysis team to explore the codebase from multiple angles, surface risks, correct assumptions, and identify opportunities. The output is a two-part report: an enhanced brief followed by a consolidated findings list.

## Task

Seven phases executed in order.

### Phase 1 — Extract brief

Parse the arguments:

- **File paths provided** — test each whitespace-delimited token as a file path in order. The first token that does not resolve to a readable file ends the file list — that token and everything after it is passed to all analysts as additional instructions. Read each valid file and concatenate their contents as the brief.
- **No arguments** — identify the most recent user message in conversation context that describes an intention, suggestion, technical query, or implementation plan. Quote it verbatim as the brief.

If no brief is found (no arguments and no actionable message in context), report this and stop. If a file path resolves but is not readable, report the error and stop.

### Phase 2 — Explore codebase

Perform targeted exploration driven by the brief. Build a context package:

- Repository overview (top-level listing, key config files)
- Relevant files mentioned or implied by the brief (read in full)
- Related patterns (existing implementations similar to what the brief describes)
- Dependency map (modules adjacent to or affected by the proposed change)

Read all files explicitly referenced in the brief — reference lists, documentation lists, file paths mentioned inline, slash commands, and context files in the target repository. These have no cap. Cap additional exploratory reads (files discovered by the parent but not mentioned in the brief) at 40; if the cap is reached, note this in the Context consumed section and list the areas skipped. Prioritise entry points and interfaces.

Record which files were read — the report includes this list.

### Phase 3 — Create analysis team

Create the team via `TeamCreate` with a unique name by appending a short random suffix (e.g., `planner-a3f9`). Spawn four analysts via the Task tool (`subagent_type: "general-purpose"`, `model: "opus"`), passing the team name. Analysts use `opus` rather than `sonnet` because pre-plan analysis involves open-ended codebase reasoning and hypothesis evaluation — tasks that benefit from a more capable model than code review.

Each analyst receives: the brief (verbatim), the context package, their specialisation, any additional instructions from the user, and the analyst instructions below.

Three analysts receive specialisations chosen by the system based on the brief. The fourth is the **sceptic** — it challenges the premise, proposes simpler alternatives, identifies unstated assumptions, checks whether the problem is correctly framed, and flags scope risks.

Each analyst must:

1. Explore the codebase independently to verify claims and discover context beyond the parent's package
2. Report findings using exactly these categories: Insight, Correction, Risk, Opportunity, Question — do not use other categories such as Clarity, Accuracy, Completeness, or Feasibility
3. Resolve ambiguities using codebase evidence where possible — only escalate to Question when the codebase cannot answer it
4. Reference specific files and line numbers
5. Distinguish facts (verified in codebase) from assessments (analytical judgement)
6. Explicitly note aspects of the brief that are well-founded, stating what they verified and why it needs no changes
7. List any files read beyond the context package, so they can be included in the report's "Context consumed" section

### Phase 4 — Collect analyses

Wait for all four analysts to respond via the team messaging system. If an analyst fails or does not respond within the platform's default task timeout, proceed with available analyses and note the missing analyst in the report.

### Phase 5 — Generate report

The report has two primary content sections. The findings list consolidates every discrete correction, risk, question, insight, and opportunity produced by the analysts. The enhanced brief is the original user input regenerated at the same level of detail, with all findings applied.

Build the findings list first, then use it as the basis for the enhanced brief. In the report, the enhanced brief appears first — it is the primary content for the planning agent. The findings list follows as supporting detail.

**Findings**

Consolidate all analyst findings into a single list, grouped by category.

Consolidation rules:

- Deduplicate findings across analysts (prefer the most specific formulation)
- No per-analyst attribution
- No summary section, no recommendation line
- Each finding has a category-prefixed identifier (C1, C2 for Correction; R1, R2 for Risk; Q1, Q2 for Question; I1, I2 for Insight; O1, O2 for Opportunity), description, and file:line references where applicable
- Omit categories that have no findings

**Enhanced brief**

Regenerate the original user input as a progressively enhanced version. This is not a summary — it reproduces the brief at the same level of detail as the original, with findings applied throughout.

Walk through the original brief's structure and content. Reconstruct it element by element:

- Preserve the user's original intent, goals, and level of detail — enhance the brief, do not condense it
- Omit context-gathering directives that the analysis has fulfilled — instructions to fetch or read artefacts (e.g., "run /plan-read X", "inspect touched files") have been addressed during analysis; exclude them. Preserve directives that express constraints, goals, or design questions for the planner.
- Where the original content is accurate and well-founded, preserve it unchanged
- Reproduce diagnostic artefacts verbatim — error messages, stack traces, query expressions, code snippets, API requests, and response codes are primary evidence; include them in full, not paraphrased or referenced. If an artefact is misleading, correct it in place and cite the evidence.
- Where a finding corrects a factual error or invalid assumption, replace the incorrect content with the correction and cite the evidence (file:line). Reference the finding number.
- Where a finding identifies a risk, note it inline at the relevant point in the narrative
- Where a finding adds architectural insight, fold it into the narrative where it is most relevant
- Where a finding presents an opportunity or alternative, include it alongside the original approach

The result reads as if the user had written the brief with full knowledge of the codebase. Incorrect preliminary information is corrected in place. The planning agent can consume the enhanced brief directly as primary context.

**Open questions** remain as a distinct subsection — they require user input and cannot be resolved into the narrative.

Output the report:

```
# Pre-plan analysis

## Analysts

1. [name] -- [specialisation]
2. [name] -- [specialisation]
3. [name] -- [specialisation]
4. [name] -- [sceptic description]

## Enhanced brief

[The original user input regenerated at the same level of detail, with findings applied
throughout. Corrections replace incorrect content in place with file:line evidence and
reference the finding number (e.g., "see Finding C2"). Risks, insights, and opportunities
are woven into the narrative at the points they apply. Accurate content is preserved unchanged.
The result is the user's brief as it would read with full knowledge of the codebase.]

### Open questions [omit if empty]

[Questions that require user input before planning -- one per line. Full context in § Question below.]

## Findings

### Correction [omit if empty]

[Numbered findings -- each with description, what was wrong, what is correct, and file:line evidence]

### Risk [omit if empty]

[Numbered findings -- each with description and file:line references]

### Question [omit if empty]

[Numbered findings -- ambiguities the codebase could not resolve]

### Insight [omit if empty]

[Numbered findings -- each with description and file:line references]

### Opportunity [omit if empty]

[Numbered findings -- each with description and file:line references]

## Context consumed

[Numbered list of files read during Phase 2 and by analysts. Group by source:
parent context package, then analyst-discovered files. Omit files that were
listed in the brief but not found or not readable -- note these separately.]
```

### Phase 6 — Save and copy report

#### Save report

Write the report to `.claude/reports/pre-plan-{date}-{id}.md`, where `{date}` is the current date in `YYYY-MM-DD` format and `{id}` is the same random suffix used for the team name (e.g., `pre-plan-2026-02-16-a3f9.md`).
Create the `.claude/reports/` directory if it does not exist.

#### Copy report

Copy the report to the system clipboard silently. Write the report to a temp file and pipe it into the platform-specific command via Bash:

```bash
REPORT_FILE=$(mktemp)
cat > "$REPORT_FILE" << 'REPORTEOF'
<paste the report text here>
REPORTEOF
OS=$(uname -s)
case "$OS" in
  MINGW*|MSYS*|CYGWIN*) cat "$REPORT_FILE" | clip ;;
  Darwin)                cat "$REPORT_FILE" | pbcopy ;;
  Linux)                 cat "$REPORT_FILE" | xclip -selection clipboard 2>/dev/null || cat "$REPORT_FILE" | xsel -b ;;
esac
rm -f "$REPORT_FILE"
```

Replace `<paste the report text here>` with the full report text.

### Phase 7 — Clean up

Send `shutdown_request` to all analysts. Wait briefly for acknowledgements, then proceed to `TeamDelete` — do not block indefinitely on unresponsive analysts.

## Constraints

- Do not ask follow-up questions after the report
- The report is the absolute last text output
- The clipboard command runs silently — no output after the report

## Error handling

- If no actionable brief is found (no arguments and no actionable message in context), report this and stop
- If a file path resolves but is not readable, report the error and stop
- If the repository is empty or no relevant files are found, report this and stop
- If an analyst fails or times out, note the missing analyst in the report and proceed with available findings
