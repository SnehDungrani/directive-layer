# Changelog — Directive

All notable changes to **Directive** are documented here.

---

## [1.3.0] — 2026-02-19

### SKILL.md and templates overhaul

- Updated `SKILL.md` from a “always apply all 8 techniques” template to an **intent- and complexity-aware protocol**:
  - Added **Step 0 (Intent Classification)** with 7 query types.
  - Added **Step 0.5 (Input Cleanup)**, including a generic rule for resolving ambiguous typos (edit distance first, then popularity/recognition, never silently guessing a name).
  - Added **Step 1 (Complexity Assessment)** with Lightweight / Standard / Deep tiers, and special handling for **framework / guide / methodology** requests.
  - Introduced a **Technique Routing Table** so only relevant techniques run per query type.
  - Enforced a global **“no raw XML/HTML tags in IDE/chat”** rule; tags are allowed only internally or in API contexts.
  - Treated the **refined prompt as internal** (never shown to the user); only `Directive applied`, a dashed line, and the final answer are visible.
  - Added detailed guidance for framework/guide outputs (required sections, implementation options, pitfalls, summary/checklist) and a task-specific validation check for them.
  - Expanded the **Before/After examples** to cover factual, conversational, analytical (standard and deep), generative, code, and multi-step queries.

- Synced all IDE templates with the new skill:
  - `templates/cursor-rules.md` now matches the updated `SKILL.md` content.
  - Other templates (`GEMINI-patch.md`, `windsurf-rules.md`, `vscode-copilot-instructions.md`) remain compatible with the new behavior.

### README clarification

- Rewrote the **What Is This?** section to clearly explain Directive is a **behavior layer**, not a pre-processor.
- Updated **Architecture** section: now explicitly lists what Directive does and does not change.
- Replaced the flow diagram with a clearer 3-box representation showing what gets sent to the model, what happens inside, and what you see.
- Updated technique descriptions to reflect that tags/reasoning are internal only — you see clean markdown output.
- Bumped version to 1.3.

### Notes

- Existing global installs can be updated by re-running `install.ps1` / `install.sh`, or by copying the new `templates/cursor-rules.md` content into the Cursor skill UI.

---

## [1.2.0] — 2026-02-18

### Current release

**Directive** is a global prompt refinement layer that applies 8 engineering-grade techniques before every AI response.

**Supported IDEs (one-command install):**
- Antigravity (Google Gemini) — `~/.gemini/GEMINI.md`
- Cursor — `~/.cursor/skills/directive/SKILL.md` (use `/directive` in chat)
- Windsurf — global rules in config folder
- VS Code + GitHub Copilot — `prompts/directive.instructions.md`

**Included:**
- `SKILL.md` — skill definition (source of truth)
- `install.ps1` / `install.sh` — global installer; validates `SKILL.md` exists
- `templates/` — GEMINI-patch, cursor-rules, windsurf-rules, vscode-copilot-instructions
- `docs/IDE-PATHS.md` — IDE paths reference

**How to update:**
1. Edit `SKILL.md` in the repo root.
2. Run `install.ps1` (Windows) or `install.sh` (Mac/Linux).
3. Add an entry here with version and date; bump version as needed.

---

*Format based on [Keep a Changelog](https://keepachangelog.com/)*
