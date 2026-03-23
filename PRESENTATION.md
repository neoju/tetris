# Godot for Web Games: Potential, AI Workflow & Comparison

**Presenter:** [Your Name]
**Date:** March 2026
**Demo:** Tetris — Guideline-compliant, built in Godot 4.6 + AI agent workflow

---

## 1. Godot's Potential for Web Games (Gambling Focus)

### 1.1 UI/UX Layer — Rich, Immediate

| Capability | Detail | Gambling Relevance |
|---|---|---|
| **Control nodes** | Button, Label, TextureRect, AnimatedSprite2D, RichTextLabel, containers — full retained-mode UI toolkit | Slot reels, bet panels, HUD overlays, chip trays |
| **Theme system** | Global `.tres` theme with per-control overrides; font, color, styleboxes all data-driven | Skin entire app to brand identity in one file |
| **Shader support** | Fragment + vertex shaders on any CanvasItem; GLSL-like syntax | Glow effects on wins, particle showers, animated card backs |
| **Particle system** | CPUParticles2D (web-safe) — burst/emission, gravity, color ramps, subnodes | Coin explosions, confetti, jackpot celebrations |
| **Tweens & AnimationPlayer** | Procedural tweens + timeline animation; easing curves built-in | Smooth reel spins, card flips, number roll-ups |
| **Responsive layout** | `canvas_items` stretch + `expand` aspect; anchor-based containers | Works phone-portrait to desktop-landscape |

**This Tetris demonstrates:** parallax shader backgrounds (24 sets), per-block textures, floating text renderer, screen shake, border glow, hard-drop starfall trails, 7 particle effect scenes — all running in the browser.

### 1.2 Game Logic Layer — Clean Separation

| Pattern | How Godot Enables It | Gambling Application |
|---|---|---|
| **RefCounted classes** | Pure logic in non-Node classes; no scene tree coupling | RNG engine, payout calculator, hand evaluator — all testable in isolation |
| **Event dictionary** | `update()` returns `{result, payout, bonus_triggered, ...}` — no signals needed | Deterministic game round: input → outcome → render |
| **Typed GDScript** | Static types on vars, params, returns; catches errors at parse time | Financial logic needs type safety |
| **Preload system** | `preload("res://...")` for compile-time dependency resolution | No runtime loading surprises in critical paths |

**This Tetris demonstrates:** `GameLogic` (RefCounted) returns event dict per frame → `GameBoard` (Node2D) only renders. Scoring, grid, piece, lock delay, input handler — all pure logic classes with 80 unit tests.

### 1.3 Networking & Multiplayer

| Feature | Status | Notes |
|---|---|---|
| **HTTPClient / HTTPRequest** | Built-in nodes | REST API calls for account, lobby, cashier |
| **WebSocketPeer** | Native class, works in web export | Real-time table state, live dealer feeds |
| **WebRTC** | Supported via GDExtension | P2P for social features |
| **ENetMultiplayer** | Not available in web builds | Use WebSocket instead |
| **MultiplayerAPI + RPCs** | Works over WebSocket transport | `@rpc` annotations for client-server calls |
| **SSL/TLS** | Supported in web via browser's TLS stack | Secure by default on HTTPS origins |

**For gambling:** WebSocket is the primary transport. Server-authoritative architecture is straightforward — client sends actions, server validates and returns outcomes. Godot's RPC system maps well to this.

### 1.4 Performance & Web Export

| Aspect | Detail |
|---|---|
| **Renderer** | GL Compatibility mode → WebGL 2. Runs on virtually all browsers (no WebGPU required) |
| **Export size** | ~15–25 MB WASM + PCK (depends on assets). Gzip/Brotli reduces to ~5–8 MB transfer |
| **Startup time** | 2–5 seconds on modern connections. Custom HTML shell for branded loading screen |
| **Frame rate** | Solid 60fps for 2D games. This Tetris: <2ms frame time in browser |
| **Threading** | Optional thread support (SharedArrayBuffer). Can be disabled for simpler CORS |
| **Audio** | OGG Vorbis, WAV. Web AudioContext integration. Auto-resume on user interaction |
| **Input** | Keyboard, mouse, touch — all work. Virtual keyboard experimental |
| **Caveats** | No filesystem access (use `user://` via IndexedDB). No native sockets (WebSocket only). CORS headers required for cross-origin |

