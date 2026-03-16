# Run a pre-plan analysis

## Usage

- `/agent-pre-planner` — uses the most recent actionable user message as the brief
- `/agent-pre-planner <issue>` — uses the specified issue number (e.g., `85`)
- `/agent-pre-planner <file1> <file2> ...` — reads files as the brief
- Text after the last valid file path or issue number is passed to all analysts as additional instructions

## Context

Use this before entering plan mode. 
It spawns an analysis team to explore the codebase from multiple angles, surface risks, correct assumptions, and identify opportunities. 
The output is a two-part report: an enhanced brief followed by a consolidated findings list.

## Task

Eight phases executed in order.

### Phase 1 — Extract brief

Parse the arguments:

- **File paths provided** — test each whitespace-delimited token as a file path in order. The first token that does not resolve to a readable file ends the file list — that token and everything after it is passed to all analysts as additional instructions. Read each valid file and concatenate their contents as the brief.
- **Issue number** — if the first token is not a valid file path but is numeric, treat it
  as a GitHub issue number. Fetch via:

  ```bash
  gh issue view <number> --json title,body,state,createdAt,comments
  ```

  Parse JSON output: present title, body, and comments chronologically with author and
  timestamp. The issue title and body form the brief. Comments provide additional context
  (handoff notes, revised decisions, discussion). Everything after the issue number token
  is passed as additional instructions.

  Only one issue number is supported per invocation. Subsequent numeric tokens are passed as additional instructions, not as issue numbers. To analyse multiple issues, run the command separately for each.
- **No arguments** — identify the most recent user message in conversation context that describes an intention, suggestion, technical query, or implementation plan. Quote it verbatim as the brief.

If no brief is found (no arguments and no actionable message in context), report this and stop. If a file path resolves but is not readable, report the error and stop.

### Phase 2 — Explore codebase

Perform targeted exploration driven by the brief. Build a context package:

- Repository overview (top-level listing, key config files)
- Relevant files mentioned or implied by the brief (read in full)
- Related patterns (existing implementations similar to what the brief describes)
- Dependency map (modules adjacent to or affected by the proposed change)

Read all files explicitly referenced in the brief — reference lists, documentation lists, file paths mentioned inline, slash commands, and context files in the target repository. These have no cap. Cap additional exploratory reads (files discovered by the parent but not mentioned in the brief) at 40; if the cap is reached, note this in the Context files section and list the areas skipped. Prioritise entry points and interfaces.

Record which files were read — the report includes them in the Context files section as a single numbered list.

### Phase 3 — Create analysis team

Generate a random 8-digit hex suffix (e.g., `a3f9b2c1`) using a shell command: `openssl rand -hex 4 2>/dev/null || date +%s | sha256sum | head -c 8`. Create the team via `TeamCreate` with name `agent-pre-planner-{suffix}`. Spawn four analysts via the Task tool (`subagent_type: "general-purpose"`, `model: "opus"`), passing the team name. Analysts use `opus` rather than `sonnet` because pre-plan analysis involves open-ended codebase reasoning and hypothesis evaluation — tasks that benefit from a more capable model than code review.

Each analyst receives: the brief (verbatim), the context package, their specialisation, any additional instructions from the user, and the analyst instructions below.

Three analysts receive specialisations chosen by the system based on the brief. The fourth is the **sceptic** — it challenges the premise, proposes simpler alternatives, identifies unstated assumptions, checks whether the problem is correctly framed, and flags scope risks.

Each analyst must:

1. Explore the codebase independently to verify claims and discover context beyond the parent's package
2. Report findings using exactly these categories: Insight, Correction, Risk, Opportunity, Question, Confirmed — do not use other categories such as Clarity, Accuracy, Completeness, or Feasibility
3. Resolve ambiguities using codebase evidence where possible — only escalate to Question when the codebase cannot answer it
4. Describe constraints and decision points, not implementation algorithms. Write "the plan must define how to handle X given Y" rather than "use algorithm Z to do X." Leave design space for the planner.
5. Reference specific files and line numbers
6. Distinguish facts (verified in codebase) from assessments (analytical judgement)
7. Report aspects of the brief that are well-founded as Confirmed findings (category prefix `V`), stating what was verified, the evidence (file:line), and why it needs no changes
8. List any files read beyond the context package, so they can be merged into the report's context file list

