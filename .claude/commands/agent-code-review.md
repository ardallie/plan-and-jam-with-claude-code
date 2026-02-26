# Run a pre-PR agent code review

## Usage

- `/agent-code-review` -> current branch vs default branch
- `/agent-code-review <PR_URL>` -> e.g., `https://github.com/owner/repo/pull/263`
- `/agent-code-review pr <number>` -> PR in current repo
- `/agent-code-review origin/<branch>` -> remote branch vs default branch
- `/agent-code-review commit <sha>` -> single commit diff (SHA must be at least 7 characters)
- `/agent-code-review <branch>` -> local branch vs default branch
- `/agent-code-review directory <path>` -> all files in the specified directory
- Text after the scope parameters is passed to all reviewers as additional instructions

## Context

Use before creating a pull request, or to review any branch, commit, PR, or directory.
Best suited to non-trivial changes; trivial fixes do not warrant a full agent review.

## Task

Six phases executed in order.

### Phase 1 — Resolve scope

Determine the default branch:

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

Parse the first parameter to determine the review source. Evaluate rules in the order listed; first match wins.

- **Empty** — current branch; `git diff <default>...HEAD`
- **PR URL** — extract owner, repo, and number via regex `https://github.com/([^/]+)/([^/]+)/pull/(\d+)`; fetch with `gh pr diff <number> --repo <owner>/<repo>`
- **`pr`** — second token is the PR number; fetch with `gh pr diff <number>`
- **Starts with `origin/`** — treat as remote ref; run `git fetch origin` then `git diff <default>...<value>`
- **`commit`** — second token is the SHA; `git show <sha>`
- **Bare SHA** — 7–40 hex characters; `git show <sha>`. Note: a branch name composed entirely of hex characters (e.g. `abc1234`) will be treated as a SHA. Use `git diff` directly in that case.
- **`directory`** — second token is the directory path; read all files in that directory recursively
- **Other string** — treat as local branch name, including branches containing `/` (e.g., `feature/login`); `git diff <default>...<branch>`

For `pr`, `commit`, and `directory`, both tokens (keyword and value) are consumed as scope and not forwarded as instructions; everything after the second token is passed as additional instructions. For all other sources, everything after the first token is passed as additional instructions.

Note: `pr`, `commit`, and `directory` are reserved keywords. A branch with one of these names cannot be reviewed using the bare branch form — use `git diff` directly in that case.

### Phase 2 — Collect metadata

For a **`commit` keyword or bare SHA** source, all diff and file data comes from `git show <sha>`. Skip the branch-based commands below.

For a **directory** source, gather all text files in the specified directory (skip binaries). There is no diff — pass the full contents of each file to reviewers. If the directory does not exist, report the error and stop. Apply the same 10,000-line budget to the total file contents: if the total exceeds 10,000 lines, print the warning below, then pause and ask the user whether to continue with the first 10,000 lines or stop. Skip the branch-based commands below.

Warning to print when directory file contents exceed 10,000 lines:

```
---

These file contents exceed 10,000 lines. A review of this scope risks missing issues and producing low-quality findings.

Recommendation:
1. Identify files that can be excluded from the review and narrow the directory path.
2. Run the review against a specific subdirectory: `/agent-code-review directory <path>`

Continue with the partial review (first 10,000 lines only), or stop here to
narrow the scope?

---
```

For all other sources, gather:

- Changed file list: `git diff <default>...<branch> --name-only` (or `gh pr diff <number> --name-only` for PRs)
- Commit messages: `git log -10 <default>..<branch>` (or `gh pr view <number> --json commits` for PRs)

If the diff is empty, report "No changes detected" and stop.

Apply a combined line budget of **10,000 lines** across the diff and full file reads.

Evaluate:

- **Diff alone exceeds 10,000 lines** — do not proceed to Phase 3. Print the warning below, then pause and ask the user whether to continue or stop.
- **Diff fits within budget** — count the total lines across all changed files. If diff + file lines ≤ 10,000, read all files in full. If the combined total exceeds 10,000, skip full file reads and provide the diff only — note this for reviewers, then proceed to Phase 3.

