# AGENTS.md — agent-rules-books

This file orients AI coding agents to the repository structure, conventions, and workflows.

## Project overview

`agent-rules-books` is a library of AI-coding-agent rule sets distilled from classic software-engineering books. It contains no application code, no build artifacts, and no runtime dependencies. The entire repository is plain Markdown.

Each of the 14 books is released in three tool-agnostic versions:

- `full` — canonical complete reference (`<book>/<book>.md`)
- `mini` — recommended compressed skill body (`<book>/<book>.mini.md`)
- `nano` — compact fallback for tight context budgets (`<book>/<book>.nano.md`)

The repository also maintains a compatibility matrix (`docs/COMPATIBILITY.md`) that maps which book rule sets can safely be loaded together as active agent guidance.

## Technology stack

- **Format**: Markdown only.
- **Build system**: None. There is no `package.json`, `pyproject.toml`, `Cargo.toml`, `Makefile`, or equivalent.
- **Runtime**: None. This is a static content repository.
- **Dependencies**: None.
- **Version control**: Git. The `.gitignore` excludes `_sources/`, `TODO.md`, `books/`, `_rule-workbench/_resources/books/`, and `.DS_Store`.

## Directory layout

```text
<book-name>/                          # one directory per book, lowercase kebab-case
  <book-name>.md                      # canonical full rule set
  <book-name>.mini.md                 # released mini compression
  <book-name>.nano.md                 # released nano compression

docs/
  USAGE.md                            # editor-specific usage patterns (Codex, Claude Code, Cursor)
  COMPATIBILITY.md                    # 14×14 compatibility matrix with linked verdicts
  CRITICISM.md                        # consolidated Reddit criticism and responses
  ADDING_THE_BOOK.md                  # workflow for adding a new book rule set
  compatibility/
    <book-a>/
      <book-b>.md                     # one detailed comparison per unordered pair (91 total)

_rule-workbench/
  PROCESS.md                          # compression rules for creating mini and nano
  RELEASE.md                          # release steps and metric conventions
  CHECK_COMPATIBILITY.md              # instructions for creating pairwise compatibility files
  <book-name>/
    full.md                           # symlink or relative path to canonical full source
    mini.md                           # workbench copy of mini (source of release)
    nano.md                           # workbench copy of nano (source of release)
    traceability.md                   # mapping from compressed rules back to full source
```

## Conventions

### File and directory naming

- Book directories use **lowercase kebab-case**.
- Released files follow `<book-name>/<book-name>.{md,mini.md,nano.md}`.

### Heading format

Every rule file must use exactly one first-level heading:

```markdown
# OBEY {book name} by {author name}
```

If the source has no clear author, omit the `by` clause:

```markdown
# OBEY {source name}
```

This applies to canonical full files, workbench files, and released mini/nano files. Do **not** add version labels such as `Mini`, `Nano`, or `Traceability` to the H1.

### Rule classification (used during compression)

When editing or creating compressed rule sets, classify rules before deciding what to keep:

- `default` — target agents already follow this reliably; keep only with evidence
- `book-thesis` — the book's central corrective bias or distinctive point of view
- `decision-changing` — changes architecture, modeling, persistence, error handling, or refactoring decisions
- `micro-decision` — changes repeated local implementation choices (naming, function shape, boundaries, etc.)
- `conflict-resolver` — resolves tradeoffs between competing pressures
- `trigger` — activates only when touching a risky area
- `checklist-only` — useful as a final scan, too weak as a main rule
- `framing` — useful context, not an operational rule

### Compression output shape

`mini.md` and `nano.md` must follow this structure:

1. Required `# OBEY ...` title
2. `When to use`
3. `Primary bias to correct`
4. `Decision rules`
5. `Trigger rules`
6. `Final checklist`

### Traceability requirements

- Every retained rule in `mini.md` gets an `M*` id in `traceability.md`.
- Every retained rule in `nano.md` gets an `N*` id in `traceability.md`.
- Each id must reference source section names and current line ranges in the canonical full file.
- Intentional omissions must be recorded as `covered by Mx`, `covered by Nx`, or `intentionally lost`.

