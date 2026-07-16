---
description: Generate a tracker-ready QA handoff and test plan from the git diff
---

Invoke the highway-skills:qa-handoff skill.

Arguments (optional): $ARGUMENTS
Supported: --pr N | --uncommitted | --staged | --last-commit | --last N | --since <commit> | base..head
No arguments → diff against the repo's default integration branch.

Follow the skill's workflow end to end:
1. Discover project context (stack, layout, tracker, default branch) — do not assume one
2. Build the canonical file ledger from the diff and classify domains
3. Analyze inline (small diffs) or dispatch domain specialists in parallel (large/multi-scope)
4. Audit coverage to 100% of changed files
5. Classify risk (Low/Medium/High) — nature of change first, then triggers
6. Output the handoff in the skill's required format
7. If a tracker integration is available, publish it to the ticket per the skill's Step 7
