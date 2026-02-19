# ⚡ Directive — global prompt protocol

> **A behavior layer that guides how the model reasons and responds — not a pre-processor.**

---

## What Is This?

**Directive** is a system-level behavior layer that changes **how** the model reasons and answers once your raw prompt is inside the context. It does **not** pre-edit or rewrite your prompt before it reaches the model.

When you use Directive, Cursor sends **two things** to the model:
1. `SKILL.md` as a **system / skill prompt** (the rules).
2. Your **raw user prompt** exactly as you typed it.

The model reads the skill first, then:
1. **Classifies** your prompt (FACTUAL / ANALYTICAL / GENERATIVE / CODE / etc.).
2. **Cleans it up internally** (fixes typos, clarifies if needed, rewrites as a clear task).
3. **Applies only the relevant techniques** (negative constraints, structure, validation, etc.) **inside its own reasoning**.
4. **Generates the final answer** directly.

The refined prompt is built internally and used by the model to think, but it's **not shown** in the response. You just see:
```
Directive applied
------------------
[answer...]
```

The system is model-agnostic and works with any IDE that can load a system prompt or skill file.

**Mission:** Move prompt engineering into the system layer — the right structure when needed, without burdening every question.

---

## Architecture

Directive functions as a **Behavior Layer**, not a pre-processor. It does not intercept, rewrite, or transform your prompt before it reaches the model. Instead, it leverages the `system` or `pre-prompt` capabilities of your AI tool to prepend behavioral instructions to the context window.

**What Directive does NOT change:**
- The underlying model weights (Sonnet/Opus/etc.).
- Cursor's tool-calling engine (file reads, edits, tests) — those are still decided by the model, just under the skill's guidance.
- Any low-level "reasoning algorithm" — it's still the same LLM, just with a stronger system prompt.

**What Directive does change:**
- Forces input cleanup and typo correction.
- Forces more structured, sectioned answers for ANALYTICAL / framework / strategy queries.
- Forces internal validation before answering.
- Forbids raw XML/HTML tags in visible output.
- For framework/guide/methodology prompts, forces full coverage (objective, variables, uncertainty, constraints, trade-offs, process, implementation options, pitfalls, checklist).

