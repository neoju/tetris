# scenes/particles/ — CPUParticles2D Effects

7 particle scenes + 7 scripts (488 LOC). All effects spawned by `scripts/particle_effects.gd`.

## EFFECT CATALOG
| Scene / Script | Lines | Type | Trigger |
|----------------|-------|------|---------|
| `CountdownEffect` | 143 | Node2D (text + bursts) | Game start countdown; emits `countdown_finished` signal |
| `ComboFireEffect` | 91 | CPUParticles2D continuous | Combo >= threshold; `set_intensity(combo)` / `stop()` |
| `ComboLightningEffect` | 85 | CPUParticles2D continuous | Combo >= threshold; side-edge bolts; `set_intensity()` / `stop()` |
| `LevelUpEffect` | 53 | CPUParticles2D one-shot | Level up; gold radial burst |
| `ClearParticles` | 49 | CPUParticles2D one-shot | Line clear; `configure(pos, color, amount, width)` |
| `HardDropImpact` | 38 | CPUParticles2D one-shot | Hard drop; `configure(pos, color, amount, velocity)` |
| `LockSparks` | 29 | CPUParticles2D one-shot | Piece lock; `configure(pos, color)` |

## PATTERNS
- One-shot effects: `one_shot = true`, `finished.connect(queue_free)` — self-cleanup
- Continuous effects: `set_intensity(level)` scales amount/velocity/lifetime; `stop()` sets `emitting = false` then `queue_free` after lifetime fade
- All visuals configured in `_ready()` (color ramps, scale curves, blend mode ADD)
- Each scene is a single root node (.tscn) with its script attached
- No scene nesting — `particle_effects.gd` instantiates via `preload().instantiate()` + `configure()` + `add_child()`

## ADDING A NEW EFFECT
1. Create `scenes/particles/NewEffect.tscn` (CPUParticles2D root)
2. Create `scenes/particles/NewEffect.gd` with `configure()` API
3. Add `preload()` constant in `scripts/particle_effects.gd`
4. Add `spawn_new_effect()` method in `particle_effects.gd`
5. Call from `scripts/game_board.gd` when event dict triggers it

## SPECIAL: CountdownEffect
Not a CPUParticles2D — extends Node2D. Draws countdown text via `_draw()`, spawns `LevelUpEffect` bursts on each step. `game_manager.gd` instantiates it and connects `countdown_finished` signal to begin play.