**Configuration from this project:**
```
renderer = GL Compatibility
viewport = 480×1040 (portrait mobile-first)
stretch_mode = canvas_items
thread_support = false (simpler deployment)
custom_html_shell = yes (branded loader)
```

### 1.5 Compliance & Security Considerations

| Concern | Godot Approach |
|---|---|
| **RNG fairness** | Server-side RNG only. Client is purely a display layer. Godot's `RandomNumberGenerator` is fine for non-critical client VFX |
| **Anti-tampering** | GDScript compiles to bytecode in export. Not foolproof, but comparable to JS minification. Critical logic must live server-side |
| **Audit trail** | Event dictionary pattern naturally creates a log of every game action — easy to serialize for compliance |
| **Responsible gaming** | Timer/session tracking trivial in `_process()`. Popup system for break reminders |

---

## 2. Godot MCP & AI Agent Workflow

### 2.1 What is Godot MCP?

**MCP** (Model Context Protocol) is a bridge that lets AI coding agents (Cursor, Claude, etc.) directly interact with the Godot editor:

```
AI Agent ←→ MCP Server ←→ Godot Editor (running)
              ↓
         • Create/modify nodes
         • Edit scene trees
         • Run scenes
         • Inspect properties
         • Read project structure
```

### 2.2 The AGENTS.md Pattern

The knowledge base file (`AGENTS.md`) at the project root gives AI agents instant context:

```markdown
# What it contains:
- Project overview & architecture diagram
- File/folder map with "where to look" table
- Conventions (naming, typing, indentation)
- Anti-patterns (what NOT to do)
- CLI commands (run, test, export)
```

**Result:** Any AI agent reads this first and immediately knows:
- Where scoring logic lives (`scripts/scoring.gd`)
- That Y-values are negated from wiki
- Not to add `class_name` to autoloads
- How to run the 80-test suite

### 2.3 Practical AI Workflow Used in This Project

| Phase | AI Agent Action | Human Action |
|---|---|---|
| **Architecture** | Generate `AGENTS.md`, plan class structure | Review, adjust scope |
| **Scaffolding** | Create RefCounted classes, scene tree via MCP | Verify in editor |
| **Logic** | Implement SRS rotation, wall kicks, scoring formulas | Playtest, verify against Tetris guideline |
| **VFX** | Generate particle scenes, shader code, animation timing | Tune constants for feel |
| **Testing** | Write GUT unit tests, run headless | Review coverage, add edge cases |
| **Asset generation** | Python scripts for block sprites & SFX | Artistic direction |
| **Web export** | Configure export preset, custom HTML shell | Deploy & test in browser |

### 2.4 Tips for Efficient AI-Assisted Godot Development

1. **AGENTS.md is your multiplier.** Every minute spent documenting conventions saves 10 minutes of AI going in the wrong direction.

2. **RefCounted-first architecture.** Pure logic classes are trivial for AI to write and test. Node-coupled code is harder to verify.

3. **Event dictionary > signals for AI.** A single dict return is easier for AI to reason about than scattered signal connections.

4. **Use MCP for scene tree operations.** Let AI create nodes, set properties, wire up scenes through the editor bridge — fewer manual steps.

5. **Test-driven with GUT.** AI writes tests, you run them headless:
   ```bash
   timeout 60 godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -gexit
   ```

6. **Constants file as single source of truth.** AI can tune `HARD_DROP_CELLS_PER_SECOND: 125.0` without hunting through code.

7. **Iterative VFX tuning.** AI proposes values → you playtest → AI adjusts. The feedback loop is fast because constants are centralized.

---

## 3. Comparison: Godot vs PhaserJS vs PixiJS vs Unity for Web

### 3.1 Overview Matrix

