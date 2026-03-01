# Revise unit tests and documentation for the current branch

## Usage

- `/agent-revisor` — revise tests and auto-discovered documentation (from manifest and CLAUDE.md files)
- `/agent-revisor file1.md file2.md` — revise tests and the specified documentation files
- `/agent-revisor ["file1.md", "file2.md"]` — JSON array format for documentation files
- Text after the last valid file path (or after the JSON array) is passed to both agents as additional instructions

## Context

Use after implementation is complete and before PR creation. Spawns a two-agent team to revise unit tests and documentation in parallel. Agents remain alive after reporting so the user can iterate.

## Task

Five phases executed in order.

### Phase 1 — Determine scope and parse arguments

**Git scope** — detect the default branch:

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

Check the current branch (`git branch --show-current`). If the current branch is the default branch, report: "Cannot revise — currently on the default branch." and stop.

Run `git diff --name-only <default>...HEAD` for the touched file list.

**Validation**: If diff is empty, report "No changes detected on the current branch." and stop.

**Argument parsing** (three paths):

1. **No arguments** -> empty documentation file list, no additional instructions
2. **JSON array** -> if the arguments contain `[`, strip any prefix text before it (handles `Reference files: [...]`, `Documentation files: [...]`, etc.), parse the bracketed content as a JSON array. Text after the closing `]` is additional instructions. If the JSON is malformed, report: "Could not parse JSON array. Expected format: `[\"file1.md\", \"file2.md\"]`" and stop.
3. **Whitespace-split** (default) -> test each whitespace-delimited token as a file path in order. The first token that does not resolve to a readable file ends the file list — that token and everything after it becomes additional instructions (consistent with `agent-pre-planner` argument parsing).

After extraction, filter to `.md`, `.mdx`, `.txt`, `.rst`, and `.adoc` files. Log any discarded files so the user can see what was filtered: "Skipped non-documentation file: {path}". The filter targets documentation formats; project-specific formats outside this set can be passed via additional instructions to the documentation-revisor.

**Documentation manifest**: Read `.claude/rules/documentation.md` if it exists. Extract file paths listed in it. Validate each path — keep those that resolve to readable files, silently skip those that do not. If the manifest file does not exist, proceed without it (this is not an error).

**CLAUDE.md auto-discovery**: Glob for `**/CLAUDE.md` across the repository.

**Merge documentation file list**: Combine files from three sources (arguments, manifest, CLAUDE.md discovery). Deduplicate. This merged list is the documentation-revisor's scope. Arguments are optional supplements — the manifest and CLAUDE.md discovery provide the baseline.

### Phase 2 — Assemble context

Assemble the following for the agent prompts:

- **Plan summary** — if `/plan-read` was invoked earlier in the conversation, extract the plan title, context section, and key design decisions as a condensed summary.
- Touched file list (`git diff --name-only`)
- Full diff (`git diff <default>...HEAD`)
- Commit messages (`git log -10 <default>..HEAD --oneline`)
- Documentation file list (for documentation-revisor only)
- Additional instructions from Phase 1 (forwarded to both agents, if present)

**Line budget**: Apply a 10,000-line cap to the diff. If the diff exceeds 10,000 lines, pause and ask the user whether to continue with the first 10,000 lines or stop. Agents process files individually (reading and editing one at a time), so individual file reads by agents are not counted against the budget — only the diff context passed in the initial prompt is capped.

**Edge case — no documentation files**: If the merged documentation file list is empty (no arguments, no manifest, no CLAUDE.md files found), skip documentation-revisor. Report: "No documentation files to revise." Spawn unit-test-revisor only.

**Edge case — nothing to revise**: If documentation files are empty AND all touched files have non-testable extensions (e.g. `.md`, `.json`, `.yaml`, `.lock`, `.svg`, `.png` — configuration files, static assets, and markup with no executable logic), report: "Nothing to revise — no testable source files and no documentation files." and stop without spawning the team.

### Phase 3 — Create revision team

`TeamCreate` with unique name (e.g., `revisor-a3f9`). Spawn via Task tool:

- `subagent_type: "general-purpose"`
- `model: "sonnet"` for both agents
- Pass team name to each

