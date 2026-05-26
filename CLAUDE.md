# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of reusable Claude Code agent definitions for a software engineering team. There is no application code here. The repo contains only agent definitions, domain skills, session rules, and project scaffolding templates.

Consumers install this repo into their own project via `install.sh`. They do not fork or modify this repo; they pull it as a versioned dependency and commit the result.

## How consumers use it

1. Run `install.sh` to copy `.claude/agents/`, `.claude/rules/`, `.claude/skills/`, `.claude/template/`, `.claude/SETUP-GUIDE.md`, and `.claude/tech-config.md` into their project.
2. Run `/feature-init` in Claude Code (handles everything: requirements gathering via PM agent, folder scaffolding, phase config, and kickoff). No manual file editing required.

## Folder structure and the reasoning behind it

```
.claude/
├── agents/           -- agent role definitions (auto-loaded by Claude Code)
├── rules/            -- session rules (auto-loaded by Claude Code)
├── skills/           -- domain knowledge packs referenced by agents
├── template/
│   ├── feature/      -- scaffolding copied per feature into projects/YYYYMMDD-name/
│   │   ├── generated-docs/design/        -- Designer output (mocks, diagrams)
│   │   ├── generated-docs/architecture/  -- sys-arch, HLD
│   │   ├── generated-docs/contracts/     -- API contract
│   │   ├── generated-docs/qa/            -- test plan
│   │   ├── product-specs/prd.md          -- PM input (feature PRD)
│   │   └── workflow/                     -- delivery config and plans
│   ├── master/       -- copied once to projects/master/ (shared product baseline)
│   │   ├── product-specs/prd.md    -- full PRD merged across all shipped features
│   │   └── mocks/                  -- current UI mocks reflecting live product
│   └── kickoff-prompt.md                  -- kickoff prompt (stays at template root, not copied per feature)
├── SETUP-GUIDE.md
└── tech-config.md           -- stack/conventions consumers tailor once after install
projects/             -- per-feature scaffolding and product specs (managed by /feature-init)
src/                  -- all production artifacts: source code, db schema, migrations, seeds, IaC
```

Key distinctions:
- `product-specs/` is PM input (what to build). `generated-docs/` is Designer output (what was produced). Never mix them.
- `template/feature/` contains things that become part of a feature folder. Kickoff files are one-time prompts, so they stay at `template/` root.
- `master/` is a shared baseline, not per-feature. It mirrors the `feature/` structure (product-specs, mocks) but is copied once, not per feature.
- `generated-docs/` is organized by concern: `design/` (mocks), `architecture/` (sys-arch, HLD), `contracts/` (API contract), `qa/` (test plan).
- `src/` is a sibling to `.claude/`, `projects/`, and `scripts/` at the consumer project root. All production artifacts go here (source code, db schema, migrations, seeds, IaC). Agent-generated design docs go under `generated-docs/`, never under `src/`.

## Rules

Rules in `.claude/rules/` are loaded automatically. Key ones to know:
- `contract-first-rule.md`: no downstream work until upstream artifact is approved. Strict sequencing.
- `product-baseline-rule.md`: `projects/master/` must stay current. PM and Designer are blocked from starting new features until it is.
- `backlog-reporting-rule.md`: agents append discovered bugs/debt to `BACKLOG.md` in the repo root. Never self-assign priority.
- `progress-tracking-rule.md`: `delivery-tracker.md` is the single source of truth for human gates and phase progress; agents check off steps directly and resume from it after interruption.
- `delegation-rule.md`: when a step names a specific role, the orchestrator must delegate to that agent, never self-execute on its behalf.
- `workflow-phases-rule.md`: all multi-step work must be structured as phased workflows with numbered steps and expected artifacts.
- `artifact-review-rule.md`: at every human-gate artifact, output the full MD content in the response and use `AskUserQuestion` with Approve / Request changes.
- `artifact-paths-rule.md`: all artifact paths must be resolved from the File locations table in `tech-config.md`, never hardcoded.
- `db-schema-change-rule.md`: every schema change requires a versioned migration file and updated ER diagram in the same commit.

## What NOT to do

- Do not add application code, project-specific content, or anything that assumes a particular consumer project.
- Do not create new folders without understanding where they fit in the input/output separation (product-specs vs generated-docs, feature vs master).
- Do not rename or restructure without grepping the full repo for references and updating all of them.
- Do not commit without the user explicitly asking.

## Writing style

Never use em dashes, en dashes, or double hyphens (`--`) in prose: responses, design documents, skill files, rule files, agent files, or any other written output. Use parentheses or restructure the sentence instead. This prohibition does not apply to `--` used as a technical separator inside code blocks (e.g. directory tree annotations, shell flags).

