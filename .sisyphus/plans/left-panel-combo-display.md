# Left Panel Combo Display (Tetris Effect Style)

## TL;DR

> **Quick Summary**: Replace the floating text renderer with a left-side panel display (below HOLD) that shows line clear type, B2B counter, and combo count with animate-in/fade-out behavior — matching Tetris Effect's visual style.
> 
> **Deliverables**:
> - New `left_panel_display.gd` Node2D script rendering action/combo text left of the board
> - Updated `scoring.gd` with `back_to_back_count` integer tracker (currently only a boolean)
> - Updated `game_logic.gd` event dictionary with `back_to_back_count` field
> - Updated `game_board.gd` to wire new panel and remove floating text calls
> - Existing floating text renderer fully disconnected
> 
> **Estimated Effort**: Short
> **Parallel Execution**: YES — 2 waves
> **Critical Path**: Task 1 (scoring) → Task 2 (left panel) → Task 3 (wire + remove) → Task 4 (QA)

---

## Context

### Original Request
User wants to add a combo/action display on the left side of the gameboard (below the HOLD piece), similar to Tetris Effect. The display should show: line clear type (SINGLE/DOUBLE/TRIPLE/TETRIS/T-SPIN), B2B xN counter, and N COMBO counter. The existing floating text over the board should be removed entirely.

### Interview Summary
**Key Discussions**:
- **Display behavior**: Animate in on each line clear event, then fade out after ~2 seconds
- **Content**: Clear type label + B2B xN counter + N COMBO
- **Floating text**: Remove entirely — left panel replaces it
- **Score popups (+N)**: Not shown in new panel (intentional — only in HUD)

**Research Findings**:
- `scoring.gd:28`: `back_to_back` is a **boolean only** — no count. Displaying "B2B x3" requires adding `back_to_back_count: int`
- `scoring.gd:27`: `combo_count` starts at -1, increments on consecutive line clears, displayed as `combo_count + 1`
- `floating_text_renderer.gd:137`: `spawn_level_up()` for "LEVEL UP!" text lives here — removing floating text orphans this
- `constants.gd:17`: `BOARD_OFFSET = Vector2(80, 86)` — only 80px to the left of the board
- Width concern: "T-SPIN DOUBLE!" and "BACK TO BACK" are too wide for 80px — text must be right-aligned to the board's left edge and extend leftward into viewport margin

### Metis Review
**Identified Gaps** (addressed):
- **B2B counter missing**: Added Task 1 to extend `scoring.gd` with `back_to_back_count: int`
- **Level-up text orphaned**: Level-up display moved to the left panel as a special event type
- **Width constraints**: Panel text right-aligned to board left edge (`BOARD_OFFSET.x - 8`), extends leftward. The viewport uses `expand` aspect mode with centering, so there's always extra margin space on wider screens
- **Score text (+N) omitted**: Intentional per user request — score is already in HUD
- **combo_count display offset**: New panel must show `combo_count + 1` to match the human-readable combo number (combo_count=0 means first combo = "1 COMBO")

---

## Work Objectives

### Core Objective
Add a Tetris Effect-style left panel that displays line clear type, back-to-back counter, and combo count with animate-in/fade-out behavior, replacing the existing floating text renderer.

### Concrete Deliverables
- `scripts/left_panel_display.gd` — New Node2D renderer for left-side action text
- Modified `scripts/scoring.gd` — Added `back_to_back_count: int` tracking
- Modified `scripts/game_logic.gd` — Event dictionary includes `back_to_back_count`
- Modified `scripts/game_board.gd` — Wires new panel, removes floating text renderer
- Modified `scripts/constants.gd` — Left panel layout/timing constants

### Definition of Done
- [ ] Line clears show clear type (SINGLE/DOUBLE/TRIPLE/TETRIS/T-SPIN variants) on left panel
- [ ] B2B consecutive clears show "B2B xN" with incrementing count
- [ ] Combo clears show "N COMBO" with incrementing count
- [ ] All text animates in with scale punch and fades out after ~2 seconds
- [ ] No floating text appears over the board anymore
- [ ] Level-up text appears on the left panel
- [ ] All existing tests still pass (`timeout 60 godot --headless --path . -d -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit`)

