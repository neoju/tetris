# scripts/ — Core Game Logic & Rendering

20 GDScript files. Pure logic (RefCounted) separated from Node rendering layer.

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
| `constants.gd` | 72 | All magic numbers: grid sizes, timing, VFX, input, audio, design width |
| `board_vfx.gd` | 151 | VFX state: clear animation timer/data, screen shake, border glow. No rendering. |

### Static Data (no extends)
| Script | Lines | Purpose |
|--------|-------|---------|
| `tetromino_data.gd` | 90 | Piece shapes, colors, spawn positions (Y-negated from wiki) |
| `wall_kick_data.gd` | 187 | SRS kick tables for I and JLSTZ (Y-negated from wiki) |

### Node-Based (rendering/UI/audio)
| Script | Lines | Purpose |
|--------|-------|---------|
| `game_board.gd` | 333 | Node2D coordinator: `_draw()` grid/pieces/ghost/clear-overlay/border-glow/starfall, event→SFX routing, delegates VFX state to BoardVfx, text to FloatingTextRenderer, particles to ParticleEffects |
| `floating_text_renderer.gd` | 249 | Node2D child of GameBoard: spawns/animates/draws floating score/action/combo text |
| `particle_effects.gd` | 233 | Node2D child of GameBoard: line clear bursts, lock sparks, hard drop impact, combo fire/lightning, level up particles |
| `game_manager.gd` | 217 | State machine (MENU/COUNTDOWN/PLAYING/PAUSED/GAME_OVER), wires UI ↔ GameBoard, viewport centering, background selection. Ghost toggle wiring |
| `sfx_manager.gd` | 35 | Autoload singleton, AudioStreamPlayer pool, `play(name)` API |
| `music_manager.gd` | 246 | Autoload singleton, level-based track selection, preload/play/stop/pause/toggle API |
| `background_manager.gd` | 109 | CanvasLayer -1, hardcoded manifest of 24 background sets, random selection, cover-mode parallax shader layers, viewport resize |
| `ui_panel.gd` | 33 | HUD (scene: `hud.tscn`): score/level/lines labels, wires PieceOverlay |
| `piece_overlay.gd` | 78 | Draws hold + next piece miniatures |

## DEPENDENCY GRAPH
```
game_board.gd ←── thin coordinator
├── constants.gd
├── board_vfx.gd (RefCounted) ←── VFX state
│   └── constants.gd
├── floating_text_renderer.gd (Node2D child) ←── text rendering
│   └── constants.gd
├── particle_effects.gd (Node2D child) ←── particle spawning
│   ├── constants.gd
│   └── tetromino_data.gd
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
└── grid.gd (direct ref for _draw)

game_manager.gd ──→ game_board.game_logic (runtime reference)
game_manager.gd ──→ background_manager.gd (select_random on new game)
ui_panel.gd ──→ game_logic (via setter)
piece_overlay.gd ──→ tetromino_data.gd + game_logic (reads hold/next)
sfx_manager.gd ──→ constants.gd (pool size, volume)
music_manager.gd ──→ constants.gd (autoload singleton)
background_manager.gd ──→ parallax_layer.gdshader (load at runtime)
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
1. **game_logic.gd** (423 lines) — Core loop. Key sections:
   - `update(delta)`: input → gravity → lock → events
   - `_lock_piece()`: placement, scoring, T-spin detection, pending_clear
   - `_begin_hard_drop()` / `_update_hard_drop_animation()`: visual hard drop

## CONVENTIONS (scripts-specific)
- RefCounted logic classes: always use `class_name`, always `preload().new()`
- Node scripts without `class_name`: game_board, sfx_manager, ui_panel, piece_overlay, floating_text_renderer, particle_effects, background_manager, music_manager
- Constants accessed via `Constants.SYMBOL` (class_name reference, no instantiation needed)
- All wall kick / shape data: Y-values negated from Tetris wiki (Godot Y+ = down)
- GameBoard child nodes (FloatingTextRenderer, ParticleEffects) created via `preload().new()` + `add_child()` in `_ready()` — draw order is tree order