Warning to print when the diff alone exceeds 10,000 lines:

```
---

This diff exceeds 10,000 lines. A review of this scope risks missing issues and producing low-quality findings.

Recommendation:
1. Identify files that can be excluded from the review (e.g. generated files) and isolate them in a separate commit.
2. Prepare a single commit containing only the essential code changes.
3. Run the review against that commit: `/agent-code-review commit <sha>`

Continue with the partial review (first 10,000 lines only), or stop here to
reorganise your commits?

---
```

If the user chooses to **stop**, end the task without proceeding to Phase 3.

If the user chooses to **continue**, keep the first 10,000 lines, discard the rest, and note the truncation for reviewers before proceeding.

### Phase 3 — Create review team

Create the team with a unique name by appending a short random suffix (e.g., `code-review-a3f9`) via `TeamCreate`. Spawn four reviewers via the Task tool (`subagent_type: "general-purpose"`, `model: "sonnet"`), passing the team name. Each reviewer receives the available source material (diff or file contents), file list, commit context where applicable, and any additional instructions.

Three reviewers receive specialisations chosen by the system based on the code under review. The fourth is the **sceptic** — it challenges assumptions, questions necessity, identifies what the other reviewers missed, and suggests simpler alternatives.

Reviewers report findings with severity (Critical/High/Moderate/Minor), file and line reference, description, and suggested fix. They must also explicitly note areas they reviewed and found correct, stating what they checked and why it needs no changes.

### Phase 4 — Collect reviews

Wait for all four reviewers to respond via the team messaging system. If a reviewer fails or does not respond within the platform's default task timeout, proceed with available reviews and note the missing reviewer in the report.

### Phase 5 — Generate report

Consolidate all reviewer findings into a single severity-grouped report. Apply these rules:

- Deduplicate: if multiple reviewers flagged the same issue, merge into one finding. When merging, use the highest severity.
- No per-reviewer attribution. The developer does not need to know which agent found what.
- Omit sections that have no findings, including "Approved without changes".
- No summary section, no recommendation line.

Output the report between `---` separators:

```
---

# Agent code review report

## Review scope

Source: [description]
Files changed: [count]

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

---
```

Copy the report to the system clipboard silently. Write the report to a temp file and pipe it into the platform-specific command via Bash:

```bash
REPORT_FILE=$(mktemp)
cat > "$REPORT_FILE" << 'REPORTEOF'
<paste the report text here>
REPORTEOF
OS=$(uname -s)
case "$OS" in
  MINGW*|MSYS*|CYGWIN*) clip < "$REPORT_FILE" ;;
  Darwin)                pbcopy < "$REPORT_FILE" ;;
  Linux)                 xclip -selection clipboard < "$REPORT_FILE" 2>/dev/null || xsel -b < "$REPORT_FILE" ;;
esac
rm -f "$REPORT_FILE"
```

Replace `<paste the report text here>` with the full report text.

### Phase 6 — Clean up

Send `shutdown_request` to all reviewers. Wait briefly for acknowledgements, then proceed to `TeamDelete` — do not block indefinitely on unresponsive reviewers.

## Constraints

- Do not ask follow-up questions after the report
- The report is the final output — nothing follows, including clipboard operation feedback

## Error handling

- If the PR URL format is invalid, report the expected format and stop
- If the PR is not found, report the error and stop
- If `pr`, `commit`, or `directory` is given without a second token, report the expected syntax and stop
- If the branch is not found, report the error and stop
- If the commit SHA is not found, report the error and stop
- If the directory does not exist, report the error and stop
- If the directory is empty, report "No files found" and stop
- If the diff is empty, report "No changes detected" and stop
- If `git fetch` fails, report the error and stop
- If there are permission issues, report the error and stop
