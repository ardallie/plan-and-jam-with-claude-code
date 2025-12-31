# Fetch all PR comments

## Usage

- `/pr-fetch-all-comments` - Uses the PR number from current branch
- `/pr-fetch-all-comments {PR_NUM}` - Fetches from the specified PR

## Context

Fetches the complete PR thread: description, reviews, inline code comments, and general discussion. Use this before responding to review feedback.

## Task

1. Identify the PR number from {PR_NUM} argument, or use `gh pr view --json number` to get it from the current branch. If not found, report this and stop.
2. Fetch PR metadata, reviews, and issue comments in a single call:
   ```bash
   gh pr view {PR_NUM} --json title,author,createdAt,body,reviews,comments
   ```
3. Fetch inline review comments (threaded code comments):
   ```bash
   gh api repos/:owner/:repo/pulls/{PR_NUM}/comments
   ```
4. Present the data in this order:
   - PR description (title, author, date, body)
   - Reviews (author, state, body)
   - Inline comments grouped by file/line as threaded conversations
   - Issue comments in chronological order

## Requirements

- This is read-only — do not create, edit, or delete any GitHub resources
- Group inline comments by file and line number, showing replies as threads
- Include review state (approved, changes_requested, commented) for each review

## Error handling

- If PR does not exist, report the error
- If there are permission issues, report them