## Agent conventions

Each agent file follows this section order:
1. Frontmatter (`name`, `description`, optional `skills`) (all agents include `collaboration-contracts` skill)
2. One-line identity (`You are a senior X.`)
3. `## Qualities`: intro line, mindset, and role-specific quality bullets
4. `## Collaboration`: who this role works with and how (behavioral only; no artifact names)
5. `## Ownership`: what this role owns end-to-end
6. `## Decision-making`: how this role makes and escalates decisions
7. `## Communication`: how this role communicates blockers, reviews, and handoffs
8. `## Hard constraints`: opens with a blockquote delegating all artifact flows to the `collaboration-contracts` skill, followed by role-specific operational rules only (security, code quality, craft standards); never re-list artifact dependencies or approval gates here
9. `## Commit conventions`: role-specific commit rules

Collaboration contracts (depends-on, produces, gatekeeps) live exclusively in `.claude/skills/collaboration-contracts/SKILL.md`, organized by pair (e.g. EM<>QA). Do not duplicate artifact flows in individual agent files. The delegation blockquote in `## Hard constraints` is the only cross-reference agents need.

## Skill naming

Skills are resolved by the `name` field in their frontmatter, not by folder path. Skill names must be unique. Agents list skills in their `skills:` frontmatter. Commit conventions live in each agent file, not in a separate skill.

## Contributing

See `CONTRIBUTING.md` for how to add or update skills and agents. For adding a new agent, always use the `create-new-agent` skill -- it enforces the mandatory structural verification checklist.

## Install script

```bash
bash install.sh          # pull from main
bash install.sh v1.0.0   # pin a tag or branch
```

Copies `.claude/agents/`, `.claude/rules/`, `.claude/skills/`, `.claude/template/`, `.claude/SETUP-GUIDE.md`, and `.claude/tech-config.md` into the consumer project. Also scaffolds `BACKLOG.md` in the consumer root if it doesn't exist. Consumers commit the result to lock the version.

## Structural change verification (mandatory)

This triggers automatically on every structural change. The user must never need to ask. Do not skip it. Do not substitute a confidence claim for the grep output.

### What counts as a structural change

- Adding, renaming, deleting, or moving an agent file in `.claude/agents/`
- Adding, renaming, deleting, or moving a skill folder in `.claude/skills/`
- Adding, renaming, deleting, or moving a rule file in `.claude/rules/`
- Renaming or relocating an artifact path (e.g. `fe-detailed-design.md`)
- Adding, renaming, or deleting a template file in `.claude/template/`
- Introducing a new role name, artifact type, or convention referenced elsewhere

If unsure whether a change qualifies, run the checklist anyway.

### Checklist

1. **Enumerate all terms to verify.** For each new/renamed/deleted thing, list every form it might be referenced as:
   - Technical identifier (e.g. `senior-macos-designer`, `macos-hig`)
   - File name (e.g. `senior-macos-designer.md`)
   - Human-readable form (e.g. `macOS Designer`, `Mac designer`)
   - Role abbreviation if any (e.g. `BE`, `FE`, `Swift Engineer`)
   - For renames/deletes: also list every form of the OLD name
2. **Pick 2-3 baselines of the same type.** Use multiple to avoid matching a minimal baseline:
   - New skill: e.g. `prd-craft`, `fe-testing`, `react-typescript`
   - New agent: e.g. `senior-frontend-engineer`, `senior-backend-engineer`, `senior-ux-ui-designer`
   - New rule: e.g. `contract-first-rule`, `progress-tracking-rule`, `delegation-rule`
   - If no existing equivalent exists: grep for the new name alone and reason about every hit; document the lack of baseline in the response
3. **Grep from the repo root, no filters.**
   - Run `cd <repo-root>` first (the directory containing `CLAUDE.md` and the `.claude/` folder)
   - Run `grep -irn "<term>" .` for every term from step 1, and for every baseline term from step 2
   - NEVER pipe through `grep -v` to exclude folders. NEVER skip a directory because "it's probably domain-specific." Every hit gets evaluated, not filtered.
4. **Compare locations.**
   - For ADDS: every location any baseline appears is a candidate the new name must also appear (or have a deliberate reason not to)
   - For RENAMES: every location the old name appears must be updated to the new name (or deliberately retained for compatibility)
   - For DELETES: every location the old name appears must be removed or updated to a replacement
5. **Fix all gaps.** Edit each file individually. Do not batch.
6. **Show the evidence.** Before saying done, paste the full final `grep -irn "<new-name>" .` output (and `grep -irn "<old-name>" .` for renames/deletes, which should be empty or deliberately retained). The user reads the output and confirms.
