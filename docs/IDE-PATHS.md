# IDE paths (for global Directive install)

Research for "how to add skill.md in [IDE]" — where each IDE stores global rules/skills so we can install without copy-paste.

| IDE | Global path we use | Source |
|-----|--------------------|--------|
| **Antigravity** | `~/.gemini/GEMINI.md` (append block) | Antigravity docs |
| **Cursor** | `~/.cursor/skills/<name>/SKILL.md` | User found `C:\Users\<you>\.cursor\skills`; same layout as code-simplifier |
| **Windsurf** | `~/.codeium/windsurf/memories/global_rules.md`, `%APPDATA%\Windsurf\User\global_rules.md` | Community docs, RuleSurf |
| **VS Code Copilot** | `%APPDATA%\Code\User\prompts\*.instructions.md` (user profile); `applyTo: '**'` for all chats | [VS Code custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions) |
So we auto-install to: Antigravity, Cursor, Windsurf, VS Code Copilot.