## Build and release process

There is no automated build. Releases are manual and governed by `_rule-workbench/RELEASE.md`.

### Adding a new book

Follow `docs/ADDING_THE_BOOK.md`:

1. Generate the full `AGENTS.md`-style rule set from the book.
2. Move the approved file to `<book-name>/<book-name>.md`.
3. Run the compression workflow from `_rule-workbench/PROCESS.md`.
4. Run the release instructions from `_rule-workbench/RELEASE.md`.

### Releasing compressed versions

For each book:

1. Validate that the workbench contains `full.md`, `traceability.md`, `mini.md`, and `nano.md`.
2. Ensure `full.md` still resolves to the canonical source.
3. Copy `_rule-workbench/<book>/mini.md` to `<book>/<book>.mini.md`.
4. Copy `_rule-workbench/<book>/nano.md` to `<book>/<book>.nano.md`.
5. Update `README.md` release matrix with deterministic metrics.

### Metric conventions

Use deterministic tooling so metrics stay reproducible:

- **Lines**: physical line count (`wc -l`)
- **Size**: raw bytes (`wc -c`)
- **Rules**: count Markdown list items (`- ` and `1.`) that represent actionable instructions; exclude headings, blank lines, prose paragraphs, code fences, and table rows

## Testing and validation

There are no automated test suites. Quality assurance is manual and process-driven.

### Validation checklist (from `_rule-workbench/PROCESS.md`)

Before considering a book done:

- All H1 headings follow the `# OBEY ...` format without version labels.
- The canonical full source is untouched.
- Each retained rule changes a real agent decision, repeated local choice, or blocks a known failure mode.
- Each omitted section or rule has a traceable disposition.
- Duplicate guidance is merged.
- Long lists are collapsed into triggers or checklist items.
- `nano.md` can stand alone as a compact always-on fallback.
- `mini.md` adds clear value beyond `nano.md`.
- The book's central thesis is still recognizable without reading the title.
- A full-to-mini gap review has been completed section by section.
- `traceability.md` explains why anything important was removed or merged.

### Compatibility verification

When updating compatibility files, follow `_rule-workbench/CHECK_COMPATIBILITY.md`:

- Use canonical `mini` files as primary evidence.
- Create exactly one file per unordered pair under `docs/compatibility/<earlier-slug>/<later-slug>.md`.
- Each file must include `Status`, `Research basis`, `Verdict`, `Conflict`, `Overlap`, `Complementarity`, claim-level evidence with line ranges, and `Source Basis`.
- The matrix in `docs/COMPATIBILITY.md` must stay in sync with the detailed files.

## Security considerations

- This repository contains only text and one PNG image (`books-ai-rules.png`). There are no executables, secrets, or sensitive data.
- All content is released under the MIT License (`LICENSE`).
- The repository intentionally does not reproduce book text; it contains original practical instructions inspired by the books.
- Do not add copyrighted source material, full book excerpts, or publisher PDFs.
- The `.gitignore` excludes local working directories (`_sources/`, `books/`, `_rule-workbench/_resources/books/`) that may contain copyrighted reference material.

## Editing guidelines

- Do not edit `full.md` in the workbench; edit the canonical source in the book directory.
- Do not patch one book in isolation when a finding is a recurring compression mistake; update `_rule-workbench/PROCESS.md` first, then re-run affected books.
- Do not import guidance from a different book during compression just because it would improve the output. Compression is source-faithful, not best-practice aggregation.
- Keep book-specific biases visible. Compression must not turn all books into the same generic style guide.
- Prefer short operational rules over explanatory prose in compressed versions.
- Use the removal test: if deleting a rule is likely to bring back a known bad habit, keep it.

## Communication

- The project README (`README.md`) is human-facing marketing and quick-start documentation.
- This `AGENTS.md` is agent-facing operational context.
- When both files exist, agents should treat `AGENTS.md` as the authoritative source for project conventions and workflows.