### Phase 4 — Collect analyses

Wait for all four analysts to respond via the team messaging system. If an analyst fails or does not respond within the platform's default task timeout, proceed with available analyses and note the missing analyst in the report.

### Phase 5 — Generate report

The report has two primary content sections. The findings list consolidates every discrete correction, risk, question, insight, opportunity, and confirmation produced by the analysts. The enhanced brief is the original user input regenerated at the same level of detail, with all findings applied.

Build the findings list first, then use it as the basis for the enhanced brief. In the report, the enhanced brief appears first — it is the primary content for the planning agent. The findings list follows as supporting detail.

**Findings**

Consolidate all analyst findings into a single list, grouped by category.

Consolidation rules:

- Deduplicate findings across analysts (prefer the most specific formulation)
- No per-analyst attribution
- No findings summary or recommendation line
- Each finding has a category-prefixed identifier (C1 [high], C2 [low] for Correction; R1 [high], R2 [low] for Risk; Q1 [blocking], Q2 [deferrable] for Question; I1 [high], I2 [low] for Insight; O1 [high], O2 [low] for Opportunity; V1, V2 for Confirmed), description, and file:line references where applicable
- Each finding carries a severity tag: `[high]` (materially affects the plan — wrong assumption, architectural risk, blocking dependency) or `[low]` (observational, informational, nice-to-know)
- Each question carries a priority tag instead of a severity tag: `[blocking]` (must be resolved before planning) or `[deferrable]` (can be resolved during or after planning)
- Confirmed findings carry no severity tag
- Omit categories that have no findings

**Enhanced brief**

Regenerate the original user input as a progressively enhanced version. This is not a summary — it reproduces the brief at the same level of detail as the original, with findings applied throughout.

Walk through the original brief's structure and content. Reconstruct it element by element:

- Preserve the user's original intent, goals, and level of detail — enhance the brief, do not condense it
- Omit context-gathering directives that the analysis has fulfilled — instructions to fetch or read artefacts (e.g., "run /plan-read X", "inspect touched files") have been addressed during analysis; exclude them. Preserve directives that express constraints, goals, or design questions for the planner.
- Where the original content is accurate and well-founded, preserve it unchanged
- Reproduce diagnostic artefacts verbatim — error messages, stack traces, query expressions, code snippets, API requests, and response codes are primary evidence; include them in full, not paraphrased or referenced. If an artefact is misleading, correct it in place and cite the evidence.
- Where a finding corrects a factual error or invalid assumption, replace the incorrect content with the correction and cite the evidence (file:line). Reference the finding number in bold (e.g., **see C2**) so corrections are visually distinct from other inline references.
- Where a finding identifies a risk, note it inline at the relevant point in the narrative
- Where a finding adds architectural insight, fold it into the narrative where it is most relevant
- Where a finding presents an opportunity or alternative, include it alongside the original approach

The result reads as if the user had written the brief with full knowledge of the codebase. Incorrect preliminary information is corrected in place. The planning agent can consume the enhanced brief directly as primary context.

**Open questions** remain as a distinct subsection — they require user input and cannot be resolved into the narrative. Group questions by priority: blocking first, then deferrable.

If the scope is large enough to warrant multiple implementation stages, include a workload split as the final part of the enhanced brief. Evaluate scope by considering: the number of distinct subsystems affected, the depth of the dependency chain between tasks, and whether intermediate validation gates exist.

