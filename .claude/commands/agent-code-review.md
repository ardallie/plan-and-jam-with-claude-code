# Run a pre-PR agent code review

## Usage

- `/agent-code-review` — current branch vs default branch
- `/agent-code-review pr <number|URL>` — PR by number (current repo) or full URL
- `/agent-code-review origin/<branch>` — remote branch vs default branch
- `/agent-code-review branch <name>` — local branch vs default branch
- `/agent-code-review commit <sha>` — single commit diff (SHA must be at least 7 characters)
- `/agent-code-review directory <path>` — all files in the specified directory
- Text after the scope parameters is passed as additional instructions

## Context

Use before creating a pull request, or to review any branch, commit, PR, or directory.
Best suited to non-trivial changes; trivial fixes do not warrant a full agent review.

## Task

Eight phases executed in order.

### Phase 1 — Resolve scope

Determine the default branch:

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

Parse the first parameter to determine the review source. Evaluate rules in the order listed; first match wins.

- **Empty** — current branch; `git diff <default>...HEAD`
- **`pr`** — second token is either a PR number or a full URL. If numeric, fetch with `gh pr diff <number>`. If URL, extract owner, repo, and number via regex `https://github.com/([^/]+)/([^/]+)/pull/(\d+)` and fetch with `gh pr diff <number> --repo <owner>/<repo>`.
- **Starts with `origin/`** — treat as remote ref; run `git fetch origin` then `git diff <default>...<value>`
- **`branch`** — second token is the local branch name; `git diff <default>...<branch>`
- **`commit`** — second token is the SHA; `git show <sha>`
- **`directory`** — second token is the directory path; read all files in that directory recursively
- **Other string** — use `AskUserQuestion` to clarify the intended scope. Present the input value and suggest the available keyword forms (`pr`, `branch`, `commit`, `directory`, `origin/`). Proceed based on the user's response.

Keyword sources (`pr`, `branch`, `commit`, `directory`) consume two tokens; remaining tokens are additional instructions.
All other sources consume one token or none; remaining tokens are additional instructions.

Use the resolved ref for all git commands in subsequent phases (e.g., `origin/feature-branch` for remote branches).

`pr`, `branch`, `commit`, and `directory` are reserved — to review a branch named "commit", use `branch commit`.

### Phase 2 — Collect metadata

Apply a combined line budget of **15,000 lines** across all source material (diff, file contents, or both).

**`commit` source** — all diff and file data comes from `git show <sha>`. Count the output lines via `wc -l`. If the total exceeds 15,000 lines, trigger the budget warning. Skip the branch-based commands below.

**`directory` source** — gather all text files in the specified directory (skip binaries). There is no diff — pass the full contents of each file to reviewers. If the directory does not exist, report the error and stop. Count total lines across all gathered files. If the total exceeds 15,000 lines, trigger the budget warning. Skip the branch-based commands below.

**All other sources** — gather:

- Changed file list: `git diff <default>...<branch> --name-only` (or `gh pr diff <number> --name-only` for PRs)
- Commit messages: `git log -10 <default>..<branch>` (or `gh pr view <number> --json commits` for PRs)

If the diff is empty, report "No changes detected" and stop.

Count diff lines via `wc -l` on the diff output. If the diff alone exceeds 15,000 lines, trigger the budget warning immediately.

If the diff fits within budget, estimate total file sizes from `git diff --stat` output. If the estimated diff + file lines ≤ 15,000, read all changed files in full. If the estimated total exceeds 15,000, trigger the budget warning.

**Budget warning** — use `AskUserQuestion` before proceeding. Present the line count and offer:

1. Continue with the first 15,000 lines (truncated review)
2. Stop and narrow the scope

Include source-specific advice: for directory sources, suggest narrowing the directory path; for commit sources, suggest reviewing a smaller commit; for diff sources, suggest isolating generated files in a separate commit or reviewing a single commit.

If the user chooses to stop, end the task. If the user chooses to continue, keep the first 15,000 lines, discard the rest, and note the truncation for reviewers.

### Phase 3 — Create review team

