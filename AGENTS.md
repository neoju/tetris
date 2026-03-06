# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-06
**Commit:** b695fb0
**Branch:** master

## OVERVIEW
Tetris Guideline-compliant game in Godot 4.6 / GDScript. Pure logic classes (RefCounted) separated from Node rendering. GL Compatibility renderer, portrait 480×1040 viewport, web export target.

## STRUCTURE
```
./
├── scripts/         # Core game logic + rendering (15 .gd files) — SEE scripts/AGENTS.md
├── scenes/          # .tscn scene files (main, board, HUD, screens, particles)
│   └── particles/   # CPUParticles2D effects (4 scenes + 4 scripts)
├── test/unit/       # GUT unit tests (6 files) — SEE test/unit/AGENTS.md
├── tools/           # Python asset generators (block sprites, SFX WAVs)
├── assets/          # Static: blocks/, fonts/, sfx/, shaders/, ui/
└── addons/gut/      # VENDOR: GUT 9.6.0 test framework — DO NOT EDIT
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Change game rules | `scripts/game_logic.gd` | Pure RefCounted, returns event dict |
| Change visuals/VFX | `scripts/game_board.gd` | 766 lines, `_draw()` based rendering |
| Add/change piece data | `scripts/tetromino_data.gd` + `wall_kick_data.gd` | Y-values NEGATED from wiki |
| Modify scoring | `scripts/scoring.gd` | T-spin 3-corner rule, B2B, combos |
| Change input timing | `scripts/input_handler.gd` | DAS=0.167s, ARR=0.033s |
| Tweak constants | `scripts/constants.gd` | Grid sizes, timing, VFX, lock delay |
| Add sounds | `scripts/sfx_manager.gd` + `assets/sfx/` | Autoload singleton, pool of 4 players |
| Scene composition | `scenes/main.tscn` | Root=Main, script=game_manager.gd |
| Run tests | CLI command below | GUT headless |
| Regenerate assets | `tools/generate_blocks.py`, `tools/generate_sfx.py` | Python, PIL/stdlib |

## ARCHITECTURE

### Runtime Flow
```
project.godot → scenes/main.tscn → GameManager (state machine: MENU/PLAYING/PAUSED/GAME_OVER)
                                      ├── GameBoard (Node2D, rendering + VFX)
                                      │     └── GameLogic (RefCounted, pure logic)
                                      │           ├── Grid, Piece, BagRandomizer
                                      │           ├── Scoring, LockDelay, InputHandler
                                      │           └── returns event Dictionary per tick
                                      ├── HUD → PieceOverlay (hold + next 3)
                                      ├── TitleScreen / PauseMenu / GameOverScreen
                                      └── SfxManager (autoload singleton)
```

### Event Dictionary Pattern
`game_logic.update(delta)` returns `{lines_cleared, score_added, game_over, piece_locked, hold_swapped, level_up, moved, rotated, hard_dropped, soft_dropped, ...}`. GameBoard reacts in `_process()`. **No signals for game events.**

### Deferred Line Clear
`game_logic.pending_clear` flag → `game_board` animates (flash + dissolve) → calls `game_logic.complete_clear()` → rows actually removed from grid.

## CONVENTIONS
- Logic classes extend `RefCounted` (not Node) — instantiated via `preload().new()`
- Only autoload: `SfxManager` (project.godot `[autoload]`)
- Dependencies: `preload("res://scripts/...")` everywhere except sfx_manager (`load()` for runtime asset paths)
- Coordinate system: Y-positive = DOWN (Godot convention). Wiki SRS values Y-negated.
- Grid: rows 0-3 hidden buffer (spawn zone), rows 4-23 visible. 10 columns.
- Cell storage: `""` = empty, piece type string (`"I"`,`"J"`,`"L"`,`"O"`,`"S"`,`"T"`,`"Z"`) = filled
- `class_name` on most scripts EXCEPT: game_board, sfx_manager, ui_panel, piece_overlay
- Section headers use `# === ... ===` comment blocks
- Typed GDScript: explicit types on vars, params, return values
- Naming: snake_case functions/vars, PascalCase class_name, UPPER_SNAKE constants
- Tabs for indentation (not spaces)
- LF line endings (.gitattributes enforced)

## ANTI-PATTERNS (THIS PROJECT)
- DO NOT add `class_name` to autoload scripts — causes "hides autoload singleton" error
- DO NOT use signals for game events — event dictionary pattern is intentional
- DO NOT modify `addons/gut/` — vendored third-party
- DO NOT store game state in Node properties — logic lives in RefCounted classes
- DO NOT use `load()` for script dependencies — use `preload()` (except sfx_manager runtime paths)
- Wiki SRS values have INVERTED Y — always negate Y when porting from Tetris wiki

## COMMANDS
```bash
# Run game
godot --path . scenes/main.tscn

# Run all tests (headless)
timeout 60 godot --headless --path . -d -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit

# Regenerate block sprites
python3 tools/generate_blocks.py

# Regenerate SFX
python3 tools/generate_sfx.py

# Export web build (requires export templates installed)
godot --headless --path . --export-release "Web" build/index.html
```

## NOTES
- No CI/CD pipeline — tests run locally only
- Web export preset configured in `export_presets.cfg` (Emscripten, threads enabled)
- `.sisyphus/` contains project planning artifacts — not runtime code
- Test evidence shows 68/68 tests passing at last recorded run
- Constants centralized in `scripts/constants.gd` — check there before adding magic numbers
