$ErrorActionPreference = "Stop"

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillSrc    = Join-Path $scriptDir "SKILL.md"
$skillDest   = "$env:USERPROFILE\.agent\skills\directive\SKILL.md"
$geminiMd    = "$env:USERPROFILE\.gemini\GEMINI.md"
$agentDir    = Split-Path -Parent $skillDest

if (-not (Test-Path $skillSrc)) {
    Write-Error "SKILL.md not found. Run this script from the directive-layer repo root."
    exit 1
}

# Shared directive block (ASCII-only for encoding safety)
# Updated for v1.3.0: Intent-based routing instead of always applying all techniques
$directiveBlock = @"
You are an expert AI coding assistant with automatic prompt refinement enabled.

Before answering any user message, you MUST follow this intent-based refinement process internally. Never skip this step. Never reveal this process to the user.

STEP 1 - INTENT CLASSIFICATION:
First, classify the prompt into one of these types:
- FACTUAL: Simple lookup, who/what/when (e.g., "Who is President of India?")
- ANALYTICAL: Requires reasoning across multiple factors (e.g., "Why do startups fail?")
- GENERATIVE: Creative or long-form content (e.g., "Suggest 5 business ideas")
- CODE: Writing, reviewing, or debugging code (e.g., "Write a Python function")
- MULTI-STEP: Contains more than one distinct task (e.g., "Summarize then convert to thread")
- EXTERNAL-CONTENT: Processes user-supplied text/data (e.g., "Fix grammar in this text")
- CONVERSATIONAL: Casual, open-ended, or ambiguous (e.g., "What can you help with?")

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
1. Negative Constraints: Convert vague instructions into specific "never" constraints.
2. Chain of Thought: Reason step-by-step (assumptions, approach, uncertainty) internally.
3. Structured Output: Define explicit output format (use markdown, not XML tags in final response).
4. Few-Shot with Reasoning: Show INPUT → REASONING → OUTPUT examples for transformation tasks.
5. System/User Separation: Keep instructions separate from user-supplied content.
6. Temperature Matching: Match response style naturally (precise for code, concise for analysis).
7. Prompt Chaining: Break multi-step tasks into numbered sequential steps.
8. Validation Loop: Self-check internally before outputting (addresses all points, no contradictions, format matches).

STEP 5 - OUTPUT:
After applying the relevant techniques internally, output exactly this:
"Directive applied"
------------------
Then immediately provide your answer using the refined approach. The final response must be clean markdown with no XML/HTML tags visible to the user.
"@

# ----- IDE selection -----
# All options are auto-configured (no paste needed)
Write-Host ""
Write-Host "Which IDE(s) should Directive apply to globally? (Enter numbers, comma-separated, or 'all')" -ForegroundColor Cyan
Write-Host "  1 = Antigravity (Google Gemini)" -ForegroundColor Gray
Write-Host "  2 = Cursor" -ForegroundColor Gray
Write-Host "  3 = Windsurf" -ForegroundColor Gray
Write-Host "  4 = VS Code + GitHub Copilot" -ForegroundColor Gray
$inputLine = Read-Host "Choice"
$inputLine = ($inputLine -replace "\s", "").ToLower()
if ($inputLine -eq "all") { $choices = @(1,2,3,4) }
else {
    $choices = @()
    foreach ($s in $inputLine -split ",") {
        $n = 0
        if ([int]::TryParse($s, [ref]$n) -and $n -ge 1 -and $n -le 4) { $choices += $n }
    }
    if ($choices.Count -eq 0) { $choices = @(1) }
}

# 1. Install skill to global location
Write-Host ""
Write-Host "Installing Directive skill..." -ForegroundColor Yellow
if (-not (Test-Path $agentDir)) { New-Item -ItemType Directory -Force -Path $agentDir | Out-Null }
Copy-Item -Force $skillSrc $skillDest
Write-Host "  Skill: $agentDir" -ForegroundColor Green