| | **Godot 4.6** | **Phaser 3.8** | **PixiJS 8** | **Unity 6 (WebGL)** |
|---|---|---|---|---|
| **Language** | GDScript, C#, GDExtension | JavaScript/TypeScript | JavaScript/TypeScript | C# |
| **Paradigm** | Scene tree + nodes | Game framework | Rendering library | Component-based ECS |
| **Web export** | WASM + WebGL2 | Native JS | Native JS | WASM + WebGL2 |
| **Bundle size** | 15–25 MB (5–8 gzipped) | 0.5–2 MB | 0.2–0.5 MB | 30–60 MB (10–20 gzipped) |
| **Startup time** | 2–5s | <1s | <1s | 5–15s |
| **2D renderer** | Custom (GL Compat / Vulkan) | WebGL via Canvas | WebGL2, WebGPU | Custom (URP/HDRP) |
| **UI system** | Built-in Control nodes | DOM or custom | None (BYO) | uGUI / UI Toolkit |
| **Audio** | Built-in (AudioServer) | Web Audio API | None (BYO) | FMOD/Wwise/built-in |
| **Physics** | Built-in 2D/3D | Arcade/Matter.js | None | PhysX/Box2D |
| **IDE** | Godot Editor (free) | VS Code + browser | VS Code + browser | Unity Editor (license) |
| **License** | MIT (fully free) | MIT | MIT | Proprietary (runtime fee) |
| **Mobile web** | Good (GL Compat) | Excellent | Excellent | Poor (heavy) |

### 3.2 Gambling-Specific Comparison

| Criterion | Godot | Phaser | PixiJS | Unity |
|---|---|---|---|---|
| **Slot machine reels** | AnimatedSprite2D + Tween | Sprite + Timeline | Container + Ticker | Animator + DOTween |
| **Card games** | Node2D + shader flip | Sprite + tween | Sprite + GSAP | GameObject + shader |
| **Particle jackpots** | CPUParticles2D (7 params) | Emitter class | @pixi/particle-emitter | Particle System (full) |
| **Table games (roulette, etc.)** | Physics2D + draw_* | Arcade physics | Custom math | Rigidbody2D |
| **Live dealer overlay** | CanvasLayer + VideoStreamPlayer | DOM video + canvas | DOM video + stage | RenderTexture + Video |
| **Regulatory compliance** | WASM bytecode (moderate obfuscation) | JS (fully readable) | JS (fully readable) | IL2CPP WASM (good obfuscation) |
| **Multi-platform from same codebase** | Web + Android + iOS + Desktop | Web only | Web only | Web + all platforms |
| **AI agent tooling** | MCP + AGENTS.md + GUT tests | Standard JS tooling | Standard JS tooling | Limited (heavy editor) |

### 3.3 When to Choose What

| Choose **Godot** when... | Choose **Phaser** when... | Choose **PixiJS** when... | Choose **Unity** when... |
|---|---|---|---|
| You need cross-platform (web + mobile app) from one codebase | Web-only, need fast startup & tiny bundle | You want maximum rendering control with minimal framework | You already have a Unity team & need AAA-quality 3D |
| Rich built-in VFX (particles, shaders, tweens) matter | Team knows JS/TS well | Building a custom engine on top | Complex 3D casino environments |
| You want an integrated editor + AI workflow | Rapid prototyping of 2D games | Just need a sprite renderer, will BYO everything else | Existing asset store content needed |
| MIT license with no runtime fees is required | Bundle size must be <2 MB | Bundle size must be <500 KB | Enterprise support contract needed |
| Game logic isolation (RefCounted) helps with compliance | Simple game rules, no complex state | Embedding in existing web app (React, Vue) | Multi-year, large-team project |

### 3.4 The Verdict for Gambling Web Games

**Godot is the sweet spot** between Phaser/PixiJS (too low-level for complex games) and Unity (too heavy for web). Key advantages:

1. **15 MB is acceptable** for a gambling site — users are investing time/money, not bouncing
2. **Built-in UI system** means no fighting with DOM overlays for bet panels, chat, balance displays
3. **Cross-platform** means the same game ships to web, Android, iOS — crucial for gambling operators
4. **MIT license** — no per-install fees, no revenue share, no runtime royalties
5. **AI-friendly architecture** accelerates development of the many similar-but-different game variants gambling requires

---

## 4. Demo Video Script

### Scene 1: Opening (0:00–0:15)

**[Screen: Title card with project name]**

> "This is a Tetris game built entirely in Godot 4.6, exported to the web. But this talk isn't about Tetris — it's about why Godot is the right engine for web-based gambling games, and how AI agents made building this 10x faster."

