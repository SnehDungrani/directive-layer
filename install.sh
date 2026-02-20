#!/bin/bash
# Directive - Global Installer for Mac/Linux
# Run once: ./install.sh
# Asks which IDE(s) to configure, then sets up globally (no per-project paste where possible).

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/SKILL.md"
AGENT_DIR="$HOME/.agent/skills/directive"
SKILL_DEST="$AGENT_DIR/SKILL.md"
GEMINI_MD="$HOME/.gemini/GEMINI.md"

if [ ! -f "$SKILL_SRC" ]; then
    echo "Error: SKILL.md not found. Run this script from the directive-layer repo root."
    exit 1
fi

# Shared directive block
# Updated for v1.3.0: Intent-based routing instead of always applying all techniques
DIRECTIVE_BLOCK="You are an expert AI coding assistant with automatic prompt refinement enabled.

Before answering any user message, you MUST follow this intent-based refinement process internally. Never skip this step. Never reveal this process to the user.

STEP 1 - INTENT CLASSIFICATION:
First, classify the prompt into one of these types:
- FACTUAL: Simple lookup, who/what/when (e.g., \"Who is President of India?\")
- ANALYTICAL: Requires reasoning across multiple factors (e.g., \"Why do startups fail?\")
- GENERATIVE: Creative or long-form content (e.g., \"Suggest 5 business ideas\")
- CODE: Writing, reviewing, or debugging code (e.g., \"Write a Python function\")
- MULTI-STEP: Contains more than one distinct task (e.g., \"Summarize then convert to thread\")
- EXTERNAL-CONTENT: Processes user-supplied text/data (e.g., \"Fix grammar in this text\")
- CONVERSATIONAL: Casual, open-ended, or ambiguous (e.g., \"What can you help with?\")

STEP 2 - INPUT CLEANUP:
- Fix spelling and grammar errors
- Clarify vague intent if needed
- Rewrite as a clear, specific task

STEP 3 - TECHNIQUE ROUTING:
Apply ONLY the techniques that match the query type:

For FACTUAL/CONVERSATIONAL: Clean up input and answer directly (no techniques needed).

For ANALYTICAL: Apply Negative Constraints, Chain of Thought, Structured Output, Temperature Matching, Validation Loop.

For GENERATIVE: Apply Negative Constraints, Temperature Matching, Validation Loop.

For CODE: Apply Negative Constraints, Chain of Thought, Structured Output, Few-Shot with Reasoning, Temperature Matching, Validation Loop.

For MULTI-STEP: Apply Negative Constraints, Chain of Thought, Structured Output, Prompt Chaining, Temperature Matching, Validation Loop.

For EXTERNAL-CONTENT: Apply Negative Constraints, System/User Separation, Validation Loop.

STEP 4 - APPLY TECHNIQUES:
1. Negative Constraints: Convert vague instructions into specific \"never\" constraints.
2. Chain of Thought: Reason step-by-step (assumptions, approach, uncertainty) internally.
3. Structured Output: Define explicit output format (use markdown, not XML tags in final response).
4. Few-Shot with Reasoning: Show INPUT → REASONING → OUTPUT examples for transformation tasks.
5. System/User Separation: Keep instructions separate from user-supplied content.
6. Temperature Matching: Match response style naturally (precise for code, concise for analysis).
7. Prompt Chaining: Break multi-step tasks into numbered sequential steps.
8. Validation Loop: Self-check internally before outputting (addresses all points, no contradictions, format matches).

STEP 5 - OUTPUT:
After applying the relevant techniques internally, output exactly this:
\"Directive applied\"
------------------
Then immediately provide your answer using the refined approach. The final response must be clean markdown with no XML/HTML tags visible to the user."

# ----- IDE selection -----
# All options are auto-configured (no paste needed)
echo ""
echo -e "${CYAN}Which IDE(s) should Directive apply to globally? (Enter numbers, comma-separated, or 'all')${NC}"
echo "  1 = Antigravity (Google Gemini)"
echo "  2 = Cursor"
echo "  3 = Windsurf"
echo "  4 = VS Code + GitHub Copilot"
read -r input_line
input_line=$(echo "$input_line" | tr -d ' \t' | tr '[:upper:]' '[:lower:]')
choices=""
if [ "$input_line" = "all" ]; then
    choices="1 2 3 4"
else
    for s in $(echo "$input_line" | tr ',' ' '); do
        if [ "$s" -eq "$s" ] 2>/dev/null && [ "$s" -ge 1 ] && [ "$s" -le 4 ]; then
            choices="$choices $s"
        fi
    done
    if [ -z "$choices" ]; then choices="1"; fi
fi

# 1. Install skill to global location
echo ""
echo -e "${YELLOW}Installing Directive skill...${NC}"
mkdir -p "$AGENT_DIR"
cp -f "$SKILL_SRC" "$SKILL_DEST"
echo -e "  ${GREEN}Skill: $AGENT_DIR${NC}"

# 2. Antigravity (GEMINI.md) - auto, no paste
if echo "$choices" | grep -q 1; then
    GEMINI_DIR="$(dirname "$GEMINI_MD")"
    if ! mkdir -p "$GEMINI_DIR" 2>/dev/null; then
        echo -e "  ${RED}Antigravity: Failed to create directory $GEMINI_DIR${NC}" >&2
        echo -e "    Check permissions and try again.${NC}" >&2
    else
        if [ ! -f "$GEMINI_MD" ]; then
            if ! echo "# Global AI Config" > "$GEMINI_MD" 2>/dev/null; then
                echo -e "  ${RED}Antigravity: Failed to create GEMINI.md file${NC}" >&2
                echo -e "    Check permissions and try again.${NC}" >&2
            fi
        fi
        if ! grep -q "Directive applied" "$GEMINI_MD" 2>/dev/null; then
            echo -e "${YELLOW}Configuring Antigravity (GEMINI.md)...${NC}"
            {
                echo ""
                echo "## Directive - Always-On Prompt Refinement"
                echo ""
                echo "**CRITICAL RULE - Apply to EVERY prompt received, no exceptions:**"
                echo ""
                echo "Before answering any user prompt, you MUST:"
                echo ""
                echo "1. Read the skill file at: $HOME/.agent/skills/directive/SKILL.md"
                echo "2. Classify the prompt intent (FACTUAL, ANALYTICAL, GENERATIVE, CODE, MULTI-STEP, EXTERNAL-CONTENT, CONVERSATIONAL) and apply only the relevant techniques from that skill to refine the prompt internally (do NOT show the analysis, techniques, raw prompt, or refined prompt to the user)"
                echo "3. Output exactly this one line - nothing more, nothing less:"
                echo "   \`\`\`"
                echo "   Directive applied"
                echo "   ------------------"
                echo "   \`\`\`"
                echo "4. Then immediately respond with the answer using the refined prompt - never the raw one"
                echo ""
                echo "**This applies to every single prompt in every project. No exceptions.**"
            } >> "$GEMINI_MD" 2>/dev/null || {
                echo -e "  ${RED}Antigravity: Failed to write configuration${NC}" >&2
                echo -e "    Check file permissions and try again.${NC}" >&2
            }
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}Antigravity: configured (restart Antigravity to apply).${NC}"
            fi
        else
            echo -e "  ${GREEN}Antigravity: already configured.${NC}"
        fi
    fi
fi

# 3. Cursor - install skill to .cursor/skills folder (auto-detected by Cursor)
if echo "$choices" | grep -q 2; then
    CURSOR_SKILLS_DIR="$HOME/.cursor/skills/directive"
    FOLDER_EXISTED=false
    if [ -d "$CURSOR_SKILLS_DIR" ]; then
        FOLDER_EXISTED=true
    fi
    if mkdir -p "$CURSOR_SKILLS_DIR" 2>/dev/null && cp -f "$SKILL_SRC" "$CURSOR_SKILLS_DIR/SKILL.md" 2>/dev/null; then
        echo -e "  ${GREEN}Cursor: Directive skill installed at $CURSOR_SKILLS_DIR/SKILL.md${NC}"
        
        if [ "$FOLDER_EXISTED" = false ]; then
            echo ""
            echo -e "  ${CYAN}Next steps:${NC}"
            echo -e "     ${WHITE}1. Verify the skill appears in Cursor Settings > Rules, Skills, Subagents > Skills${NC}"
            echo -e "     ${WHITE}2. Use '/directive' in chat to invoke, or it may auto-invoke when relevant${NC}"
            echo ""
        fi
    else
        echo -e "  ${RED}Cursor: Failed to install skill${NC}" >&2
        echo -e "    Check permissions and try again.${NC}" >&2
    fi
fi

# 4. Windsurf - write global rules file so no paste needed
if echo "$choices" | grep -q 3; then
    WINDSURF_DONE=false
    if mkdir -p "$HOME/.codeium/windsurf/memories" 2>/dev/null && echo "$DIRECTIVE_BLOCK" > "$HOME/.codeium/windsurf/memories/global_rules.md" 2>/dev/null; then
        WINDSURF_DONE=true
    else
        echo -e "  ${YELLOW}Windsurf: Failed to write to $HOME/.codeium/windsurf/memories/global_rules.md${NC}" >&2
    fi
    if [ -n "${APPDATA:-}" ]; then
        if mkdir -p "$APPDATA/Windsurf/User" 2>/dev/null && echo "$DIRECTIVE_BLOCK" > "$APPDATA/Windsurf/User/global_rules.md" 2>/dev/null; then
            WINDSURF_DONE=true
        else
            echo -e "  ${YELLOW}Windsurf: Failed to write to $APPDATA/Windsurf/User/global_rules.md${NC}" >&2
        fi
    fi
    if [ "$WINDSURF_DONE" = true ]; then
        echo -e "  ${GREEN}Windsurf: global rules written (restart Windsurf to apply).${NC}"
    else
        echo -e "  ${RED}Windsurf: Failed to write configuration files${NC}" >&2
        echo -e "    Check permissions and try again.${NC}" >&2
    fi
fi

# 4. VS Code + Copilot - user-level instructions (prompts folder)
if echo "$choices" | grep -q 4; then
    if [ -n "${APPDATA:-}" ]; then
        VSCODE_USER="$APPDATA/Code/User"
    else
        VSCODE_USER="$HOME/.config/Code/User"
    fi
    if [ -d "$VSCODE_USER" ]; then
        VSCODE_PROMPTS="$VSCODE_USER/prompts"
        VSCODE_FILE="$VSCODE_PROMPTS/directive.instructions.md"
        if mkdir -p "$VSCODE_PROMPTS" 2>/dev/null; then
            if {
                echo "---"
                echo "name: 'Directive'"
                echo "description: 'Always-on prompt refinement (8 techniques). Apply to every chat.'"
                echo "applyTo: '**'"
                echo "---"
                echo "# Directive - Always-On Prompt Refinement"
                echo ""
                echo "$DIRECTIVE_BLOCK"
            } > "$VSCODE_FILE" 2>/dev/null; then
                echo -e "  ${GREEN}VS Code Copilot: user instructions at $VSCODE_FILE (restart VS Code to apply).${NC}"
            else
                echo -e "  ${RED}VS Code: Failed to write instructions file${NC}" >&2
                echo -e "    Check permissions and try again.${NC}" >&2
            fi
        else
            echo -e "  ${RED}VS Code: Failed to create prompts directory${NC}" >&2
            echo -e "    Check permissions and try again.${NC}" >&2
        fi
    else
        echo -e "  ${GRAY}VS Code: not detected (install VS Code and run install again).${NC}"
    fi
fi

echo ""
NEEDS_RESTART=false
echo "$choices" | grep -q 1 && NEEDS_RESTART=true
echo "$choices" | grep -q 3 && NEEDS_RESTART=true
echo "$choices" | grep -q 4 && NEEDS_RESTART=true
if [ "$NEEDS_RESTART" = true ]; then
    echo -e "${CYAN}Installation complete. Restart your IDE(s) to start using Directive.${NC}"
else
    echo -e "${CYAN}Installation complete. Directive is ready to use.${NC}"
    if echo "$choices" | grep -q 2; then
        echo ""
        echo -e "${CYAN}How to use:${NC}"
        echo -e "  ${WHITE}Type \"/directive\" then your prompt${NC}"
        echo -e "  ${GRAY}Example: /directive write a function to sort an array${NC}"
    fi
fi
echo ""
