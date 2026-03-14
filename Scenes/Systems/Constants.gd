extends Node
## All gameplay constants for Phantom Frequencies.

# Beat timing
const DEFAULT_BPM: int = 100
const MIN_BPM: int = 80
const MAX_BPM: int = 120
const BEAT_TOLERANCE_MS: float = 50.0  # ±50ms window for on-beat actions

# Grid
const TILE_SIZE: int = 64  # pixels per grid tile

# Sound propagation
const SOUND_DECAY_RATE: float = 2.0
const SOUND_EVENT_TTL: float = 0.5  # seconds before a sound event expires
const SOUND_WAVE_POOL_SIZE: int = 20
const PLAYER_SOUND_RADIUS: float = 192.0  # 3 tiles
const PLAYER_SOUND_INTENSITY: float = 1.0
const GUARD_HEARING_RANGE: float = 320.0   # 5 tiles
const SENTINEL_HEARING_RANGE: float = 448.0  # 7 tiles

# Player
const PLAYER_MOVE_DURATION: float = 0.12  # seconds for move tween
const PLAYER_COLOR: Color = Color(0.6, 0.8, 1.0, 0.9)  # ghostly blue-white
const PLAYER_ON_BEAT_COLOR: Color = Color(0.2, 0.9, 0.3, 0.9)  # green flash
const PLAYER_OFF_BEAT_COLOR: Color = Color(0.9, 0.2, 0.2, 0.9)  # red flash
