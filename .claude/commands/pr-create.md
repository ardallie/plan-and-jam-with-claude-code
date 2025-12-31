# Create a GitHub pull request

## Usage

- `/pr-create` - Creates a PR from the current branch to the default branch

## Context

This command creates a pull request for the current feature branch. It analyses all commits since branching and generates a PR description following the repository template.

## Task

1. Identify the default branch (main or master) and verify the current branch is a feature branch
2. Review all commits: `git log <default>..HEAD`
3. Review all changes: `git diff <default>..HEAD`
4. Read the PR template from `.github/pull_request_template.md`
5. Generate the PR description following the template structure
6. Create the PR: `gh pr create --title "..." --body "..."`
7. Return the PR URL to confirm completion

## Requirements

- Do not push code — the user must push commits before running this command
- Follow the structure defined in `.github/pull_request_template.md`
- Analyse all commits, not just the most recent one
- Generate a coherent summary that captures the overall change
- Exclude "Test plan" section from the PR description
- Exclude "Generated with Claude Code" footer

## Error handling

- If on the default branch (not a feature branch), report this clearly and stop
- If PR creation fails, report the error
