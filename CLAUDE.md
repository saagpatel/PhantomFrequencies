# Phantom Frequencies

## Project Overview
Phantom Frequencies is a rhythm-based stealth game built in Godot 4.4 where sound is both the primary mechanic and the visual language. The player is a ghost infiltrating a haunted signal tower. Every action generates visible sound waves that ripple across the level. Guards detect the player by sound, not sight. Moving on beat keeps the player silent; mistimed actions generate noise that alerts guards. Environmental sounds (machinery, wind, dripping water) provide cover. The player can record and replay sound patterns to create distractions. Zero cloud dependencies — runs entirely local.

## Tech Stack
- Engine: Godot 4.4 (GDScript primary, with typed GDScript strict mode)
- Audio: Godot AudioStreamPlayer2D + AudioBusLayout
- Physics/Detection: Area2D with collision shapes for sound propagation zones
- Rendering: Godot 2D with custom shaders (sound ripple effects, fog/visibility)
- Level Design: Godot TileMapLayer for grid-based levels
- State Machine: GDScript-based hierarchical FSM for guard AI and player states
- Save/Config: Godot ConfigFile for settings, JSON for level data
- Build: Godot export templates for macOS (.dmg)

## Architecture
```
Scenes/
├── Main.tscn                    # Root scene, manages game state
├── Player/
│   ├── Player.tscn              # Player character + sound emitter
│   └── SoundWave.tscn           # Pooled ripple VFX instance
├── Guards/
│   ├── GuardBase.tscn           # Base guard with FSM + hearing
│   ├── Patroller.tscn           # Walks a path, medium hearing
│   └── Sentinel.tscn            # Stationary, wide hearing cone
├── Environment/
│   ├── SoundSource.tscn         # Environmental noise emitter
│   ├── Recorder.tscn            # Sound recording/playback device
│   └── Door.tscn                # Opens on beat, generates noise
├── Levels/
│   ├── Level01.tscn             # Tutorial — one guard, learn beat
│   ├── Level02.tscn             # Two guards, environmental cover
│   └── Level03.tscn             # Full level, recorder mechanic
├── UI/
│   ├── BeatIndicator.tscn       # Rhythm UI at screen bottom
│   ├── HUD.tscn                 # Minimal HUD (alert state, level)
│   ├── PauseMenu.tscn
│   └── MainMenu.tscn
└── Systems/
    ├── BeatManager.gd           # Singleton — drives the beat clock
    ├── SoundPropagation.gd      # Singleton — manages all sound events
    └── LevelManager.gd          # Singleton — level loading, checkpoints
```

Data flow:
```
BeatManager (tempo clock)
    ↓ beat_tick signal
Player input → on-beat? → silent / noisy
    ↓ sound_event(position, radius, intensity)
SoundPropagation system
    ↓ queries Area2D overlaps
Guards (hearing Area2D) → FSM transition → alert/investigate/chase
    ↕
Environmental SoundSources → constant noise zones → mask player sounds
```

## Development Conventions
- GDScript strict mode: all variables typed, all functions typed returns
- Scene naming: PascalCase (`GuardBase.tscn`)
- Script naming: PascalCase matching scene (`GuardBase.gd`)
- Signal naming: snake_case past tense (`sound_detected`, `beat_hit`, `level_completed`)
- Folders: lowercase with hyphens for multi-word (`sound-effects/`)
- Autoloads (singletons): BeatManager, SoundPropagation, LevelManager, GameState
- Git commits: `type(scope): description` (e.g., `feat(guard): add hearing cone visualization`)
- All gameplay constants in a single `Constants.gd` autoload (BPM, sound decay rate, guard hearing ranges)
- Test levels manually after every mechanic change — no automated test framework for Godot (manual QA checklist per phase)

## Current Phase
**Phase 0: Foundation** (target: Week 1)
- [ ] Godot 4.4 project scaffold with folder structure
- [ ] BeatManager singleton with configurable BPM and beat_tick signal
- [ ] Player scene with grid movement snapped to beat timing
- [ ] Visual beat indicator UI (expanding rings on beat)
- [ ] Sound event system: player actions emit sound_event(position, radius, intensity)
- [ ] SoundWave VFX: shader-driven expanding ring at sound_event origin
- [ ] Basic tilemap level with walls and floor

## Key Decisions Made
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Engine | Godot 4.4 GDScript | Explicit user goal to build a Godot project. GDScript is fastest for solo prototyping. |
| 2D not 3D | 2D top-down | Stealth + rhythm mechanics are easier to read in 2D. Sound propagation visualization works better top-down. Dramatically reduces art requirements. |
| Grid movement | Tile-snapped discrete movement | Aligns naturally with beat timing. Continuous movement + beat sync is much harder to tune. |
| Sound as Area2D | Area2D collision shapes, not raycasts | Simpler to implement, debug, and visualize. Raycasts would need many casts per sound event. |
| No procedural levels | Handcrafted levels | Stealth level design requires careful guard placement and environmental sound placement. Procedural generation would produce unsolvable or trivial levels. |
| BPM range | 80-120 BPM | 80 feels relaxed/manageable, 120 feels tense. Tutorial at 80, later levels ramp up. |
| Shader ripples | Custom fragment shader on Sprite2D | GPU-driven ripple effect scales to many simultaneous sound events without frame drops. |

## Do NOT
- Do NOT use C# or C++ — GDScript only for this project
- Do NOT use Godot 3.x APIs or patterns — this is Godot 4.4, use the 4.x API (TileMapLayer not TileMap, no `yield`, use `await`)
- Do NOT make guards use sight/vision cones — the entire mechanic is sound-based detection only
- Do NOT add procedural level generation — all levels are hand-designed
- Do NOT use any external plugins or addons — vanilla Godot only
- Do NOT create 3D assets — this is a 2D game with shader effects for visual depth
- Do NOT store any data in cloud services — fully offline, single-player
- Do NOT build a level editor in Phase 0-1 — use Godot's built-in scene editor for level design