When a prompt is submitted:
1.  **Context Loading**: The AI tool reads [`SKILL.md`](./SKILL.md) via its configured system prompt file (e.g. `GEMINI.md`, `~/.cursor/skills/directive/SKILL.md`, `rules.md`).
2.  **Intent Classification**: The model classifies the query (FACTUAL, ANALYTICAL, GENERATIVE, CODE, MULTI-STEP, EXTERNAL-CONTENT, CONVERSATIONAL).
3.  **Technique Routing**: Only the techniques that fit the query type are applied — not all eight on every prompt. FACTUAL and CONVERSATIONAL are answered directly with no technique bloat.
4.  **Internal Refinement & Response**: The model refines the prompt internally (you don't see this), outputs `Directive applied`, then answers using the refined approach.

This keeps quality high without over-applying structure to simple queries.

## Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     What gets sent to the model                 │
├─────────────────────────────────────────────────────────────────┤
│  [System Prompt]   SKILL.md (behavioral instructions)           │
│  [User Prompt]     Your raw input, exactly as typed             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  What happens inside the model                  │
├─────────────────────────────────────────────────────────────────┤
│  1. Read SKILL.md instructions                                  │
│  2. Classify intent (FACTUAL / ANALYTICAL / CODE / etc.)        │
│  3. Clean up input internally (fix typos, clarify)              │
│  4. Build refined prompt internally (not shown to you)          │
│  5. Apply relevant techniques in reasoning                      │
│  6. Validate before output                                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      What you see                               │
├─────────────────────────────────────────────────────────────────┤
│  Directive applied                                              │
│  ------------------                                             │
│  [answer in clean markdown/prose, no tags]                      │
└─────────────────────────────────────────────────────────────────┘
```

**Without** the skill: Cursor just answers based on its built-in system prompt + your raw message.
**With** `SKILL.md`: the model **must** first follow your intent classification, input cleanup, routing, structure, and validation rules **before** it decides how to respond.

---

## Technique Routing

The skill is defined in [`SKILL.md`](./SKILL.md). It uses **intent-based routing**: the model classifies the query first (internally), then applies only the techniques that improve that type of prompt. This all happens inside the model's reasoning — you just see the final answer.

| Technique | When it applies | What it does |
| :--- | :--- | :--- |
| **1. Negative Constraints** | Analytical, generative, code, multi-step, external content | Converts vague instructions into specific, testable "never" constraints. |
| **2. Chain of Thought** | Analytical, code, multi-step | Forces reasoning-before-answer internally; you only see the final clean answer. |
| **3. Structured Output** | Analytical, code, multi-step | Enforces clear structure (headings, sections, lists) — markdown for IDE/chat, XML only for API output. |
| **4. Few-Shot with Reasoning** | Generative, code | INPUT → REASONING → OUTPUT examples so the model learns why, not just what. |
| **5. System/User Separation** | External content | Keeps instructions separate from user-supplied text to reduce prompt injection. |
| **6. Temperature Advisory** | Analytical, generative, code, multi-step | Adds a comment for the *caller* (API/user) recommending temperature by task type. |
| **7. Prompt Chaining** | Multi-step | Breaks "do A and then B" into numbered steps with clear inputs/outputs. |
| **8. Validation Loop** | Analytical, generative, code, multi-step | Self-check before output: address all points, no contradictions, format match. |

**FACTUAL and CONVERSATIONAL:** No techniques applied; the model answers directly to avoid noise.

## Technical Implementation Details

### Token Overhead & Budget
Since Directive functions by prepending behavioral instructions, it consumes context tokens for every request.
- **Input Overhead:** ~800-1000 tokens (fixed cost per extensive system prompt).
- **Context Limits:** If the model's context window is full, the system prompt may be truncated by the provider. This results in a silent failure where Directive is not applied.
- **Latency Impact:** Negligible for `flash` models; slight increase for `pro` models due to increased input processing.
- **Output Overhead:** Minimal. The refined prompt and internal reasoning are not shown to you — only the final clean answer.

### Failure Modes & Verification

Directive relies on the model following the protocol in `SKILL.md`.
1. **Verification Signal:** The protocol asks the model to output `Directive applied` then `------------------` before the answer.
   - *Note: This is a probabilistic instruction. Strong models follow it reliably; smaller or older models may sometimes skip it.*
2. **Missing Signal:** If `Directive applied` is absent:
   - **Cause:** `SKILL.md` was not injected (wrong path or not loaded).
   - **Cause:** Context truncation dropped the system prompt.
   - **Cause:** Provider sanitization stripped custom instructions.

### Multi-turn & Agentic Behavior
In multi-turn or agent loops (e.g. Windsurf Cascade):
- **Persistence:** The system prompt usually persists for the session.
- **Re-injection:** Some tools re-inject the prompt every turn, which repeats token cost.
- **Idempotency:** The protocol is idempotent; re-reading it does not change state. You may see `Directive applied` on each turn if the agent starts fresh each time.

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

The skill adds a **temperature advisory** (a comment for the caller) when relevant; the model cannot set API temperature itself. Recommended ranges (normalized 0–1; scale for API-specific ranges):

| Task Type | Recommended Temperature | Use When |
|-----------|--------------------------|----------|
| Factual / analysis | **0.2 – 0.4** | Lookups, explanations, summaries |
| Code generation | **0.1 – 0.3** | Writing or debugging code |
| Balanced explanation | **0.5 – 0.7** | Tutorials, how-tos |
| Creative writing | **0.8 – 1.0** | Stories, marketing, varied tone |
| Brainstorming | **1.0 – 1.2** | Ideation, exploration |

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

Directive — intent classification, technique routing, packaging, global install, and IDE integration — is an original work by Sneh Dungrani. No identical implementation exists publicly.

**Techniques based on:**
- Anthropic Constitutional AI and prompting docs (negative constraints, hallucination reduction)
- Chain-of-thought prompting (Wei et al.; OpenAI prompt engineering practices)
- Production AI validation loop patterns

---

*Directive — global prompt protocol*  
*Author: Sneh Dungrani | Version: 1.3 | February 2026*  
*Repo: [directive-layer](https://github.com/SnehDungrani/directive-layer)*
