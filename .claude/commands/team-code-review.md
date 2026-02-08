# Run a pre-PR team code review

## Usage

- `/team-code-review` or `/team-code-review local` -> current branch vs default branch
- `/team-code-review <PR_URL>` -> e.g., `https://github.com/owner/repo/pull/263`
- `/team-code-review <number>` -> assumes PR in current repo
- `/team-code-review origin/<branch>` -> remote branch vs default branch
- `/team-code-review <branch>` -> local branch vs default branch
- Text after the first parameter is passed to all reviewers as additional instructions

## Context

Use this before creating a pull request. It sits between `/plan-handoff` and `/pr-create` in the plan workflow and can also be used standalone for any branch or PR. Intended for non-trivial changes — trivial fixes do not warrant four reviewers.

## Task

Six phases executed in order.

### Phase 1 — Resolve scope

Determine the default branch:

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

Parse the first parameter to determine the diff source. Evaluate rules in the order listed; first match wins.

- **PR URL** — extract owner, repo, and number via regex `https://github.com/([^/]+)/([^/]+)/pull/(\d+)`; fetch with `gh pr diff <number> --repo <owner>/<repo>`
- **Numeric** — treat as PR number in current repo; fetch with `gh pr diff <number>`
- **Starts with `origin/`** — treat as remote ref; run `git fetch origin` then `git diff <default>...<value>`
- **Empty or `local`** — current branch; `git diff <default>...HEAD`. The keyword `local` is consumed as the scope token, not forwarded as instructions.
- **Other string** — treat as local branch name, including branches containing `/` (e.g., `feature/login`); `git diff <default>...<branch>`

Everything after the first whitespace-delimited token is passed to reviewers as additional instructions.

### Phase 2 — Collect metadata

Gather:

- Changed file list: `git diff <default>...<branch> --name-only` (or `gh pr diff <number> --name-only` for PRs)
- Commit messages: `git log --oneline -10 <default>..<branch>` (or `gh pr view <number> --json commits` for PRs)

If the diff is empty, report "No changes detected" and stop.

Read all changed files in full so reviewers have complete file context beyond the diff hunks. If more than 20 files changed, skip full file reads and provide the diff only — note this for reviewers.

If the diff exceeds 2000 lines, keep the first 2000 lines and discard the rest. Note the omission and list truncated or excluded files.

### Phase 3 — Create review team

Create the team with a unique name by appending a short random suffix (e.g., `code-review-a3f9`) via `TeamCreate`. Spawn four reviewers via the Task tool (`subagent_type: "general-purpose"`, `model: "sonnet"`), passing the team name. Each reviewer receives the diff, file list, commit context, and any additional instructions.

Three reviewers receive specialisations chosen by the system based on the code under review. The fourth is the **sceptic** — it challenges assumptions, questions necessity, identifies what the other reviewers missed, and suggests simpler alternatives.

Each reviewer outputs findings as a bulleted list. Each finding includes: severity (Critical/High/Medium/Low), file path, line reference where applicable, description, and suggestion.

### Phase 4 — Collect reviews

Wait for all four reviewers to respond via the team messaging system. If a reviewer fails or does not respond within the platform's default task timeout, proceed with available reviews and note the missing reviewer in the report.

### Phase 5 — Generate report

Consolidate findings into a structured report between `---` separators:

```
---

# Team code review report

## Review scope

Source: [description]
Files changed: [count]

## [Reviewer 1 — system-assigned focus]

[findings or "No issues identified"]

## [Reviewer 2 — system-assigned focus]

[findings or "No issues identified"]

## [Reviewer 3 — system-assigned focus]

[findings or "No issues identified"]

## Sceptic

[critical perspective or "No concerns"]

## Summary

Total: [count by severity]
Recommendation: [Proceed to PR / Address findings first]

---
```

Copy the report to the system clipboard silently. Detect the platform and run the appropriate command via Bash:

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

### Phase 6 — Cleanup

Send `shutdown_request` to all reviewers. Wait briefly for acknowledgements, then proceed to `TeamDelete` — do not block indefinitely on unresponsive reviewers.

## Constraints

- Do not ask follow-up questions after the report ("Should we proceed?", "What would you like to do next?")
- The report is the absolute last text output
- The clipboard command runs silently — no output after the report

## Error handling

- If the PR URL format is invalid, report the expected format and stop
- If the PR is not found, report the error and stop
- If the branch is not found, report the error and stop
- If the diff is empty, report "No changes detected" and stop
- If `git fetch` fails (e.g., network issues), report the error and stop
- If there are permission issues, report them