### Must Have
- Text positioned to the left of the board, below the HOLD piece
- Animate-in with scale punch (like current floating text), fade out over ~2 seconds
- Show combo count as human-readable (display `combo_count + 1`)
- B2B counter shows accumulated consecutive count (not just boolean)
- Clear type labels: SINGLE, DOUBLE, TRIPLE, TETRIS, T-SPIN, T-SPIN MINI, T-SPIN SINGLE, T-SPIN MINI SINGLE, T-SPIN DOUBLE, T-SPIN TRIPLE
- Text visible on wide viewports (extend leftward from board edge into margin)
- Level-up text on the left panel

### Must NOT Have (Guardrails)
- No `class_name` on the new script (follows Node rendering convention: `game_board`, `floating_text_renderer`, `particle_effects`, etc.)
- No score popups (+N) in the left panel — score is in the HUD only
- No signals for game events — event dictionary pattern is the project convention
- No modification to `addons/gut/` — vendored third-party
- No changes to game logic behavior — only visual display changes (except B2B counter tracking)
- No changes to the right side (NEXT panel) or HUD layout
- Do NOT remove `floating_text_renderer.gd` file — just disconnect it (remove `add_child` and calls in `game_board.gd`). Less risk.

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES (GUT 9.6.0)
- **Automated tests**: Tests-after — verify scoring changes don't break existing tests, add unit test for B2B counter
- **Framework**: GUT (Godot Unit Testing)

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Visual/UI**: Use Playwright or screenshot capture via Godot — run the game, trigger line clears, verify visual output
- **Logic**: Use Bash — run GUT test suite headless
- **Integration**: Use Bash — run the game, verify no crashes

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — logic + new script):
├── Task 1: Add B2B count to scoring + event propagation [quick]
├── Task 2: Create left_panel_display.gd script [unspecified-high]
└── Task 3: Add left panel constants to constants.gd [quick]

Wave 2 (After Wave 1 — integration):
├── Task 4: Wire new panel into game_board + remove floating text [unspecified-high]
└── Task 5: Run tests + visual QA verification [deep]

Critical Path: Task 1 → Task 4 → Task 5
Parallel Speedup: ~40% faster than sequential
Max Concurrent: 3 (Wave 1)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1    | —         | 4, 5   |
| 2    | —         | 4      |
| 3    | —         | 2, 4   |
| 4    | 1, 2, 3   | 5      |
| 5    | 4         | —      |

### Agent Dispatch Summary

- **Wave 1**: **3 tasks** — T1 → `quick`, T2 → `unspecified-high`, T3 → `quick`
- **Wave 2**: **2 tasks** — T4 → `unspecified-high`, T5 → `deep`

---

## TODOs

