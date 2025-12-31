# Respond to PR review comments

## Usage

- `/pr-response` - Uses the PR number from conversation context
- `/pr-response {PR_NUM}` - Responds to comments on the specified PR

## Context

This command responds to feedback from the automated Claude Code Review workflow. It posts both a summary comment and individual threaded replies to each review comment.

## Task

1. Identify the PR number from {PR_NUM} argument, or search the conversation for a PR URL or number. If not found, report this and stop.
2. Fetch repository info: `gh repo view --json owner,name`
3. Fetch all review comments: `gh api repos/{OWNER}/{REPO}/pulls/{PR_NUM}/comments --jq '.[] | {id, path, line, body}'`
4. Analyse each comment against what was implemented in the conversation
5. Post a summary comment using `gh pr comment {PR_NUM} --body "..."`
6. Post threaded replies to each comment using `gh api repos/{OWNER}/{REPO}/pulls/{PR_NUM}/comments/{COMMENT_ID}/replies -f body="..."`
7. Return confirmation that all responses were posted

## Response format

Prefix each item with `[x]` (resolved) or `[i]` (not resolved).

**Summary comment structure:**

For resolved issues:
- `[x]` **Brief title** - One-line summary
- **Modified:** Affected files
- **Change:** What was changed and why

For unresolved issues:
- `[i]` **Brief title** - One-line summary
- **Reason:** Why the suggestion was not implemented

**Threaded reply structure:**

- `[x]` Resolved - explain how, reference specific files and lines
- `[i]` Not resolved - explain current status and rationale

## Requirements

- Address EVERY review comment, not just resolved ones
- Be truthful and accurate about what was done
- Keep responses concise but specific
- Use the replies API for threaded responses, not standalone inline comments

## Error handling

- If PR number cannot be determined, report this clearly and stop
- If API calls fail, report the error
