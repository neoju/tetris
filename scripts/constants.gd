class_name Constants
extends RefCounted

# =============================================================================
# GRID CONSTANTS
# =============================================================================
const CELL_SIZE: int = 32
const COLS: int = 10
const TOTAL_ROWS: int = 24          # 4 buffer + 20 visible
const VISIBLE_ROWS: int = 20
const BUFFER_ROWS: int = 4

# =============================================================================
# BOARD LAYOUT
# =============================================================================
const DESIGN_WIDTH: int = 480
const BOARD_OFFSET := Vector2(80, 86)  # (480 - 320) / 2 = 80, aligned with panels

# =============================================================================
# VISUAL STYLE
# =============================================================================
const BORDER_COLOR := Color(0.65, 0.65, 0.72)
const BORDER_WIDTH: float = 1.5
const GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.06)

# =============================================================================
# ANIMATION TIMING
# =============================================================================
const FLOAT_SPEED: float = 45.0
const FLOAT_DURATION: float = 1.6
const FLOAT_HOLD_RATIO: float = 0.3
const SCALE_PUNCH: float = 1.4
const SCALE_SETTLE_TIME: float = 0.15

# =============================================================================
# LINE CLEAR ANIMATION
# =============================================================================
const CLEAR_FLASH_DURATION: float = 0.08       # White overlay phase
const CLEAR_DISSOLVE_DURATION: float = 0.32   # Block fade-out phase
const CLEAR_TOTAL_DURATION: float = CLEAR_FLASH_DURATION + CLEAR_DISSOLVE_DURATION

# =============================================================================
# VFX TIMING
# =============================================================================
const SHAKE_DECAY: float = 10.0               # How fast shake dies (higher = faster)
const BORDER_GLOW_DECAY: float = 3.0          # How fast border glow fades
const HARD_DROP_CELLS_PER_SECOND: float = 125.0

# =============================================================================
# INPUT SETTINGS
# =============================================================================
const DAS_DELAY: float = 0.167
const ARR_RATE: float = 0.033

# =============================================================================
# LOCK DELAY
# =============================================================================
const LOCK_TIME: float = 0.5
const MAX_MOVES: int = 15

# =============================================================================
# AUDIO
# =============================================================================
const SFX_POOL_SIZE: int = 4
const SFX_VOLUME_DB: float = -7.0

# =============================================================================
# MUSIC
# =============================================================================
const MUSIC_VOLUME_DB: float = -12.0