- [x] 1. Add B2B Count Tracking to Scoring + Event Propagation

  **What to do**:
  - In `scripts/scoring.gd`: Add `var back_to_back_count: int = 0` alongside existing `back_to_back: bool`
  - In `scoring.gd:process_placement()`: When `qualifies_for_b2b and back_to_back` (line 55), increment `back_to_back_count += 1`. When B2B is first activated (line 80: `back_to_back = true`), if it wasn't already true, set `back_to_back_count = 1`. When B2B breaks (line 83: `back_to_back = false`), reset `back_to_back_count = 0`
  - In `scoring.gd:reset()` (line 136): Add `back_to_back_count = 0`
  - In `scripts/game_logic.gd:_lock_piece()`: Add `"back_to_back_count": scoring.back_to_back_count` to the events dictionary (around line 389, alongside `is_back_to_back`)
  - Add a GUT unit test in `test/unit/` for the B2B counter: verify it increments on consecutive Tetris clears, resets when broken by a non-qualifying clear, starts at 0

  **Must NOT do**:
  - Do not change combo logic or any other scoring behavior
  - Do not add `class_name` to any existing Node scripts
  - Do not modify event dictionary structure beyond adding the new `back_to_back_count` field

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small, surgical changes to 2 existing files + 1 test file. Well-scoped logic modification.
  - **Skills**: `[]`
    - No special skills needed — pure GDScript logic edit
  - **Skills Evaluated but Omitted**:
    - `git-master`: Not needed — single-concern commit

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3)
  - **Blocks**: Tasks 4, 5
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `scripts/scoring.gd:27-29` — Existing `combo_count`, `back_to_back`, `combo_grace_pieces` declarations. New `back_to_back_count` goes here
  - `scripts/scoring.gd:44-83` — `process_placement()` method. B2B logic at lines 53-56 (qualification check), 80-83 (state update). New counter logic goes alongside
  - `scripts/scoring.gd:136-142` — `reset()` method. Add `back_to_back_count = 0` here

  **API/Type References**:
  - `scripts/game_logic.gd:329-413` — `_lock_piece()` method. Events dict declared at 330-343. Add `back_to_back_count` field at line 389 alongside `is_back_to_back`

  **Test References**:
  - `test/unit/` — Existing test directory. Check existing scoring tests for pattern to follow (test file naming, describe/it structure)

  **WHY Each Reference Matters**:
  - `scoring.gd:53-56` — Shows the exact B2B qualification logic. The counter increments here when `qualifies_for_b2b and back_to_back` (already in a B2B streak)
  - `scoring.gd:80-83` — Shows where B2B state transitions. Counter must be set to 1 when B2B activates, 0 when it breaks
  - `game_logic.gd:389` — Shows where `is_back_to_back` is set in events. `back_to_back_count` goes right next to it

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: B2B counter increments on consecutive qualifying clears
    Tool: Bash (GUT test)
    Preconditions: Fresh scoring instance
    Steps:
      1. Call process_placement(4, false, false, false, 0, true) — Tetris, B2B activates → count=1
      2. Call process_placement(4, false, false, false, 0, true) — Second Tetris, B2B continues → count=2
      3. Call process_placement(4, false, false, false, 0, true) — Third → count=3
      4. Assert scoring.back_to_back_count == 3
    Expected Result: back_to_back_count increments from 1 to 3 over 3 consecutive Tetrises
    Failure Indicators: count stays at 1 or doesn't increment
    Evidence: .sisyphus/evidence/task-1-b2b-counter-increment.txt

  Scenario: B2B counter resets on non-qualifying clear
    Tool: Bash (GUT test)
    Preconditions: Scoring instance with active B2B streak (count=2)
    Steps:
      1. Start with 2 consecutive Tetris clears (count=2)
      2. Call process_placement(1, false, false, false, 0, false) — Single, breaks B2B
      3. Assert scoring.back_to_back_count == 0
      4. Assert scoring.back_to_back == false
    Expected Result: back_to_back_count resets to 0
    Failure Indicators: count stays at 2 or resets to wrong value
    Evidence: .sisyphus/evidence/task-1-b2b-counter-reset.txt

  Scenario: All existing GUT tests still pass
    Tool: Bash
    Preconditions: None
    Steps:
      1. Run: timeout 60 godot --headless --path . -d -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit
      2. Assert exit code 0 and "0 failing" in output
    Expected Result: All 68+ tests pass, 0 failures
    Failure Indicators: Any test failure or non-zero exit code
    Evidence: .sisyphus/evidence/task-1-tests-pass.txt
  ```

  **Commit**: YES
  - Message: `feat(scoring): add back-to-back count tracking for B2B xN display`
  - Files: `scripts/scoring.gd`, `scripts/game_logic.gd`, `test/unit/test_b2b_counter.gd`
  - Pre-commit: `timeout 60 godot --headless --path . -d -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit`

- [x] 2. Create Left Panel Display Script

  **What to do**:
  - Create `scripts/left_panel_display.gd` extending Node2D
  - No `class_name` (follows convention for Node rendering scripts)
  - Preload `constants.gd` for layout constants
  - Load the same font as floating_text_renderer: `preload("res://assets/fonts/monogram-extended.ttf")` with FontVariation (embolden 0.3 regular, 0.5 bold)
  - Implement `spawn(events: Dictionary)` method that extracts: lines_cleared, is_tspin, is_tspin_mini, is_back_to_back, back_to_back_count, combo_count
  - Implement `spawn_level_up()` method for level-up display
  - Implement `clear()` method to clear all active texts
  - Text layout (top to bottom, right-aligned to `BOARD_OFFSET.x - 8`):
    1. **B2B line** (if is_back_to_back): "B2B x{count}" in golden color (Color(1.0, 0.85, 0.0))
    2. **Clear type** (always): "SINGLE" / "DOUBLE" / "TRIPLE" / "TETRIS" / "T-SPIN ..." — large text, color-coded (same as `_get_score_color` from floating_text_renderer)
    3. **Combo line** (if combo >= 1): "{combo+1} COMBO" — color-coded by combo level (same as `_get_combo_color`)
  - Animation: Each text entry has a timer. Scale punch on spawn (1.4x → 1.0x over 0.15s), hold for 0.5s, then fade out over 1.5s (total ~2s)
  - Only ONE active display at a time — new line clear replaces the previous one (no stacking)
  - Position: Text drawn to the LEFT of the board. Y position starts at approximately `BOARD_OFFSET.y + BUFFER_ROWS * CELL_SIZE + 60` (below HOLD panel, in the visible playfield zone). Right-align text using `HORIZONTAL_ALIGNMENT_RIGHT` with draw width extending from x=0 to `BOARD_OFFSET.x - 8`
  - Implement `update_display(delta: float)` for parent to call each frame (updates timer, handles fade)
  - Implement `_draw()` to render current active text with alpha/scale based on timer

  **Must NOT do**:
  - Do not add `class_name`
  - Do not use signals
  - Do not stack multiple text entries — one active display, replaced on new event
  - Do not show score (+N) — only clear type, B2B, combo
  - Do not use `load()` for script dependencies — use `preload()`

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: New file creation with moderate complexity — animation logic, text layout, multiple display modes
  - **Skills**: `[]`
    - No special skills needed — GDScript Node2D rendering
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: Not applicable — this is Godot GDScript, not web frontend

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3)
  - **Blocks**: Task 4
  - **Blocked By**: Task 3 (needs constants defined)

  **References**:

  **Pattern References**:
  - `scripts/floating_text_renderer.gd:1-28` — Font loading pattern with FontVariation. Copy this exactly for consistency
  - `scripts/floating_text_renderer.gd:35-44` — `update_texts()` pattern: timer increment, position update, removal on expiry. Adapt for single-entry display
  - `scripts/floating_text_renderer.gd:136-178` — `_draw()` pattern: alpha calculation from timer, scale punch, multi-line text rendering with `draw_string()`
  - `scripts/floating_text_renderer.gd:185-198` — `_get_action_label()`: exact action label strings for all line clear types. Copy this function
  - `scripts/floating_text_renderer.gd:230-249` — `_get_score_color()` and `_get_combo_color()`: color logic. Copy these functions
  - `scripts/particle_effects.gd:1-10` — Example of Node2D child script without class_name, preload pattern

  **API/Type References**:
  - `scripts/constants.gd:17` — `BOARD_OFFSET = Vector2(80, 86)`: left edge of the board. Panel text right-aligns to `BOARD_OFFSET.x - 8` (x=72)
  - `scripts/constants.gd:7-11` — Grid constants: CELL_SIZE=32, BUFFER_ROWS=4, VISIBLE_ROWS=20. Used to calculate Y position

  **External References**:
  - Godot `CanvasItem.draw_string()` docs — parameters: font, pos, text, alignment, width, font_size, color

  **WHY Each Reference Matters**:
  - `floating_text_renderer.gd` is the primary reference — the new script replaces it, so it should follow the same patterns for font loading, color logic, and action labels, but with different positioning and single-entry behavior
  - `constants.gd` board layout values determine exact positioning of the panel text

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Script loads without errors
    Tool: Bash
    Preconditions: left_panel_display.gd exists in scripts/
    Steps:
      1. Run: godot --headless --path . --quit-after 2 2>&1
      2. Check output for parse errors mentioning left_panel_display
    Expected Result: No parse errors related to the new script
    Failure Indicators: GDScript parse error or missing preload reference
    Evidence: .sisyphus/evidence/task-2-script-loads.txt

  Scenario: Script has all required methods
    Tool: Bash (grep verification)
    Preconditions: Script exists
    Steps:
      1. Verify func spawn(events: Dictionary) exists
      2. Verify func spawn_level_up() exists
      3. Verify func update_display(delta: float) exists
      4. Verify func clear() exists
      5. Verify func _draw() exists
      6. Verify no class_name declaration
    Expected Result: All 5 methods present, no class_name
    Failure Indicators: Missing method or unexpected class_name
    Evidence: .sisyphus/evidence/task-2-methods-check.txt
  ```

  **Commit**: YES (groups with Task 3)
  - Message: `feat(ui): create left panel combo display script`
  - Files: `scripts/left_panel_display.gd`, `scripts/constants.gd`
  - Pre-commit: `timeout 60 godot --headless --path . -d -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit`

