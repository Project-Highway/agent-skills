---
name: qa-handoff
description: Generates a tracker-ready QA handoff and test plan from a git diff — canonical file ledger, concrete per-file checks, risk level, and coverage proof. Use when a diff is ready to hand to QA, when asked "what should QA test here", or when a ticket needs a test plan before moving to testing. Works on any stack; the diff is the single source of truth.
---

# QA Handoff Generator

## Overview

Turn a git diff into a QA handoff a tester can execute without reading the code:
what changed in plain English, where it applies, a concrete checklist, what is NOT
impacted, and a justified risk level. The git diff is the single source of truth —
every assertion must trace back to an actual hunk, and every changed file must be
covered.

This skill is stack-agnostic: it discovers the project's context instead of assuming
one. It handles single-scope repos (FE-only or BE-only — the common case) and
monorepos (dispatch per scope) with the same workflow.

## When to Use

- A branch/PR is finishing development and QA needs a test plan
- Someone asks "what should QA test for this change?"
- A ticket is moving to a testing column and needs a handoff comment
- Re-run after significant new commits — the handoff must match the current diff

**When NOT to use:** reviewing code quality (use `code-review-and-quality`),
writing automated tests (use `test-driven-development`).

## Hard Requirements

- Git diff is the single source of truth — not the PR description, not the ticket.
- 100% of files from `git diff --name-status` must be covered, with proof.
- Checklist items must be concrete and executable — name the route/screen/command,
  the action, and the expected result.
- Must include "What is NOT impacted."
- Must include Low / Medium / High risk with justification tied to the diff.
- If any file cannot be covered, flag it explicitly and request follow-up.

## Workflow

### Step 0: Discover project context

Before analyzing the diff, learn the project (do not assume a stack):

- Read `CLAUDE.md` / `README` / the package manifest(s) for: stack, test/build
  commands, directory layout, auth/permission mechanisms, feature-flag mechanisms.
