---
name: feature-init
description: Scaffold a new feature folder under projects/. Creates projects/master/ (once) and projects/YYYYMMDD-feature-name/ from the template. Use when starting work on a new feature.
---

# Feature Init

Scaffolds a new feature workspace and guides the user through requirements, config, and kickoff interactively. One command -- no manual file editing required.

**Sequence:** Requirements Kickoff → Scaffold → Phase Config → Kick off

---

## Step 0: Requirements Kickoff

Open with: "Let me gather details about what you'd like to build today."

Use `AskUserQuestion` (single-select) to ask how the user wants to start:

- **Describe it now** -- you'll interview me
- **I have requirements text** -- I'll paste them
- **I have a full PRD** -- I'll paste it or give a file path

### Path A: Describe it now

Invoke the `senior-product-manager` agent with this instruction:

> "Run a short requirements interview with the user. Ask one question at a time. When you have enough context, produce: (1) a one-paragraph summary, (2) 3-5 key points, (3) a suggested 2-3 word kebab-case slug for the feature folder (e.g. `user-auth-flow`). Do not write a full PRD -- requirements summary only."

Wait for PM agent to complete. Extract the slug suggestion from its output.

### Path B: I have requirements text

Ask the user to paste their requirements. Then invoke `senior-product-manager` with:

> "The user has provided the following requirements: [paste]. Refine them into: (1) a one-paragraph summary, (2) 3-5 key points, (3) a suggested 2-3 word kebab-case slug. Requirements summary only -- no full PRD."

Extract the slug suggestion.

### Path C: I have a full PRD

Ask the user to paste the PRD content or provide a file path. If a file path is given, read the file. Derive a 2-3 word kebab-case slug from the PRD title or first heading. No PM agent invocation needed.

### Confirm the slug

After any path, present the slug suggestion to the user using `AskUserQuestion`:

> "I'll name the feature folder `YYYYMMDD-[slug]` (today's date will be prepended). Does this look right?"

Options: "Yes, use this name" / "Edit it" (user types a different slug via Other).

Hold the confirmed slug and requirements summary in context -- they are written to `prd.md` after the scaffold in Step 1.

---

## Step 1: Scaffold

Run `bash .claude/skills/feature-init/feature-init.sh YYYYMMDD-[confirmed-slug]` using Bash. IMPORTANT: always use this relative path exactly -- never expand it to an absolute path. Substitute today's date (YYYYMMDD) and the confirmed slug.

Show the user the folder tree from the script output. Extract the feature folder path from the output (format: `projects/YYYYMMDD-feature-name`) -- you will need it in every subsequent step.

**Write requirements to `prd.md`:**

- **Paths A or B:** Write the requirements frontmatter block to `[feature-folder]/product-specs/prd.md`:

  ```
  ---
  requirements:
    summary: <one paragraph from PM output>
    key_points:
      - <bullet>
      - <bullet>
    additional_context: none
    gathered_by: orchestrator-inline
  ---
  ```

- **Path C (full PRD provided):** Write the full PRD content directly to `[feature-folder]/product-specs/prd.md` (no frontmatter wrapper).

Then invoke `/my-git-commit` automatically without asking. Commit subject: `"Scaffold [feature-name] feature folder"` where `[feature-name]` is the `YYYYMMDD-feature-name` portion of the folder path.

---

## Step 2: Phase Config

Read `[feature-folder]/workflow/feature-setup.md` to extract all stages and their `👤` gate lines.

Identify skippable stages: all stages currently marked `[ ]` except Stages 6, 7, and 8 (those are locked and always active).

**2a. Stage selection**

Use `AskUserQuestion` (multi-select):

> "Which stages would you like to skip? Stages 6, 7, and 8 are always included."

Options: one per skippable stage, using its stage label (e.g. "Stage 1: Discovery"). If there are more than 4 skippable stages, split into two sequential questions covering the full list. If the user selects nothing, all stages remain active.

**2b. Deployment target**

Use `AskUserQuestion` (single-select):

> "What is your deployment target?"

Options: **Local** / **AWS** / **Other** (user types custom value via Other).

**2c. Gate-level config (conditional)**

If any active stage has two or more `👤` checkpoint lines, use `AskUserQuestion` (multi-select) to ask which individual gates to skip:

> "Are there any specific review gates you want to skip?"

Options: one per `👤` checkpoint across all active stages, labelled in plain English (strip "HUMAN:", e.g. "Review and approve the PRD"). If every active stage has at most one gate, skip this question.

**Apply the selections**

Update `[feature-folder]/workflow/feature-setup.md`:
- For each skipped stage: change its `[ ]` to `[-]`
- For each skipped gate: find the matching `👤` step line within its stage and change its `[ ]` to `[-]`
- Replace the `local` default in the `## Deployment target` block with the user's choice

Print a plain-language summary with consistent alignment:

1. Collect every label that will appear: stage names (e.g. `Stage 1: Discovery`) and checkpoint labels (e.g. `    👤 Review and approve the PRD`). The checkpoint prefix `    👤 ` counts toward the label width.
2. Find `max_label_width` = the length of the longest label.
3. For each line, pad the label to `max_label_width` with spaces, then append the status badge.
4. Print a blank line after each stage block (after its last checkpoint row, or after the stage line itself if it has no checkpoints).

Example with correct alignment (labels padded to a common column):

```
Phases configured:
- Stage 1: Discovery                            [ active ]
    👤 Review and approve the PRD               [ active ]

- Stage 2: Design                               [ active ]
    👤 Review and approve mocks                 [ active ]

- Stage 3: Technical Planning                   [ active ]
    👤 Review and approve system architecture   [ skipped ]
    👤 Review and approve high-level design     [ skipped ]
    👤 Review and approve implementation plan   [ skipped ]

- Stage 4: Engineering                          [ active ]
    👤 Review and approve deployment plan       [ skipped ]

Deployment target: local
```

Use `[ active ]` for `[ ]` items and `[ skipped ]` for `[-]` items. Only show checkpoint rows for active stages.

Then ask: "Does this look right before we continue?" with options "Yes, continue" and "No, reconfigure". If reconfigure, repeat from 2a until the user confirms.

---

## Step 3: Kick off

Ask the user: "Config and requirements are ready. Ready to kick off?" Offer "Yes, proceed" and "Not yet".

If yes: read `.claude/template/kickoff-prompt.md`, replace every occurrence of `[YYYYMMDD-feature-name]` with the actual feature folder path (e.g. `projects/20260420-my-feature`), then execute the resulting prompt as if the user had sent it. The kickoff prompt handles everything from here.