- [x] 3. Add Left Panel Constants to constants.gd

  **What to do**:
  - In `scripts/constants.gd`: Add a new section `# LEFT PANEL DISPLAY` with:
    - `const LEFT_PANEL_X_RIGHT: float = 72.0` — Right edge of text area (BOARD_OFFSET.x - 8)
    - `const LEFT_PANEL_Y_START: float = 250.0` — Top of text display area (below HOLD panel, in visible zone: BOARD_OFFSET.y + BUFFER_ROWS * CELL_SIZE + 60 ≈ 86 + 128 + 36 = 250)
    - `const LEFT_PANEL_HOLD_DURATION: float = 0.5` — Time text stays at full opacity before fading
    - `const LEFT_PANEL_FADE_DURATION: float = 1.5` — Fade-out time
    - `const LEFT_PANEL_TOTAL_DURATION: float = 2.0` — Total display time (hold + fade)
    - `const LEFT_PANEL_TEXT_WIDTH: float = 72.0` — Width available for text rendering (0 to LEFT_PANEL_X_RIGHT)
    - `const LEFT_PANEL_ACTION_FONT_SIZE: int = 28` — Font size for clear type label
    - `const LEFT_PANEL_COMBO_FONT_SIZE: int = 36` — Font size for combo count (bigger, like Tetris Effect)
    - `const LEFT_PANEL_B2B_FONT_SIZE: int = 20` — Font size for B2B label (smaller accent)
    - `const LEFT_PANEL_LINE_GAP: float = 6.0` — Vertical gap between text lines

  **Must NOT do**:
  - Do not modify existing constants
  - Do not change section ordering or formatting convention

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Trivial — adding constant declarations to one file
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2)
  - **Blocks**: Tasks 2, 4
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `scripts/constants.gd:28-33` — Existing animation timing section. Follow same comment block style (`# ===...===`) and const naming convention (UPPER_SNAKE)
  - `scripts/constants.gd:16-17` — `DESIGN_WIDTH` and `BOARD_OFFSET` — used to calculate LEFT_PANEL_X_RIGHT

  **WHY Each Reference Matters**:
  - `constants.gd` formatting convention must be matched exactly (section headers, const style, typed declarations)
  - BOARD_OFFSET determines the right edge of the left panel area

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Constants are accessible from GDScript
    Tool: Bash
    Preconditions: constants.gd updated
    Steps:
      1. Run: godot --headless --path . --quit-after 2 2>&1
      2. Check no parse errors
    Expected Result: Clean load, no errors
    Failure Indicators: Parse error in constants.gd
    Evidence: .sisyphus/evidence/task-3-constants-load.txt
  ```

  **Commit**: YES (groups with Task 2)
  - Message: `feat(ui): create left panel combo display script`
  - Files: `scripts/constants.gd`, `scripts/left_panel_display.gd`

- [x] 4. Wire Left Panel into GameBoard + Remove Floating Text

  **What to do**:
  - In `scripts/game_board.gd`:
    1. Add preload: `const LeftPanelDisplayScript = preload("res://scripts/left_panel_display.gd")`
    2. Add variable: `var _left_panel: Node2D  # LeftPanelDisplay`
    3. In `_ready()` (after existing child creation, around line 44):
       - Remove `_text_renderer = FloatingTextRendererScript.new()` and its `add_child(_text_renderer)` (lines 41-42)
       - Add `_left_panel = LeftPanelDisplayScript.new()` and `add_child(_left_panel)`
    4. In `_process()`:
       - Replace `_text_renderer.update_texts(delta)` calls (lines 67 and 143) with `_left_panel.update_display(delta)`
       - Replace `_text_renderer.spawn(events)` call (line 127) with `_left_panel.spawn(events)`
       - Replace `_text_renderer.spawn_level_up(center)` call (line 137) with `_left_panel.spawn_level_up()`
    5. In `clear_floating_texts()` (line 51):
       - Replace `_text_renderer.clear()` with `_left_panel.clear()`
    6. Remove the `FloatingTextRendererScript` preload (line 7) and `_text_renderer` variable (line 16) — they're no longer used
    7. Update `back_to_back_count` in the events passed to `_left_panel.spawn()` — the event dict from `game_logic.gd` will already contain it (from Task 1)

  **Must NOT do**:
  - Do not delete `floating_text_renderer.gd` file — just disconnect it. It can be removed in a future cleanup
  - Do not change game logic, VFX, particles, or SFX behavior
  - Do not modify the event dictionary routing — just change the receiver
  - Do not change draw order — left panel should be a child of GameBoard like text_renderer was

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Integration task touching a 333-line coordinator file. Requires careful line-by-line replacement to avoid breaking event flow.
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (sequential after Wave 1)
  - **Blocks**: Task 5
  - **Blocked By**: Tasks 1, 2, 3

  **References**:

  **Pattern References**:
  - `scripts/game_board.gd:6-8` — Existing preload pattern for child scripts. Add LeftPanelDisplayScript here
  - `scripts/game_board.gd:16` — Existing `_text_renderer` variable. Replace with `_left_panel`
  - `scripts/game_board.gd:40-45` — Child creation in `_ready()`. Replace FloatingTextRenderer with LeftPanelDisplay
  - `scripts/game_board.gd:51-56` — `clear_floating_texts()`. Update to call `_left_panel.clear()`
  - `scripts/game_board.gd:67` — `_text_renderer.update_texts(delta)` during clear animation. Replace
  - `scripts/game_board.gd:127` — `_text_renderer.spawn(events)` on line clear. Replace
  - `scripts/game_board.gd:137` — `_text_renderer.spawn_level_up(center)` on level up. Replace
  - `scripts/game_board.gd:143` — `_text_renderer.update_texts(delta)` in main process loop. Replace

  **WHY Each Reference Matters**:
  - Each line reference is a specific call site that must be changed. Missing ANY one will cause the old renderer to be partially active or the new one to not update correctly
  - The draw order (add_child position) determines z-order — left panel should be added where text_renderer was

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Game launches without crashes
    Tool: Bash
    Preconditions: All Wave 1 tasks complete
    Steps:
      1. Run: timeout 10 godot --headless --path . --quit-after 5 2>&1
      2. Check for no fatal errors or crashes
    Expected Result: Clean exit, no errors mentioning text_renderer or left_panel
    Failure Indicators: Null reference error, missing method, crash on startup
    Evidence: .sisyphus/evidence/task-4-launch-clean.txt

  Scenario: No references to _text_renderer remain in game_board.gd
    Tool: Bash (grep)
    Preconditions: Edits complete
    Steps:
      1. Search game_board.gd for "_text_renderer"
      2. Search game_board.gd for "FloatingTextRendererScript"
    Expected Result: Zero matches for both
    Failure Indicators: Any remaining reference to old renderer
    Evidence: .sisyphus/evidence/task-4-no-old-refs.txt

  Scenario: All existing GUT tests still pass
    Tool: Bash
    Preconditions: Integration complete
    Steps:
      1. Run: timeout 60 godot --headless --path . -d -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit
      2. Assert 0 failures
    Expected Result: All 68+ tests pass
    Failure Indicators: Any test failure
    Evidence: .sisyphus/evidence/task-4-tests-pass.txt
  ```

  **Commit**: YES
  - Message: `refactor(board): wire left panel display, disconnect floating text renderer`
  - Files: `scripts/game_board.gd`
  - Pre-commit: `timeout 60 godot --headless --path . -d -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit`

- [ ] 5. Visual QA — Full Gameplay Verification

  **What to do**:
  - Launch the game and play through multiple scenarios to verify the left panel display works correctly
  - Test scenarios:
    1. **Single line clear**: Verify "SINGLE" appears on left panel, fades after ~2s
    2. **Double/Triple/Tetris**: Verify correct label, larger/colored text
    3. **Consecutive clears (combo)**: Verify "2 COMBO", "3 COMBO" etc. appears and increments
    4. **Combo break**: Verify combo text disappears after 2 pieces without clearing
    5. **T-Spin**: Verify "T-SPIN SINGLE", "T-SPIN DOUBLE" labels
    6. **Back-to-back**: Verify "B2B x1", "B2B x2" etc. on consecutive Tetris/T-spin
    7. **B2B break**: Verify B2B counter resets when broken
    8. **Level up**: Verify "LEVEL UP!" appears on left panel
    9. **No floating text**: Verify NO text appears floating over the board
    10. **Text positioning**: Verify text is to the left of the board, below HOLD, readable
    11. **Animation**: Verify scale punch on appearance, smooth fade out
  - Capture screenshots for each scenario

  **Must NOT do**:
  - Do not modify any code — this is verification only
  - Do not skip any scenario

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Comprehensive visual verification requiring gameplay interaction through multiple scenarios
  - **Skills**: `['playwright']`
    - `playwright`: For browser-based verification if running web export, or tmux for desktop

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (after Task 4)
  - **Blocks**: Final verification wave
  - **Blocked By**: Task 4

  **References**:

  **Pattern References**:
  - `scripts/scoring.gd:27-29` — combo_count and back_to_back logic to understand when each display triggers

  **WHY Each Reference Matters**:
  - Understanding scoring behavior is needed to know what gameplay actions trigger each display type

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Left panel shows line clear type correctly
    Tool: interactive_bash (tmux) — launch Godot game
    Preconditions: Game running, gameplay active
    Steps:
      1. Launch game: godot --path . scenes/main.tscn
      2. Start a game (press start button)
      3. Play until a line is cleared
      4. Observe left panel area — text should appear showing clear type
      5. Wait 2+ seconds — text should fade out
    Expected Result: Clear type label visible on left side, fades after ~2s
    Failure Indicators: No text appears, text appears on board instead of left side, text doesn't fade
    Evidence: .sisyphus/evidence/task-5-line-clear-display.png

  Scenario: Combo counter increments on consecutive clears
    Tool: interactive_bash (tmux)
    Preconditions: Game running
    Steps:
      1. Clear a line — observe no combo text (first clear, combo_count=0)
      2. Clear another line immediately — observe "2 COMBO" on left panel
      3. Clear another — observe "3 COMBO"
    Expected Result: Combo count increments correctly on consecutive clears
    Failure Indicators: Wrong combo number, no combo text, combo appears on first clear
    Evidence: .sisyphus/evidence/task-5-combo-increment.png

  Scenario: No floating text over the board
    Tool: interactive_bash (tmux)
    Preconditions: Game running
    Steps:
      1. Clear lines in various ways
      2. Observe the board area (center of playfield)
      3. Verify NO floating text appears over the board
    Expected Result: Board area is clean — no floating text, no score popup
    Failure Indicators: Any text floating over the board
    Evidence: .sisyphus/evidence/task-5-no-floating-text.png
  ```

  **Commit**: NO (verification only)