**unit-test-revisor** receives:
- Touched file list, full diff, commit messages, plan summary (if available), additional instructions (if any)
- Instructions:
  1. Discover the project's test conventions — search for existing test files using common patterns (`*.test.*`, `*.spec.*`, `__tests__/`, `test/`, `*_test.*`, `test_*.*`). Identify the naming convention, directory placement, test framework, and assertion style from the first few matches.
  2. For each touched source file, locate its corresponding test file(s) using the discovered conventions.
  3. If a test file exists, read it and the source file. Revise tests to cover the changes in the diff. Add test cases for new functionality. Update tests that reference changed behaviour. Remove tests for deleted functionality.
  4. If no test file exists for a touched source file, create one following the discovered conventions.
  5. Skip non-testable files (configuration, markdown, generated files, type declarations with no logic).
  6. If no testable files exist among the touched files, report "No testable files found" and exit without edits.
  7. Run the test suite after making changes. If tests fail, read the failure output, fix the tests, and re-run. Iterate until all tests pass or the failures are clearly outside the scope of the revision (e.g., pre-existing failures unrelated to touched files). Report any unresolved failures in the summary.
  8. Do not commit or push code.
  9. Send a summary to the team lead via `SendMessage`: files revised (path + what changed), files created (path + what it covers), files skipped (path + reason).

**documentation-revisor** receives (only if documentation files exist):
- Documentation file list, touched file list, full diff, commit messages, plan summary (if available), additional instructions (if any)
- Instructions:
  1. **Extract a change manifest from the diff.** Scan the diff for:
     - Renamed symbols (old name -> new name)
     - New exports, methods, types, or functions
     - Removed exports, methods, types, or functions
     - Changed function signatures or type definitions
     Record these as a checklist before touching any documentation file.
  2. **For each documentation file:**
     a. Read the documentation file.
     b. Identify the source files this documentation file references or describes — scan for file paths, module names, and symbol references in the text. Read those source files (not just the diff) to understand the current API surface: all methods, types, exports, and patterns.
     c. **Mechanical pass:**
        - For each renamed symbol in the change manifest, Grep the documentation file for every occurrence of the old name. Replace all using the Edit tool.
        - For removed symbols, search and remove references.
        - For new symbols, identify where they belong in the document structure and add them.
     d. **Semantic pass:**
        - Compare every description in the documentation against the current source — implementation patterns, data flow, architecture, file paths, workflow steps, prose descriptions.
        - Update anything that no longer matches.
        - The change manifest is a starting checklist, not a ceiling — any inaccurate documentation must be updated regardless of whether it appears in the manifest.
  3. **Post-edit verification** — after all edits, grep each old/removed symbol name across all documentation files to confirm step 2c caught every occurrence. Fix any remaining references.
  4. Do not commit or push code.
  5. Send a summary to the team lead via `SendMessage`: files revised (path + what changed), files skipped (path + reason). Include the change manifest in the summary.

### Phase 4 — Collect results

Wait for both agents (or one, if documentation-revisor was skipped) to send their summaries via `SendMessage`. Messages are delivered automatically when each agent finishes its turn. If an agent goes idle after sending its summary, that is normal — the summary has been received. If an agent fails or does not respond within the platform's default task timeout, proceed with available results and note the missing agent in the output.

### Phase 5 — Output summary

Consolidate agent summaries into brief output. No report file saved. No clipboard copy — the work product is the file changes themselves, not a report.

```
---

# Revision summary

## Unit tests

[summary from unit-test-revisor]

## Documentation

[summary from documentation-revisor, or "Skipped — no documentation files to revise"]

---
```

After the summary, append:

```
Agents are still running. To continue working with an agent, ask me to message them.
Team: [team name]. To clean up: ask me to shut down the team.
```

## Error handling

- Current branch is the default branch -> report "Cannot revise — currently on the default branch." and stop
- Empty diff (no touched files) -> report "No changes detected on the current branch." and stop
- Nothing to revise (no testable files and no documentation files) -> report and stop before spawning team
- Malformed JSON array in arguments -> report expected format and stop
- Non-documentation files in arguments -> log each skipped file, continue with remaining
- Diff exceeds 10,000 lines -> pause, ask user to continue (truncated) or stop
- `.claude/rules/documentation.md` missing -> proceed without it (not an error)
- Paths in documentation manifest unreadable -> skip silently, use remaining valid paths
- Agent fails or times out -> note in summary, proceed with available results
- Git commands fail -> report error and stop

## Constraints

- Do not ask follow-up questions after the summary (the agent interaction note is informational, not a question)
- The summary and agent interaction note are the final output
