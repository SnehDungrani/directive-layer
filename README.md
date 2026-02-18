# ⚡ Directive — global prompt protocol

> **A global prompt control layer that prepends engineering constraints before inference.**

---

## What Is This?

**Directive** is a prompt control layer that standardizes inputs before they reach the inference model. It operates as an always-on middleware within the IDE, establishing a baseline engineering protocol to reduce ambiguity and enforce output structure.

The system is model-agnostic and designed for infrastructure-level consistency.

**Mission:** Shift prompt engineering from a user-time cognitive load to a system-time architectural guarantee.

---

## Architecture

Directive functions as a **System Prompt Injection Layer**. It does not intercept network traffic or act as a binary middleware. Instead, it leverages the `system` or `pre-prompt` capabilities of your AI tool to prepend a structured engineering protocol to the context window.

When a prompt is submitted:
1.  **Context Loading**: The AI tool reads the `SKILL.md` content via its configured system prompt file (e.g., `GEMINI.md`, `~/.cursor/skills/directive/SKILL.md`, `rules.md`).
2.  **Instruction Injection**: The Directive protocol is inserted into the context window *before* the user's prompt.
3.  **In-Context Learning**: The LLM adheres to the injected protocol to process the subsequent user input.
4.  **Structured Generation**: The model generates a response that follows the 8-step engineering format defined in the protocol.

This ensures that every query is processed through a rigorous engineering framework without requiring a proxy server or browser extension.

## Flow Architecture

The following diagram illustrates the injection process:

```
[System Context]
   └── Injected: DIRECTIVE_PROTOCOL (from SKILL.md)
       ├── Engineering Constraints
       ├── Output Format (XML)
       └── Validation Loop

[User Input]
   └── "Write a Python script to..."

[LLM Context Window]
   ├── [System] DIRECTIVE_PROTOCOL
   ├── [User] Original Prompt
   └── [Assistant] "Directive applied" (Verification Signal)
       └── [Assistant] <thinking> ... </thinking>
       └── [Assistant] <answer> ... </answer>
```

---

## Injection Protocol

The skill enforces the following constraints via in-context instructions (defined in [`SKILL.md`](./SKILL.md)):

| Technique | Implementation | Guarantee |
| :--- | :--- | :--- |
| **Negative Constraints** | `system` instructions forbidding specific patterns. | Reduces hallucination by explicitly defining out-of-bounds behavior. |
| **Chain of Thought** | Mandatory `<thinking>` tags in output schema. | Exposes logic errors in the reasoning trace before the final answer is committed. |
| **Structured Output** | XML-delimited response format (`<answer>`, `<code>`). | Ensures outputs are machine-parseable and consistent across different models. |
| **Reasoning Wrappers** | `INPUT` → `REASONING` → `OUTPUT` few-shot examples. | Aligns output quality with standard reasoning patterns. |
| **System/User Separation** | Explicit delimiter strategies in prompt structure. | Mitigates prompt injection and contextual drift. |
| **Task Classification** | Heuristic instructions to adopt specific personas. | Aligns tone and depth with the nature of the request. |
| **Step Chaining** | Sequential processing instructions. | Prevents instruction skipping in multi-part requests. |
| **Self-Correction** | A pre-output validation checklist. | Forces the model to review its own output against constraints. |

## Technical Implementation Details

### Token Overhead & Budget
Since Directive functions by prepending instructions, it consumes context tokens for every request.
- **Input Overhead:** ~800-1000 tokens (fixed cost per extensive system prompt).
- **Context Limits:** If the model's context window is full, the system prompt may be truncated by the provider. This results in a silent failure where Directive is not applied.
- **Latency Impact:** Negligible for `flash` models; slight increase for `pro` models due to increased input processing.
- **Output Overhead:** Variable. The `<thinking>` blocks add to generation time but are often collapsed in agentic UIs.

### Failure Modes & Verification

Directive relies on the model adhering to the injected protocol.
1. **Verification Signal:** The protocol explicitly instructs the model to output `Directive applied` as its very first line.
   - *Note: This is a probabilistic instruction, not a hardcoded system output. Extremely capable models (e.g., Claude 3.5 Sonnet, GPT-4o) follow it reliably. Smaller or older models may occasionally skip it.*
2. **Missing Signal:** If `Directive applied` is absent:
   - **Cause:** `SKILL.md` content was not successfully injected (file path error).
   - **Cause:** Context window truncation dropped the system prompt.
   - **Cause:** Provider sanitization removed custom system instructions.

### Multi-turn & Agentic Behavior
In multi-turn conversations or agent loops (e.g., Bolt.new, Windsurf Cascade):
- **Persistence:** The system prompt typically persists across the entire session.
- **Re-injection:** Some stateless agentic tools re-inject the system prompt on every turn, incurring the input token cost repeatedly.
- **Idempotency:** The protocol is designed to be idempotent; re-reading it does not alter state, but repeated verification lines (`Directive applied`) may appear if the agent treats every turn as a fresh start.