---

## Final Verification Wave

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. Verify: left panel shows clear type + B2B + combo, floating text removed, all tests pass, level-up on left panel. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run GUT test suite headless. Review all changed files for: typing compliance, tab indentation, preload convention, no class_name on Node scripts, no signals for game events. Check for AI slop: excessive comments, over-abstraction.
  Output: `Build [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high` (+ `playwright` skill)
  Start from clean state. Launch game, play through several line clears: single, double, triple, tetris, consecutive combos, B2B T-spins. Verify text appears on left side, animates, fades. Verify NO floating text appears over the board. Screenshot evidence for each scenario.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff. Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **Wave 1**: `feat(scoring): add back-to-back count tracking` — scoring.gd, game_logic.gd
- **Wave 1**: `feat(ui): create left panel combo display script` — left_panel_display.gd, constants.gd
- **Wave 2**: `refactor(board): wire left panel, remove floating text` — game_board.gd
- **Final**: `test(scoring): add B2B counter unit test` — test/unit/

---

## Success Criteria

### Verification Commands
```bash
# Run all tests — expect all pass (68+ tests)
timeout 60 godot --headless --path . -d -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit

# Run game — expect no crash, visual verification
godot --path . scenes/main.tscn
```

### Final Checklist
- [ ] Left panel shows clear type on line clear
- [ ] Left panel shows "B2B xN" on consecutive Tetris/T-spin clears
- [ ] Left panel shows "N COMBO" on consecutive line clears
- [ ] Text animates in and fades out (~2 seconds)
- [ ] No floating text over the board
- [ ] Level-up text on left panel
- [ ] All GUT tests pass
- [ ] No class_name on new Node script
- [ ] Tab indentation, typed GDScript throughout
