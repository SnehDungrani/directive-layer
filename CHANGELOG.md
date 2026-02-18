# Changelog — Directive

All notable changes to **Directive** are documented here.

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