- Identify the default integration branch (`git remote show origin` → HEAD branch,
  or the project's documented convention) — that is the default diff base.
- Identify the tracker and ticket-key pattern from branch names or project docs
  (e.g. `HWAY-\d+`, `PROJ-\d+`).

### Step 1: Determine the diff range

Parse the arguments:

| Argument | Diff command |
|----------|-------------|
| _(empty)_ | `git diff <default-branch>...HEAD` |
| `--pr <number>` | PR diff via the available tool (`gh pr diff N` or the GitHub MCP) |
| `--uncommitted` | `git diff` |
| `--staged` | `git diff --cached` |
| `--last-commit` | `git diff HEAD~1..HEAD` |
| `--last <N>` | `git diff HEAD~<N>..HEAD` |
| `--since <commit>` | `git diff <commit>..HEAD` |
| `<base>..<head>` | `git diff <base>..<head>` |

### Step 2: Build the canonical file ledger

Run the diff with `--name-status` and classify every file into one or more domains
(generic — map onto whatever the project's layout actually is):

| Domain | Typical signals |
|--------|-----------------|
| UI | components, pages, templates, styles |
| STATE | stores, reducers, context providers |
| API-CLIENT | API modules, generated clients, request/response models |
| BE | controllers, services, handlers, jobs, domain logic |
| DB | migrations, schema, ORM mappings, seed data |
| AUTH | access control, permissions, policies, middleware, feature flags |
| CONFIG | env, build config, CI workflows, infra manifests |
| TEST | test files |
| DOCS | documentation (note only, no QA needed) |

In a monorepo, first split the ledger by top-level scope (e.g. `api/` vs `app/`),
then classify within each. In a single-scope repo, skip the split.

Present the ledger (file → domains) before proceeding.

### Step 3: Analyze — inline or via specialists

Pick the cheapest sufficient mode:

- **Inline** (default for small diffs: roughly ≤5 files or 1–2 domains): analyze
  the hunks directly, producing the per-file outputs below yourself.
- **Specialist dispatch** (large or multi-domain diffs, or any monorepo full-stack
  change): launch one subagent per populated domain group **in parallel**, each
  receiving its files' hunks (`git diff <range> -- <paths>`). Skip specialists with
  no files.

Every analysis (inline or specialist) must return, per file:

1. **Behavior change in plain English**
2. **Where it applies** (endpoint / screen / flow / job / table)
3. **Concrete QA checks** — executable checklist items (≥2 per file; 1 is enough
   for TEST/CONFIG/DOCS files)
4. **What is NOT impacted**
5. **Risk triggers** observed (for Step 5)

Domain-specific focus:

- **BE:** request validation, response/contract shape, error paths, side effects
  (jobs/events), idempotency, cross-module dependencies.
- **DB:** schema risks (types, nullability, defaults, FKs, indexes), data-migration
  safety, backward compatibility, rollback safety.
- **AUTH:** every changed endpoint/screen gets at least one **allowed** and one
  **denied** case; feature-flag on AND off; tenant/organization scoping.
- **UI:** permission/flag gating, form validation and error states,
  loading/empty/error states, dialog flows, shared-component consumers, responsive
  behavior, the longest locale if i18n exists.
- **STATE / API-CLIENT:** contract changes, state shape changes, which components
  consume the changed pieces, error handling.
- **CONFIG:** required setup changes, default-behavior validation,
  misconfiguration scenarios.

**Client-facing UI on a Highway property:** if the diff touches footers,
fixed/sticky overlays, toasts, banners, chatbot embeds, or `100dvh` math, fold the
Verification checklist from `highway-client-facing-styleguide` into the QA
checklist (reserved corner, phantom-scrollbar check, widths × longest locale).

### Step 4: Coverage audit

Compare the canonical ledger against the analysis output:

- Every file has a behavior summary and the required number of checks.
- No vague coverage ("test that it works" tied to nothing).
- Gaps → targeted follow-up on the specific files, then re-audit.
- Proceed to synthesis only at 100%.

### Step 5: Risk classification

Severity is a **QA routing decision**, not just a label: most pipelines have
several safety nets after dev testing (QA env → staging → regression — adapt to
the project's actual stages). **Low = safe to skip dedicated QA-env testing**;
staging/regression would catch a miss and worst-case impact is small. Aim for
~7/10 strictness — lean Low for straightforward, well-understood changes; reserve
Medium/High for changes where a missed bug is user-visible or hard to catch later.
Assess the **whole ticket scope combined**, not each side in isolation.

**5a — classify the nature of the change first:**

1. **Additive-only** (new props/params/interfaces, no existing logic modified) → **Low**
2. **Import/path moves** (same interface, consumers updated mechanically) → **Low**
3. **1:1 rewrites** (refactor with identical behavior) → **Low** for small isolated
   units; **Medium** for complex ones (timers, polling, async orchestration,
   multi-step flows) or whole pages
4. **Behavioral changes** → apply the triggers below

**5b — triggers (for categories 3-complex and 4):**

- **High** if ANY: DB migration (especially destructive); auth/permission or
  feature-flag changes; new feature with new UI + new endpoints; shared component
  **replaced with a different implementation**; financial/payment flows; API
  contract change with multiple consumers; external integration changes; config
  changes affecting runtime behavior.
- **Medium** if ANY: full-stack behavioral change; complex-component or page-level
  rewrite; shared service/repository interface changed; API type restructuring;
  multi-domain behavioral impact.
- **Low**: isolated small rewrites, additive changes, moves, test/config/docs-only,
  cosmetic changes, type-only improvements, dead-code removal, small contained
  bug fixes.

### Step 6: Synthesize the handoff

Deduplicate checks, group by flow/feature area, include only sections relevant to
the detected scope, and output in this structure:

```markdown
# QA Handoff — Auto Generated (from diff)

**Branch / Base / Scope / Files changed / Generated:** …

## What Changed (plain English)
## Where This Applies            ← per scope: endpoints, screens, jobs, tables, flags
## QA Checklist (do these)       ← grouped by flow; concrete, executable items
## What is NOT Impacted (safe to skip)
## Risk Level: Low | Medium | High   ← justification tied to diff triggers
## Dev Verification              ← pre-QA checks the developer confirms
## Regression Hotspots (top 5)
## Coverage Proof                ← table: file | domain(s) | covered — N/N
```

### Step 7: Publish (project-dependent, optional)

If the project has a tracker integration available (e.g. Linear or Jira MCP):

- Extract the ticket key from the branch name using the project's pattern; ask if
  no match.
- Post the handoff (or a link to it, if the project uses a dedicated test-plan
  tool) as a ticket comment, with the risk level stated up front, and set any
  severity/test-plan fields the project's workflow defines.
- On re-runs, update the existing plan/comment and call out what changed,
  including any severity change (old → new).

If no integration is available, deliver the document itself as the output.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The PR description already explains it" | Descriptions drift from code. The diff is the truth; the ledger proves nothing was skipped. |
| "QA will figure out what to test" | Unscoped testing wastes QA on safe areas and misses risky ones. The handoff is the routing. |
| "Too small to need a handoff" | Small diffs take one inline pass and still produce the risk call that lets QA skip a whole env stage. |
| "Everything feels Medium" | Medium-by-default defeats routing. Classify the change's nature first; commit to Low when the triggers say so. |

## Red Flags

- A changed file absent from the coverage table
- Checklist items that name no route, screen, command, or expected result
- Risk level with no trigger from the diff behind it
- AUTH-domain changes without a denied-case check
- Handoff not regenerated after significant new commits

## Verification

- [ ] Coverage proof shows N/N files, matching `git diff --name-status` exactly
- [ ] Every checklist item names a concrete location, action, and expected result
- [ ] "What is NOT impacted" is present and specific
- [ ] Risk level cites at least one trigger (or a change-nature category) from the diff
- [ ] Scope sections match reality (no empty BE section in an FE-only repo)
