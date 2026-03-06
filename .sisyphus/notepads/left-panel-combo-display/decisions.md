# Left Panel Combo Display — Decisions

_Architectural choices and design decisions._

---

## Layout & Positioning

- **Panel X position**: Right-align text to `BOARD_OFFSET.x - 8` (x=72), extend leftward
- **Panel Y position**: Start at 250px (below HOLD panel: BOARD_OFFSET.y + BUFFER_ROWS * CELL_SIZE + 60)
- **Text rendering width**: 72px (0 to LEFT_PANEL_X_RIGHT)
- **Single active display**: New line clear replaces previous — no stacking

## Animation Timing

- **Scale punch**: 1.4x → 1.0x over 0.15s (matches floating text)
- **Hold duration**: 0.5s at full opacity
- **Fade duration**: 1.5s
- **Total display time**: ~2 seconds

## Font Sizes

- **Action label** (clear type): 28px
- **Combo count**: 36px (bigger emphasis, Tetris Effect style)
- **B2B label**: 20px (smaller accent)

## Content Display

- **Line 1** (if applicable): "B2B xN" in golden (1.0, 0.85, 0.0)
- **Line 2** (always): Clear type (SINGLE/DOUBLE/TRIPLE/TETRIS/T-SPIN variants)
- **Line 3** (if combo >= 1): "N COMBO" with color-coded intensity
