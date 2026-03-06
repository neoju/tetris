# test/unit/ — GUT Unit Tests

6 test files, 66 tests total. Framework: GUT 9.6.0 (vendored in `addons/gut/`).

## TEST FILES
| File | Lines | Tests | Covers |
|------|-------|-------|--------|
| `test_grid.gd` | 211 | Grid placement, collision, line clear, perfect clear |
| `test_game_logic.gd` | 179 | GameLogic flows: spawn, gravity, hold, lock, combos, level up, game over |
| `test_rotation.gd` | 178 | Piece rotation, SRS wall kicks, ghost positions |
| `test_bag.gd` | 130 | 7-bag properties, peek, drought limits, reset |
| `test_scoring.gd` | 121 | Scoring formulas, T-spin, B2B, combos, level cap |
| `test_lock_delay.gd` | 81 | Lock timer, move reset, max moves |

## CONVENTIONS
- All tests `extends GutTest`
- Setup via `before_each()` — creates fresh instances per test
- Test functions: `test_<descriptive_name>()`
- Dependencies loaded with `const X = preload("res://scripts/...")` then `.new()`
- Assertions: `assert_true`, `assert_false`, `assert_eq`, `assert_not_null` (GUT API)
- Helper functions: underscore-prefixed (`_fill_row_except`, `_sorted_positions`)
- Section headers: `# === Test: Description ===`

## RUN COMMAND
```bash
timeout 60 godot --headless --path . -d -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit
```

## ADDING NEW TESTS
1. Create `test/unit/test_<module>.gd`
2. `extends GutTest` at top
3. Preload tested class: `const MyClass = preload("res://scripts/my_class.gd")`
4. Add `before_each()` for setup, `test_*()` functions for cases
5. Run the command above — GUT auto-discovers `test_*.gd` files
