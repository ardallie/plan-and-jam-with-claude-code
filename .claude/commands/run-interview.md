Present open questions to the user interactively via the `AskUserQuestion` tool.

Every option list must follow the format rules in `.claude/rules/principles.md` under "Presenting design options":

- Include "keep current behaviour" as a first-class option.
- Mark exactly one option `(recommended)`, or state explicitly that no recommendation is given.
- Lead the recommendation's justification with the concrete user-visible payoff, not with architectural symmetry.
