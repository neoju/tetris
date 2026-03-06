# scripts/ — Core Game Logic & Rendering

15 GDScript files. Pure logic (RefCounted) separated from Node rendering layer.

## SCRIPT CATALOG

### Pure Logic (RefCounted) — instantiate with `preload().new()`
| Script | Lines | Purpose |
|--------|-------|---------|
| `game_logic.gd` | 423 | Core game loop: gravity, input, lock, hold. Returns event dict from `update(delta)` |
| `grid.gd` | 162 | Playfield storage, collision, line detection/clearing, perfect clear |
| `scoring.gd` | 171 | Points, T-spin detection (3-corner), B2B, combos, level progression |
| `piece.gd` | 87 | Single tetromino: position, rotation with wall kicks, ghost calculation |
| `bag_randomizer.gd` | 82 | 7-bag piece randomizer with peek support |
| `input_handler.gd` | 120 | DAS/ARR implementation, returns action dict to GameLogic |
| `lock_delay.gd` | 40 | Lock timer with move-count reset (0.5s, max 15 moves) |
| `constants.gd` | 64 | All magic numbers: grid sizes, timing, VFX, input, audio |

### Static Data (no extends)
| Script | Lines | Purpose |
|--------|-------|---------|
| `tetromino_data.gd` | 90 | Piece shapes, colors, spawn positions (Y-negated from wiki) |
| `wall_kick_data.gd` | 187 | SRS kick tables for I and JLSTZ (Y-negated from wiki) |

### Node-Based (rendering/UI/audio)
| Script | Lines | Purpose |
|--------|-------|---------|
| `game_board.gd` | 766 | Node2D renderer: `_draw()`, VFX, particles, clear animation, event consumption. `show_ghost` toggle |
| `game_manager.gd` | 149 | State machine (MENU/PLAYING/PAUSED/GAME_OVER), wires UI ↔ GameBoard. Ghost toggle wiring |
| `sfx_manager.gd` | 35 | Autoload singleton, AudioStreamPlayer pool, `play(name)` API |
| `ui_panel.gd` | 33 | HUD (scene: `hud.tscn`): score/level/lines labels, wires PieceOverlay |
| `piece_overlay.gd` | 78 | Draws hold + next piece miniatures |

## DEPENDENCY GRAPH
```
game_board.gd
├── constants.gd
├── game_logic.gd ←── core hub
│   ├── grid.gd
│   ├── piece.gd
│   │   ├── tetromino_data.gd
│   │   └── wall_kick_data.gd
│   ├── bag_randomizer.gd
│   ├── scoring.gd
│   ├── lock_delay.gd
│   ├── input_handler.gd
│   └── tetromino_data.gd
├── grid.gd
└── tetromino_data.gd

game_manager.gd ──→ game_board.game_logic (runtime reference)
ui_panel.gd ──→ game_logic (via setter)
piece_overlay.gd ──→ tetromino_data.gd + game_logic (reads hold/next)
sfx_manager.gd ──→ constants.gd (pool size, volume)
```

## EVENT DICTIONARY SCHEMA
`game_logic.update(delta)` returns:
```gdscript
{
    "moved": bool,              # Horizontal movement occurred
    "rotated": bool,            # Rotation occurred
    "hard_dropped": bool,       # Hard drop initiated
    "soft_dropped": bool,       # Soft drop active
    "hold_swapped": bool,       # Hold piece swapped
    "piece_locked": bool,       # Piece locked to grid
    "lines_cleared": int,       # Number of lines cleared (0-4)
    "score_added": int,         # Points earned this tick
    "game_over": bool,          # Game ended
    "level_up": bool,           # Level increased
    # On lock events, also includes:
    "locked_positions": Array[Vector2i],
    "locked_piece_type": String,
    "cleared_rows_data": Array[{row: int, cells: Array}],
    "combo_count": int,
    "is_tspin": bool,
    "is_tspin_mini": bool,
    "is_back_to_back": bool,
    "is_perfect_clear": bool,
}
```

## COMPLEXITY HOTSPOTS
1. **game_board.gd** (766 lines) — All rendering + VFX in one file. Key sections:
   - `_process()`: event consumption, clear animation state machine
   - `_draw()`: immediate-mode board/piece/ghost/floating text rendering
   - `_start_clear_animation()` / `_update_clear_anim()`: deferred clear protocol
2. **game_logic.gd** (423 lines) — Core loop. Key sections:
   - `update(delta)`: input → gravity → lock → events
   - `_lock_piece()`: placement, scoring, T-spin detection, pending_clear
   - `_begin_hard_drop()` / `_update_hard_drop_animation()`: visual hard drop

## CONVENTIONS (scripts-specific)
- RefCounted logic classes: always use `class_name`, always `preload().new()`
- Node scripts without `class_name`: game_board, sfx_manager, ui_panel, piece_overlay
- Constants accessed via `Constants.SYMBOL` (class_name reference, no instantiation needed)
- All wall kick / shape data: Y-values negated from Tetris wiki (Godot Y+ = down)
