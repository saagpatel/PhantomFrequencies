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

# Guards
const GUARD_SPRITE_SIZE: float = 48.0
const GUARD_HEARING_THRESHOLD: float = 0.3  # min intensity to react
const GUARD_INVESTIGATE_BEAT_INTERVAL: int = 2  # move every N beats when investigating
const GUARD_INVESTIGATE_TIMEOUT_BEATS: int = 4  # beats of silence before returning
const GUARD_ALERT_ESCAPE_BEATS: int = 6  # beats of silence in alert before returning
const GUARD_PATROL_COLOR: Color = Color(0.2, 0.8, 0.3, 0.9)  # green
const GUARD_INVESTIGATE_COLOR: Color = Color(0.9, 0.8, 0.2, 0.9)  # yellow
const GUARD_ALERT_COLOR: Color = Color(0.9, 0.2, 0.2, 0.9)  # red
const GUARD_RETURN_COLOR: Color = Color(0.4, 0.6, 0.9, 0.9)  # blue

# Environmental sound sources
const SOUND_SOURCE_MACHINERY_INTERVAL: int = 2  # emit every N beats
const SOUND_SOURCE_MACHINERY_RADIUS: float = 256.0  # 4 tiles
const SOUND_SOURCE_MACHINERY_INTENSITY: float = 0.8
const SOUND_SOURCE_DRIP_RADIUS: float = 128.0  # 2 tiles
const SOUND_SOURCE_DRIP_INTENSITY: float = 0.4
const SOUND_SOURCE_DRIP_CHANCE: float = 0.3  # 30% chance per beat
const SOUND_SOURCE_VENT_RADIUS: float = 192.0  # 3 tiles
const SOUND_SOURCE_VENT_INTENSITY: float = 0.6
const SOUND_SOURCE_SPRITE_SIZE: float = 32.0
const SOUND_SOURCE_COLOR: Color = Color(0.5, 0.7, 0.9, 0.7)  # light blue

# Player
const PLAYER_MOVE_DURATION: float = 0.12  # seconds for move tween
const PLAYER_COLOR: Color = Color(0.6, 0.8, 1.0, 0.9)  # ghostly blue-white
const PLAYER_ON_BEAT_COLOR: Color = Color(0.2, 0.9, 0.3, 0.9)  # green flash
const PLAYER_OFF_BEAT_COLOR: Color = Color(0.9, 0.2, 0.2, 0.9)  # red flash
const PLAYER_MASKED_COLOR: Color = Color(0.2, 0.4, 0.9, 0.9)  # blue (masked by env sound)

# Levels
const LEVEL_SCENES: Array[String] = [
	"res://Scenes/Levels/Level01.tscn",
]
