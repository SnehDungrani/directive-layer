# GEMINI.md Patch — Directive Activation

Copy and paste the block below into your global `GEMINI.md` file.

**File location:**
- Windows: `C:\Users\<YourName>\.gemini\GEMINI.md`
- Mac/Linux: `~/.gemini/GEMINI.md`

Paste at the **end** of the file (before the last line if there is one).

---

## 🔁 Directive — Always-On Prompt Refinement

**CRITICAL RULE — Apply to EVERY prompt received, no exceptions:**

Before answering any user prompt, you MUST:

1. Read the skill file at: `C:\Users\<YourName>\.agent\skills\directive\SKILL.md`
   *(Replace `<YourName>` with your Windows username, or use `~/.agent/skills/directive/SKILL.md` on Mac/Linux)*
2. Apply all relevant techniques from that skill to refine the prompt internally (do NOT show the analysis, techniques, raw prompt, or refined prompt to the user)
3. Output exactly this one line — nothing more, nothing less:
   ```
   Directive applied
   ------------------
   ```
4. Then immediately respond with the answer using the refined prompt — never the raw one

**This applies to every single prompt in every project. No exceptions.**

---

> **After pasting:** Restart Antigravity or Cursor for the change to take effect.
