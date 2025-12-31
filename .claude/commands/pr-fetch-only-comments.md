# Fetch PR comments (no inline)

## Usage

- `/pr-fetch-only-comments` - Uses the PR number from current branch
- `/pr-fetch-only-comments {PR_NUM}` - Fetches from the specified PR

## Context

Fetches PR description, reviews, and general discussion comments — excludes inline code comments. Lighter alternative to `/pr-fetch-all-comments` when code-level feedback isn't needed.

## Task

1. Identify the PR number from {PR_NUM} argument, or use `gh pr view --json number` to get it from the current branch. If not found, report this and stop.
2. Fetch all data in a single call:
   ```bash
   gh pr view {PR_NUM} --json title,author,createdAt,body,reviews,comments
   ```
3. Present the data in this order:
   - PR description (title, author, date, body)
   - Reviews (author, state, body)
   - Issue comments in chronological order

## Requirements

- This is read-only — do not create, edit, or delete any GitHub resources
- Include review state (approved, changes_requested, commented) for each review

## Error handling

- If PR does not exist, report the error
- If there are permission issues, report them