Generate a random 8-digit hex suffix (e.g., `a3f9b2c1`) using a shell command: `openssl rand -hex 4 2>/dev/null || date +%s | sha256sum | head -c 8`. Create the team via `TeamCreate` with name `agent-code-review-{suffix}`. Spawn four reviewers via the Task tool (`subagent_type: "general-purpose"`, `model: "sonnet"`), passing the team name. Each reviewer receives the available source material (diff or file contents), file list, commit context where applicable, and any additional instructions.

Three reviewers receive specialisations chosen by the system based on the code under review. The fourth is the **sceptic** — it challenges assumptions, questions necessity, identifies what the other reviewers missed, and suggests simpler alternatives.

Reviewers report findings with severity (Critical/High/Moderate/Minor), file and line reference, description, and suggested fix. They must also explicitly note areas they reviewed and found correct, stating what they checked and why it needs no changes. Prefix findings that require user input with `[Question]` within their severity group. These drive the interview phase.

Tag as `[Question]` when the finding depends on information not present in the codebase — business requirements, deployment constraints, or intentional design trade-offs. Do not tag findings with clear, codebase-derivable fixes.

- `[Question]` — "The error handler silently swallows exceptions. Is this intentional for this endpoint?" (requires domain knowledge unavailable in the codebase)
- Not `[Question]` — "The error handler silently swallows exceptions. Add logging and re-throw." (actionable without user input)

### Phase 4 — Collect reviews

Wait for all four reviewers to respond via the team messaging system. If a reviewer fails or does not respond within the platform's default task timeout, proceed with available reviews and note the missing reviewer in the report.

### Phase 5 — Generate report

Consolidate all reviewer findings into a single severity-grouped report. Apply these rules:

- Deduplicate: if multiple reviewers flagged the same issue, merge into one finding. When merging, use the highest severity.
- Preserve `[Question]` prefixes during deduplication and consolidation. A merged finding retains the prefix if any constituent finding had it.
- No per-reviewer attribution. The developer does not need to know which agent found what.
- Omit sections that have no findings, including "Approved without changes".
- No findings summary or recommendation line.

Output the report:

```
# Agent code review report

## Summary

Title: {concise title suitable for GitHub}
Source: [current branch | pr #N | branch name | commit sha | directory path]

[1-2 paragraphs: what the changes do, which areas of the codebase they affect, and key design decisions]

**Tip:** start a new conversation before acting on this report.

## Reviewers

1. [name] — [role description]
2. [name] — [role description]
3. [name] — [role description]
4. [name] — [role description]

## Findings

### Critical [omit if empty]

[consolidated findings — each with file:line reference, description, recommended fix]

### High [omit if empty]

[findings]

### Moderate [omit if empty]

[findings]

### Minor [omit if empty]

[findings]

### Approved without changes [omit if empty]

[areas/aspects reviewed by one or more reviewers and found correct — aggregate all positive assessments]

## Clarifications [omit if no interview]

[User responses from interview]
```

### Phase 6 — Save report

Write the report to `.claude/reports/{yyyyMMdd}-{HHmm}-agent-code-review-{suffix}.md`,
where `{yyyyMMdd}` and `{HHmm}` are local machine time (`date +%Y%m%d` and `date +%H%M`)
and `{suffix}` is the same hex suffix used for the team name.
Create the `.claude/reports/` directory if it does not exist.

If the report contains `[Question]`-prefixed findings, proceed to the interview phase after clean up.
Otherwise the command ends after clean up.

### Phase 7 — Clean up

The team is deleted before the interview phase. The interview uses `AskUserQuestion` on the parent agent and does not require the team to be active.

Send `shutdown_request` to all reviewers. Wait briefly for acknowledgements, then proceed to `TeamDelete` — do not block indefinitely on unresponsive reviewers.

### Phase 8 — Interview

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

- Do not proceed to implementation unless the user explicitly approves — the review is advisory only
- The command ends after the interview save (or after cleanup if no interview). The conversation may continue with other work.
- After interview, the saved report file must be overwritten with updated content

## Error handling

- If a keyword (`pr`, `branch`, `commit`, `directory`) is given without a second token, report the expected syntax and stop
- If the `pr` second token is not a valid number or URL, report the expected format and stop
- If the PR, branch, or commit is not found, report the error and stop
- If the directory does not exist or is empty, report the error and stop
- If the diff is empty, report "No changes detected" and stop
- If `gh` or `git` commands fail, report the error and stop
- If there are permission issues, report the error and stop
