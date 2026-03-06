# Left Panel Combo Display — Learnings

_Conventions, patterns, and gotchas discovered during implementation._

---

## Session Start: 2026-03-06T11:27:36.583Z

Initial context:
- Tetris game in Godot 4.6, GDScript, pure logic (RefCounted) + Node rendering separation
- Scoring system has `back_to_back: bool` but no count — need to add `back_to_back_count: int`
- Existing floating text renderer shows score popups over board — replacing with left panel display
- combo_count starts at -1, displayed as `combo_count + 1` for human-readable format
- Board layout: BOARD_OFFSET = Vector2(80, 86), only 80px left margin

## Wave 1, Task 3: Left Panel Constants Added

**DATE:** 2026-03-06

### What We Did
Added LEFT PANEL DISPLAY section to `scripts/constants.gd` (lines 72-84):
- 10 new constants for panel positioning, animation timing, and font sizes
- All values derived from prior design decisions (decisions.md)

### Key Learnings
1. **Comment block consistency**: Godot project uses `# =============================================================================` headers consistently across all sections
2. **Constant naming**: All panel-related constants use `LEFT_PANEL_` prefix + UPPER_SNAKE pattern
3. **Type safety**: All constants properly typed (`: float` / `: int`)
4. **Value derivation**:
   - RIGHT edge at x=72 (BOARD_OFFSET.x 80 minus 8px margin)
   - Y start at 250 (BUFFER_ROWS=4 × CELL_SIZE=32 = 128, + BOARD_OFFSET.y=86, + gap=36 ≈ 250)
   - Font sizes chosen for visual hierarchy: Combo largest (36), Action mid (28), B2B accent (20)

### Godot Validation
✓ File loads without parse errors
✓ No type mismatches detected
✓ Ready for floating_text_renderer.gd to consume these constants

### Next Tasks
- Task 4: floating_text_renderer enhancements
- Task 5: Panel rendering integration

## Task 2 — Script Implementation

Created `scripts/left_panel_display.gd` (180 lines, Node2D without class_name).

**Key patterns copied from floating_text_renderer.gd**:
- Font loading with FontVariation (embolden 0.3 regular, 0.5 bold) in `_ready()` — lines 14-27
- Helper functions `_get_action_label()`, `_get_score_color()`, `_get_combo_color()` — exact copies
- `_draw()` pattern: alpha fade calculation, scale punch animation, multi-line layout with y_cursor

**Implementation details**:
- Single active display: Dictionary with keys {action_text, b2b_text, combo_text, timer, duration, color, position, combo_count}
- Replace on new event: `spawn()` overwrites `_active_display` — no stacking
- Animation: scale punch (Constants.SCALE_PUNCH → 1.0 over SCALE_SETTLE_TIME), hold (LEFT_PANEL_HOLD_DURATION), fade (LEFT_PANEL_FADE_DURATION)
- Text layout: B2B (if present) → Action → Combo (if present), right-aligned to LEFT_PANEL_X_RIGHT
- Font sizes from constants: ACTION=28, COMBO=36, B2B=20 (scaled by scale_factor during punch)
- Alpha calculation: hold at 1.0, then fade linearly after hold_duration
- Display removal: if timer >= duration, set `_active_display = {}`

**Verification**:
- Script loads without parse errors (Godot --headless --quit-after 2)
- All 6 required methods present (spawn, spawn_level_up, clear, update_display, _draw, _ready)
- No class_name (follows Node rendering script convention)
- Right-aligned text with HORIZONTAL_ALIGNMENT_RIGHT
- combo_count displayed as `combo + 1` for human-readable format

**Next steps**: Task 3 (constants already done), Task 4 (scene integration), Task 5 (wiring)

---

## Task 1 (Wave 1) — B2B Counter Increment Implementation

**DATE:** 2026-03-06

### What We Did
Implemented B2B count tracking in scoring system for event propagation to UI layer.

**Changes made:**
1. Added `var back_to_back_count: int = 0` to `scripts/scoring.gd` (line 29)
2. Increment counter on consecutive B2B clears: `back_to_back_count += 1` (line 58)
3. Initialize counter to 1 on first qualifying clear: `if not back_to_back: back_to_back_count = 1` (lines 83-84)
4. Reset counter to 0 on non-qualifying clear: `back_to_back_count = 0` (line 88)
5. Reset counter in `reset()` method: `back_to_back_count = 0` (line 147)
6. Propagate to events dict in `game_logic.gd`: `events["back_to_back_count"] = scoring.back_to_back_count` (line 387)

### Key Learnings