### Scene 2: The Game in Action (0:15–0:45)

**[Screen: Live gameplay in browser — show T-spins, combos, Tetris clears]**

> "Let's start with what you're seeing. This runs in any browser — Chrome, Firefox, Safari. WebGL 2, no plugins. 60fps. Portrait layout for mobile-first."

**[Trigger a Tetris clear — show particles, screen shake, floating text]**

> "Every visual effect you see — the screen shake, the particle explosions, the dissolving lines, the starfall on hard drops — these are all built with Godot's 2D tools. CPUParticles2D, shader-driven parallax backgrounds, procedural drawing."

**[Show responsive resize — drag browser window narrow → wide]**

> "The layout adapts. Canvas-items stretch mode with expand aspect. Same game, phone to ultrawide."

### Scene 3: Architecture That Matters (0:45–1:30)

**[Screen: VS Code / Cursor showing code structure]**

> "Here's why this architecture matters for gambling. All game logic lives in pure RefCounted classes — no Node dependencies."

**[Show `game_logic.gd` — highlight the `update()` function returning event dict]**

> "Every frame, `update()` returns a dictionary: lines cleared, score added, was it a T-spin, is it game over. The rendering layer just reads this dict and reacts."

**[Show `scoring.gd` — highlight point values and T-spin detection]**

> "For a slot machine, replace this with: spin result, payout amount, bonus triggered, free spins remaining. Same pattern. The renderer animates reels, the logic class calculates outcomes."

**[Show unit tests running — terminal with 80/80 passing]**

> "80 unit tests, all headless. The scoring logic, grid operations, piece rotations — all tested without ever opening a browser. For gambling, this means your payout calculator is provably correct before it touches a pixel."

### Scene 4: AI Agent Workflow (1:30–2:15)

**[Screen: Cursor IDE with AI chat panel]**

> "Now the interesting part. This entire game was built with an AI agent workflow. Here's how."

**[Show AGENTS.md file]**

> "Step one: AGENTS.md. This file tells any AI agent everything about the project — architecture, conventions, anti-patterns, where to find things. It's the context that makes AI useful instead of annoying."

**[Show AI creating a particle effect via MCP]**

> "Step two: Godot MCP. The AI doesn't just write code — it talks directly to the Godot editor. Create nodes, set properties, build scene trees. I describe what I want, the AI builds it in the running editor."

**[Show AI writing a test, running it, fixing a bug]**

> "Step three: test-driven iteration. AI writes the test, runs it headless, sees the failure, fixes the code. For gambling, imagine: 'Write a test that verifies a 96.5% RTP over 10,000 simulated spins.' The AI writes it, runs it, and you have proof."

### Scene 5: Why Not Phaser or Unity? (2:15–2:45)

**[Screen: Comparison table from section 3]**

> "Quick comparison. Phaser and PixiJS are great if you're building a simple slot with JS. But when you need built-in particles, a real UI system, shaders, and cross-platform export — you're rebuilding half an engine."

> "Unity can do everything, but 30–60 MB bundles and 5–15 second load times are deal-breakers for web gambling where every second of load time costs players."

> "Godot sits in the middle. 15 MB, 3-second load, full engine features, MIT license — no runtime fees eating into your margins."

### Scene 6: Close (2:45–3:00)

**[Screen: Game running with final score, then title card with links]**

> "Godot 4.6 with AI agent tooling is production-ready for web gambling games. Rich VFX, clean architecture, testable logic, fast web export, and zero licensing cost. The code for this demo is open source — link in the description."

---

### Video Production Notes

| Element | Specification |
|---|---|
| **Resolution** | 1920×1080 (game captured at native 480×1040 centered, browser chrome visible) |
| **Duration** | ~3 minutes |
| **Recording tool** | OBS or `wf-recorder` (Wayland) |
| **Audio** | Voiceover + game SFX/music at 30% volume |
| **Transitions** | Simple cuts, no fancy transitions — focus on content |
| **Code font** | Same as IDE (monospace), zoom to 150% for readability |
| **Browser** | Firefox or Chrome, clean profile, no extensions visible |
| **Terminal** | Show GUT test output with green checkmarks for impact |
