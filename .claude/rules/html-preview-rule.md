# Rule: HTML Preview for Human-Gate Artifacts

Every time an agent writes **or updates** any of the following artifacts, it must immediately generate a co-located HTML preview using pandoc:

| Artifact | Path |
|---|---|
| PRD | `[feature-folder]/product-specs/prd.md` |
| Kickoff Plan | `[feature-folder]/workflow/kickoff-plan.md` |
| System Architecture | `[feature-folder]/generated-docs/architecture/sys-arch.md` |
| High-Level Design | `[feature-folder]/generated-docs/architecture/hld.md` |
| BE Detailed Design | `[feature-folder]/generated-docs/architecture/be-detailed-design.md` |
| FE Detailed Design | `[feature-folder]/generated-docs/architecture/fe-detailed-design.md` |
| API Contract | `[feature-folder]/generated-docs/contracts/api-contract.md` |
| Deployment Plan | `[feature-folder]/generated-docs/architecture/deployment-plan.md` |
| Test Plan | `[feature-folder]/generated-docs/qa/test-plan.md` |

The HTML file lives in the same folder as the MD, with the same base name (e.g. `prd.md` → `prd.html`).

## Pandoc command

```bash
CSS='body{max-width:800px;margin:2rem auto;padding:0 1rem;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;font-size:16px;line-height:1.6;color:#24292e}h1,h2,h3{border-bottom:1px solid #eaecef;padding-bottom:.3em;margin-top:1.5em}a{color:#0366d6}code{background:#f6f8fa;padding:.2em .4em;border-radius:3px;font-size:85%}pre{background:#f6f8fa;padding:16px;border-radius:6px;overflow:auto}pre code{background:none;padding:0}blockquote{padding:0 1em;color:#6a737d;border-left:.25em solid #dfe2e5;margin:0 0 16px}table{border-collapse:collapse;width:100%}td,th{border:1px solid #dfe2e5;padding:6px 13px}tr:nth-child(2n){background:#f6f8fa}img{max-width:100%}'

pandoc "$MD_FILE" -f gfm -o "$HTML_FILE" --standalone \
  --metadata title="$(basename "$MD_FILE" .md)" \
  --variable "header-includes=<style>${CSS}</style>"
```

Substitute `$MD_FILE` and `$HTML_FILE` with the actual paths. Run this as a single Bash call immediately after writing the MD.

## Markdown writing rules for correct HTML rendering

**Always insert a blank line before a pipe table.** GFM requires it; without it the table collapses into a paragraph in the HTML output.

```markdown
Existing stack confirmed from `src/`:

| Layer | Technology |
|-------|------------|
```

Not:

```markdown
Existing stack confirmed from `src/`:
| Layer | Technology |
|-------|------------|
```

**Task list items (`- [ ]`, `- [x]`) render correctly** only when `-f gfm` is passed to pandoc (already included in the command above).

## If pandoc is not installed

Check first:

```bash
command -v pandoc >/dev/null 2>&1 || echo "PANDOC_MISSING"
```

If pandoc is missing: print one line -- `Note: pandoc not found -- HTML preview skipped for [filename].md` -- and continue. Do not block or stop work.

## At human review gates

When a 👤 gate is reached for one of these artifacts, use `AskUserQuestion` (single-select) instead of a plain-text prompt:

> "[artifact name] is ready for your review."

Options:
- **Open in browser** -- run the OS-appropriate command to open the `.html` file, then wait for the human to return and confirm
- **I'll review in terminal** -- proceed to the approval prompt directly

OS commands for opening:
- macOS: `open [file].html`
- Linux: `xdg-open [file].html`
- Windows: `start [file].html`

After the human has reviewed (via either path), ask for approval as normal: "Do you approve?" with **Approve** and **Request changes** options. Do not proceed until approved.