### Local vs. Cloud Processing
The term "local" applies only to the *source* of the instruction file.
- **Local Injection:** Antigravity, Cursor (local features), generic API wrappers read `SKILL.md` from disk.
- **Remote Inference:** When using chat interfaces or cloud-based IDEs, the text from `SKILL.md` is sent over the network to the model provider. **Directive runs in the model's inference context, not on your localhost CPU.**

---

## Supported Environments

Directive is infrastructure-agnostic but requires a mechanism to inject system instructions.

### Native / File-Based Support (Auto-Sync)
These environments read directly from the local file system. Updates to `SKILL.md` are reflected immediately in new sessions.
-   **Antigravity (Google Gemini)**: via `GEMINI.md`
-   **Cursor**: via `~/.cursor/skills/directive/SKILL.md` (auto-detected)
-   **Windsurf**: via `rules.md`

*(Note: `GEMINI.md` support is unique to the Antigravity wrapper. Other tools rely on their specific configuration files.)*

See the `templates/` directory for reference implementations.

---

## File Structure

```
directive-layer\          <- Git repo: directive-layer
├── SKILL.md                              <- The skill definition (AI reads this)
├── README.md                             <- This file
├── install.ps1                           <- One-click installer (Windows)
├── install.sh                            <- One-click installer (Mac/Linux)
├── CHANGELOG.md                          <- Version history
├── .gitignore                            <- Excludes project-specific IDE files
└── templates\
    ├── GEMINI-patch.md                   <- For Antigravity (Google Gemini)
    ├── cursor-rules.md                   <- For Cursor IDE (manual skill setup reference)
    ├── windsurf-rules.md                 <- For Windsurf IDE (rules.md)
    └── vscode-copilot-instructions.md    <- For VS Code + GitHub Copilot
```

---

## Installation (One Command, Global Setup)

Run the installer once. It sets up Directive globally so it works in **all your projects** across supported IDEs.

### ⚡ One-Click Installer (Windows)

Copy and run in PowerShell (clone + install in one go):

```powershell
git clone https://github.com/SnehDungrani/directive-layer.git
cd directive-layer
.\install.ps1
```

When prompted, enter which IDE(s) you use (e.g. `1,2,3` or `all`). Restart your IDE(s) if the installer says so (Cursor doesn't require restart).

**What the installer does:**
- **Always:** Installs the skill to `~/.agent/skills/directive/SKILL.md`
- **Antigravity (option 1):** Patches `GEMINI.md` automatically. Restart Antigravity to apply.
- **Cursor (option 2):** Installs skill file at `~/.cursor/skills/directive/SKILL.md` (auto-detected by Cursor, no restart needed).
- **Windsurf (option 3):** Writes global rules to Windsurf's config folder. Restart Windsurf to apply.
- **VS Code Copilot (option 4):** Writes user-level instructions to `prompts/directive.instructions.md`. Restart VS Code to apply.

All options are fully automated — no copy/paste needed.

---

### For Mac / Linux

Copy and run in terminal (clone + install in one go):

```bash
git clone https://github.com/SnehDungrani/directive-layer.git
cd directive-layer
chmod +x install.sh
./install.sh
```

When prompted, enter which IDE(s) you use (e.g. `1,2,3` or `all`).

---

## Temperature Reference Card

*Note: Values are normalized for 0.0–1.0 ranges. For API-specific ranges (e.g., 0-2), scale accordingly.*

| Task Type | Temperature | Use When |
|---|---|---|
| Code generation | **0.1 - 0.2** | Writing functions, debugging, refactoring (Strict) |
| Analysis / factual | **0.3 - 0.5** | Research, explanations, summaries (Balanced) |
| Creative writing | **0.7 - 0.9** | Stories, marketing copy, creative content (Expressive) |
| Brainstorming | **0.8 - 1.0** | Idea generation, business ideas, innovation (Max Exploration) |

---

## Updating the Skill

To modify the core protocol:

1.  Edit `SKILL.md` in this repository (Source of Truth).
2.  Run `install.ps1` (Windows) or `install.sh` (Mac/Linux) to propagate changes to the global `.agent` directory and IDE-specific locations.
3.  Add an entry to `CHANGELOG.md`.

*Note: For template-based integrations (VS Code, etc.), you must manually re-paste the updated content.*

---

## Known Issues & Operational Risks

-   **Context Truncation:** On very long conversations, the system prompt may be effectively truncated by the provider to save context window space, silently disabling Directive.
-   **Multi-Agent Loops:** Stateless agents may re-inject the system prompt on every turn, increasing token costs linearly with conversation length.

---

## Authorship & Credits

**Author:** Sneh Dungrani

Directive — its structure, packaging, global installation architecture, and IDE integration system — is an original work by Sneh Dungrani. No identical implementation exists publicly.

**Techniques based on:**
- Anthropic's Constitutional AI research (negative constraints, hallucination reduction)
- OpenAI's chain-of-thought prompt engineering practices
- Production AI system validation loop patterns

---

*Directive — global prompt protocol*  
*Author: Sneh Dungrani | Version: 1.2 | February 2026*  
*Repo: [directive-layer](https://github.com/SnehDungrani/directive-layer)*