When splitting is warranted, list each plan with a short title, its constituent tasks, dependencies on prior plans, and a validation gate (how to verify that plan's work before proceeding). Order plans by dependency — earlier plans must not depend on later ones. When the scope is narrow, state that a single plan is sufficient.

Output the report:

```
# Pre-plan analysis

## Summary

Title: {concise title suitable for GitHub}
Source: [conversation context | file paths | issue #N]

[1-2 paragraphs: what the brief is about, which areas of the codebase are affected, and key constraints or goals]

**Tip:** start a new conversation before acting on this report.

## Analysts

1. [name] — [specialisation]
2. [name] — [specialisation]
3. [name] — [specialisation]
4. [name] — [sceptic description]

## Enhanced brief

[The original user input regenerated at the same level of detail, with findings applied
throughout. Corrections replace incorrect content in place with file:line evidence and
reference the finding number in bold (e.g., **see C2**). Risks, insights, and opportunities
are woven into the narrative at the points they apply. Accurate content is preserved unchanged.
The result is the user's brief as it would read with full knowledge of the codebase.]

### Open questions [omit if empty]

[Questions that require user input before planning — grouped by priority (blocking first,
then deferrable). One per line. Full context in § Question below.]

### Workload split

[Scope assessment: brief justification for splitting or not. When splitting,
list each plan with title, tasks, dependency on prior plans, and validation gate.
When not splitting, state that a single plan is sufficient.]

## Findings

### Correction [omit if empty]

[Numbered findings — each with severity tag, description, what was wrong, what is correct, and file:line evidence]

### Risk [omit if empty]

[Numbered findings — each with severity tag, description, and file:line references]

### Question [omit if empty]

[Numbered findings — each with priority tag, ambiguities the codebase could not resolve]

### Insight [omit if empty]

[Numbered findings — each with severity tag, description, and file:line references]

### Opportunity [omit if empty]

[Numbered findings — each with severity tag, description, and file:line references]

### Confirmed [omit if empty]

[Numbered findings — each with what was verified and file:line evidence]

## Context files

[Single deduplicated numbered list of all files read during analysis — by the
parent agent during exploration and by analysts. No grouping by source, no analyst
attribution. Omit files listed in the brief but not found or not readable —
note these separately.]
```

### Phase 6 — Save report

Write the report to `.claude/reports/{yyyyMMdd}-{HHmm}-agent-pre-planner-{suffix}.md`, where `{yyyyMMdd}` and `{HHmm}` are local machine time (`date +%Y%m%d` and `date +%H%M`) and `{suffix}` is the same hex suffix used for the team name (e.g., `20260216-0945-agent-pre-planner-a3f9b2c1.md`).
Create the `.claude/reports/` directory if it does not exist.

If the report contains an `### Open questions` subsection with questions, proceed to the interview phase after clean up. Otherwise the command ends after clean up.

### Phase 7 — Clean up

Send `shutdown_request` to all analysts. Wait briefly for acknowledgements, then proceed to `TeamDelete` — do not block indefinitely on unresponsive analysts.

### Phase 8 — Interview

This phase collects user answers and overwrites the saved report file with updated content. The file save is mandatory — without it, the report lacks interview answers.

**Run the interview tool:**

Use the `AskUserQuestion` tool to present open questions interactively. Group questions by priority — blocking questions first, then deferrable. For each question, provide 2-4 answer options that help the user make an informed choice rather than composing an answer from scratch. Draw options from codebase evidence, trade-offs, or reasonable alternatives as appropriate.

If there are more questions than the tool supports per call, batch them across multiple calls — blocking questions in the first batch.

**Collect answers:**

The tool returns the user's selections. The user may also provide free-text via the built-in "Other" option. If the user declines to answer a question, leave it unresolved. If all questions are unresolved, end the interview.

**Update the report** — for each answered question:

- **Enhanced brief**: weave the answer into the narrative at the relevant point, written as a statement of fact or design decision. Reference the finding number in bold (e.g., **see Q2**).
- **Open questions subsection**: remove the answered question. If all resolved, remove the entire subsection.
- **Question finding**: prepend `[Resolved]` to the description and append the user's answer on a new line prefixed with `Answer:`. Do not delete the finding — it serves as audit trail.
- Skipped questions: no changes.

**Save updated report:**

Overwrite the same file path used in the Save report phase. Output the updated report in full.

## Constraints

- The saved report is the deliverable; the command ends after the final save
- After interview, the saved report file must be overwritten with updated content

## Error handling

- If no actionable brief is found (no arguments and no actionable message in context), report this and stop
- If a file path resolves but is not readable, report the error and stop
- If the repository is empty or no relevant files are found, report this and stop
- If an analyst fails or times out, note the missing analyst in the report and proceed with available findings
- If the issue does not exist, report the error and stop
- If `gh` commands fail, report the error and stop