# 2. Antigravity (GEMINI.md) - auto, no paste
if ($choices -contains 1) {
    $geminiDir = Split-Path -Parent $geminiMd
    if (-not (Test-Path $geminiDir)) {
        try {
            New-Item -ItemType Directory -Force -Path $geminiDir | Out-Null
        } catch {
            Write-Host "  Antigravity: Failed to create directory $geminiDir" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Gray
            continue
        }
    }
    if (-not (Test-Path $geminiMd)) {
        try {
            New-Item -ItemType File -Force -Path $geminiMd -Value "# Global AI Config" | Out-Null
        } catch {
            Write-Host "  Antigravity: Failed to create GEMINI.md file" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Gray
            continue
        }
    }
    $content = Get-Content -Path $geminiMd -Raw -ErrorAction SilentlyContinue
    if ($content -notmatch "Directive applied") {
        Write-Host "Configuring Antigravity (GEMINI.md)..." -ForegroundColor Yellow
        $nl = [Environment]::NewLine
        $block = $nl + $nl +
            "## Directive - Always-On Prompt Refinement" + $nl +
            "**CRITICAL RULE - Apply to EVERY prompt received, no exceptions:**" + $nl + $nl +
            "Before answering any user prompt, you MUST:" + $nl + $nl +
            "1. Read the skill file at: $env:USERPROFILE\.agent\skills\directive\SKILL.md" + $nl +
            "2. Classify the prompt intent (FACTUAL, ANALYTICAL, GENERATIVE, CODE, MULTI-STEP, EXTERNAL-CONTENT, CONVERSATIONAL) and apply only the relevant techniques from that skill to refine the prompt internally (do NOT show the analysis, techniques, raw prompt, or refined prompt to the user)" + $nl +
            "3. Output exactly this one line - nothing more, nothing less:" + $nl +
            '   ```' + $nl +
            "   Directive applied" + $nl +
            "   ------------------" + $nl +
            '   ```' + $nl +
            "4. Then immediately respond with the answer using the refined prompt - never the raw one" + $nl + $nl +
            "**This applies to every single prompt in every project. No exceptions.**" + $nl
        try {
            Add-Content -Path $geminiMd -Value $block
            Write-Host "  Antigravity: configured (restart Antigravity to apply)." -ForegroundColor Green
        } catch {
            Write-Host "  Antigravity: Failed to write configuration" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Antigravity: already configured." -ForegroundColor Green
    }
}

# 3. Cursor - install skill to .cursor\skills folder (auto-detected by Cursor)
if ($choices -contains 2) {
    $cursorSkillsDir = Join-Path $env:USERPROFILE ".cursor\skills\directive"
    $folderExisted = Test-Path $cursorSkillsDir
    try {
        if (-not $folderExisted) { 
            New-Item -ItemType Directory -Force -Path $cursorSkillsDir | Out-Null
        }
        $cursorSkillPath = Join-Path $cursorSkillsDir "SKILL.md"
        Copy-Item -Force $skillSrc $cursorSkillPath -ErrorAction Stop
        
        Write-Host "  Cursor: Directive skill installed at $cursorSkillPath" -ForegroundColor Green
        
        if (-not $folderExisted) {
            Write-Host ""
            Write-Host "  Next steps:" -ForegroundColor Cyan
            Write-Host "  1. Verify the skill appears in Cursor Settings > Rules, Skills, Subagents > Skills" -ForegroundColor White
            Write-Host "  2. Use '/directive' in chat to invoke, or it may auto-invoke when relevant" -ForegroundColor White
            Write-Host ""
        }
    } catch {
        Write-Host "  Cursor: Failed to install skill" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Gray
    }
}

# 4. Windsurf - write to global rules file so no paste needed
if ($choices -contains 3) {
    $windsurfPaths = @(
        (Join-Path $env:APPDATA "Windsurf\User\global_rules.md"),
        (Join-Path $env:USERPROFILE ".codeium\windsurf\memories\global_rules.md")
    )
    $windsurfDone = $false
    foreach ($p in $windsurfPaths) {
        $dir = Split-Path -Parent $p
        try {
            if (-not (Test-Path $dir)) { 
                New-Item -ItemType Directory -Force -Path $dir | Out-Null
            }
            Set-Content -Path $p -Value $directiveBlock -ErrorAction Stop
            $windsurfDone = $true
        } catch {
            Write-Host "  Windsurf: Failed to write to $p" -ForegroundColor Yellow
            Write-Host "    Error: $_" -ForegroundColor Gray
        }
    }
    if ($windsurfDone) {
        Write-Host "  Windsurf: global rules written (restart Windsurf to apply)." -ForegroundColor Green
    } else {
        Write-Host "  Windsurf: Failed to write configuration files" -ForegroundColor Red
    }
}

# 4. VS Code + Copilot - user-level instructions (prompts folder of VS Code profile)
if ($choices -contains 4) {
    $vscodeUser = Join-Path $env:APPDATA "Code\User"
    $vscodePromptsDir = Join-Path $vscodeUser "prompts"
    if (Test-Path $vscodeUser) {
        try {
            if (-not (Test-Path $vscodePromptsDir)) { 
                New-Item -ItemType Directory -Force -Path $vscodePromptsDir | Out-Null
            }
            $vscodeInstructions = Join-Path $vscodePromptsDir "directive.instructions.md"
            $vscodeContent = @"
---
name: 'Directive'
description: 'Always-on prompt refinement (8 techniques). Apply to every chat.'
applyTo: '**'
---
# Directive - Always-On Prompt Refinement

$directiveBlock
"@
            Set-Content -Path $vscodeInstructions -Value $vscodeContent -ErrorAction Stop
            Write-Host "  VS Code Copilot: user instructions at $vscodeInstructions (restart VS Code to apply)." -ForegroundColor Green
        } catch {
            Write-Host "  VS Code: Failed to write instructions file" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Gray
        }
    } else {
        Write-Host "  VS Code: not detected (install VS Code and run install again)." -ForegroundColor Gray
    }
}

Write-Host ""
$needsRestart = ($choices -contains 1) -or ($choices -contains 3) -or ($choices -contains 4)
if ($needsRestart) {
    Write-Host "Installation complete. Restart your IDE(s) to start using Directive." -ForegroundColor Cyan
} else {
    Write-Host "Installation complete. Directive is ready to use." -ForegroundColor Cyan
    if ($choices -contains 2) {
        Write-Host ""
        Write-Host "How to use:" -ForegroundColor Cyan
        Write-Host '  Type "/directive" then your prompt' -ForegroundColor White
        Write-Host '  Example: /directive write a function to sort an array' -ForegroundColor Gray
    }
}