**B2B State Machine:**
- B2B qualifies on: `lines == 4` (Tetris) OR `is_tspin` (any T-spin)
- Counter starts at 0, increments when B2B is already true AND new clear qualifies
- Counter initializes to 1 when B2B transitions from false→true on qualifying clear
- Counter resets to 0 when B2B breaks (non-qualifying clear with lines > 0)
- Counter unchanged on no-clear (lines == 0) — combo grace period doesn't affect B2B

**Implementation pattern matches combo_count:**
- Similar state management: combo_count starts -1, B2B counter starts 0
- Similar reset logic: both reset in reset() method
- Differs: combo has "grace pieces" mechanic, B2B counter doesn't

**Event propagation:**
- New field added alongside existing `is_back_to_back: bool` (which is the PREVIOUS B2B state)
- `back_to_back_count` represents CURRENT streak length (0 if no active streak)
- Placed after `combo_count` in events dict for logical grouping (line 387)

### Testing

Created 12 comprehensive unit tests in `test/unit/test_b2b_counter.gd`:
- Initialization: counter at 0
- Activation: counter set to 1 on first qualifying clear
- Increment: counter increases on consecutive qualifying clears (mixed Tetris/T-spin)
- Reset: counter to 0 on non-qualifying clears (single/double/triple)
- Persist: counter unchanged on no-clear
- Sequence: counter resets properly between B2B streaks

**Test results:** 12/12 PASSED, 80/80 total tests PASSED (68 existing + 12 new)

### Verification
- ✓ All code changes syntactically valid (Godot parsed without errors)
- ✓ No type mismatches or missing fields
- ✓ No regressions in existing test suite
- ✓ Event propagation layer ready for UI consumption

### Next Steps
- UI layer (Task 2+) consumes `back_to_back_count` from events dict
- Display counter value in left panel (already designed in previous session)

## Task 4 — Left Panel Integration (Wave 2)

**DATE:** 2026-03-06

### Changes Applied

All 8 replacements successfully applied to `scripts/game_board.gd`:

1. **Line 7**: Replaced `FloatingTextRendererScript` preload with `LeftPanelDisplayScript`
2. **Line 16**: Replaced `_text_renderer` variable with `_left_panel` 
3. **Lines 41-42**: Replaced `_text_renderer` instantiation with `_left_panel` in `_ready()`
4. **Line 52**: Replaced `_text_renderer.clear()` with `_left_panel.clear()`
5. **Line 67**: Replaced `_text_renderer.update_texts(delta)` with `_left_panel.update_display(delta)` (during clear animation)
6. **Line 127**: Replaced `_text_renderer.spawn(events)` with `_left_panel.spawn(events)` (on line clear)
7. **Line 137**: Replaced `_text_renderer.spawn_level_up(center)` with `_left_panel.spawn_level_up()` — **removed center parameter** per new API signature
8. **Line 143**: Replaced `_text_renderer.update_texts(delta)` with `_left_panel.update_display(delta)` (final update)

**Indentation fix required**: Initial edits created incorrect indentation in lines 126-141 (events scope issue). Fixed by restoring proper tab indentation under `if game_logic != null:` block.

### Verification Results

✅ **Grep check**: `grep -n "_text_renderer\|FloatingTextRendererScript" scripts/game_board.gd` → NO OUTPUT (all references successfully removed)

✅ **LSP diagnostics**: Not available (GDScript LSP not configured in environment)

✅ **Test suite**: All 80 tests pass (0.405s runtime)
- 7 scripts tested
- 214 assertions passed
- No failures

✅ **Game launch**: `godot --headless --path . scenes/main.tscn --quit-after 2` → Clean exit
- Only warnings about scene file UIDs (pre-existing, unrelated to changes)
- Script loads successfully, no runtime errors

### Issues Encountered

**Indentation scope error (fixed)**: Initial batch edit accidentally placed lines 133-141 (`if events.get("level_up")` and `if events.get("game_over")`) outside the `if game_logic != null:` block, causing "Identifier 'events' not declared" parse error. Root cause: incorrect indentation level when replacing line 127 spawn call. Fixed by restoring proper tab depth for entire events-handling block (lines 126-141).

**Lesson learned**: When replacing multiple lines within nested scopes, verify full context block indentation in single pass rather than line-by-line edits.

### API Signature Change Notes

Critical difference between FloatingTextRenderer and LeftPanelDisplay:
- **OLD**: `spawn_level_up(center: Vector2)` — took center position parameter
- **NEW**: `spawn_level_up()` — NO PARAMETERS (left panel uses fixed position, ignores center)

This signature change was correctly applied at line 137 by removing the `center` argument.

### Integration Status

**Wave 2 COMPLETE**: Left panel display successfully wired into GameBoard, floating text renderer fully disconnected (file not deleted per plan guardrails). System ready for Wave 3 (ghost toggle + combo streak backfill).


## Task: Redesign left_panel_display.gd for Persistent Counters

