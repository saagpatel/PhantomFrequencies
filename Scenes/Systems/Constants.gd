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
const GUARD_HEARING_RANGE: float = 320.0   # 5 tiles
const SENTINEL_HEARING_RANGE: float = 448.0  # 7 tiles