**DATE:** 2026-03-06

### What We Changed
- Removed transient display logic (single-display dict, timer, fade animation, action labels)
- Added persistent counter state (`_combo_count: int = -1`, `_b2b_count: int = 0`)
- Added update methods (`update_combo()`, `update_b2b()`, `clear_combo()`, `clear_b2b()`)
- Simplified `_draw()` to render both counters simultaneously without animation
- Reduced file from 179 lines to 92 lines

### Key Learnings
- Persistent display = state variables + conditional rendering, no timers
- Dual counter rendering requires y_cursor accumulation with line gaps
- Display rules: B2B when count > 0, combo when count >= 1 (shown as count+1)
- Font sizes create visual hierarchy: combo (36px) > B2B (20px)
- Removed unused _font variant (kept _font_bold only, embolden=0.5)

### Implementation Details
- B2B counter drawn first at y=250, golden color (1.0, 0.85, 0.0)
- Combo counter drawn below B2B, color-coded by intensity via `_get_combo_color()`
- Right-aligned text: `draw_string(..., Vector2(0, y), text, HORIZONTAL_ALIGNMENT_RIGHT, 72.0, ...)`
- Text box spans [0..72], right edge at x=72 (LEFT_PANEL_X_RIGHT)
- Line gap of 6px between counters

### Verification
- ✓ Parse check clean (no errors mentioning left_panel_display)
- ✓ 80/80 tests pass
- ✓ All new methods present: update_combo(), update_b2b(), clear_combo(), clear_b2b(), clear()
- ✓ Old methods removed: spawn(), spawn_level_up(), update_display()

### API Usage Pattern (for game_board.gd integration)
```gdscript
# On piece lock event:
if events["combo_count"] >= 1:
    left_panel.update_combo(events["combo_count"])
else:
    left_panel.clear_combo()

if events["back_to_back_count"] > 0:
    left_panel.update_b2b(events["back_to_back_count"])
elif events.get("b2b_broken", false):
    left_panel.clear_b2b()

# On game reset:
left_panel.clear()  # Clears both counters
```

## Task: Wire Left Panel Alongside Floating Text

**DATE:** 2026-03-06

### What We Changed
- Added LeftPanelDisplayScript preload and _left_panel variable to game_board.gd
- Instantiated _left_panel as child (draw order: text → left panel → particles)
- Added left panel counter updates on line clear events (combo/B2B)
- Added left panel clear() call in clear_floating_texts()
- Kept _text_renderer unchanged (dual system, not replacement)

### Integration Points
- Preload: line 8 (after FloatingTextRendererScript)
- Variable: line 18 (after _text_renderer)
- Instantiation: lines 46-47 (after _text_renderer, before _particles)
- Update calls: lines 133-147 (after line clear event handling)
- Clear call: line 54 (in clear_floating_texts())

### Key Learnings
- Dual renderer system: transient (floating text) + persistent (left panel)
- Both receive events independently, no conflict
- Left panel API: update_combo/update_b2b for changes, clear_combo/clear_b2b for resets
- Draw order preserved: text → left panel → particles (z-order by add_child sequence)
- Combo logic: combo >= 1 shows counter, combo == -1 clears counter, combo == 0 no change
- B2B logic: b2b_count > 0 shows counter, b2b_count == 0 + lines_cleared > 0 clears counter

### Verification
- ✓ Parse check clean (only UID warnings, unrelated)
- ✓ 80/80 tests pass (0.418s)
- ✓ Both renderers present in game_board.gd (grep verified)
- ✓ No spawn() calls to left panel (method doesn't exist, grep returned empty)

### Code Changes Summary
**File:** scripts/game_board.gd (+18 lines)
- Added const LeftPanelDisplayScript preload
- Added var _left_panel: Node2D
- Added _left_panel instantiation and add_child()
- Added combo/B2B counter update logic in line clear handler
- Added _left_panel.clear() in clear_floating_texts()

### Integration Pattern Confirmed
```gdscript
# On line clear event:
if events.get("lines_cleared", 0) > 0:
    _text_renderer.spawn(events)  # Transient feedback
    # ... VFX/particles ...
    
    # Persistent counter updates
    var combo = events.get("combo_count", -1)
    var b2b_count = events.get("back_to_back_count", 0)
    
    if combo >= 1:
        _left_panel.update_combo(combo)
    elif combo == -1:
        _left_panel.clear_combo()
    
    if b2b_count > 0:
        _left_panel.update_b2b(b2b_count)
    elif b2b_count == 0:
        _left_panel.clear_b2b()
```

### Next Steps
- Visual QA to verify both systems display correctly
- Confirm left panel positioning (Constants.LEFT_PANEL_X_RIGHT, etc.)
- Test combo/B2B counter interaction in live gameplay
