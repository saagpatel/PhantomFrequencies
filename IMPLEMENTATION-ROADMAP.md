# Implementation Roadmap

## Session Strategy
This project uses Godot 4.4 with GDScript. Claude Code sessions will generate GDScript files, scene configuration instructions, and shader code. Since Godot scenes (.tscn) are text-based, Claude Code can generate them directly. Estimated 5-6 sessions over 3 weeks, ~2-3 hours each.

**Important Godot workflow note:** After Claude Code generates files, open the project in Godot Editor to verify scenes load correctly, test gameplay, and adjust spatial placement visually. Claude Code handles logic; Godot Editor handles spatial tuning.

---

## Phase 0: Foundation (Week 1)

### Session 1: Project Scaffold + Beat System
**Scope:**
- Create Godot 4.4 project with full folder structure (Scenes/, Scripts/, Assets/, Shaders/)
- Implement BeatManager autoload:
  - Configurable BPM (default 100)
  - Emits `beat_tick` signal on each beat using AudioStreamPlayer sync
  - Tracks beat count, measures, current beat phase (0.0-1.0)
  - Provides `is_on_beat(tolerance_ms: float) -> bool` utility
- Implement BeatIndicator UI scene:
  - Expanding ring animation synced to BeatManager
  - Color shifts green on beat window, red off-beat
  - Positioned at screen bottom center
- Create basic TileMapLayer with wall and floor tiles (placeholder colored rectangles)
- Create test level scene with a simple room

**Deliverables:** Runnable project with audible/visible beat pulse in a room
**Verification:** Open Godot, run scene, confirm beat indicator pulses at correct BPM, confirm BeatManager.is_on_beat() returns true within tolerance window

### Session 2: Player Movement + Sound Events
**Scope:**
- Implement Player scene:
  - Grid-based movement (arrow keys / WASD)
  - Movement only executes on input + beat alignment
  - On-beat movement: silent (no sound event)
  - Off-beat movement: generates sound_event(position, radius=3tiles, intensity=1.0)
  - Standing still is always silent
  - Visual feedback: player sprite flashes green/red for on/off beat
- Implement SoundPropagation autoload:
  - `emit_sound(origin: Vector2, radius: float, intensity: float, source: Node)` method
  - Stores active sound events with TTL (0.5 seconds)
  - Emits `sound_emitted` signal with event data
- Implement SoundWave VFX scene:
  - Shader-driven expanding ring (fragment shader on a Sprite2D)
  - Color based on intensity (low=blue, high=red)
  - Fades out as ring expands to radius
  - Object pooling: pre-instantiate 20 SoundWave instances, reuse

**Deliverables:** Player moves on grid, on-beat is silent, off-beat emits visible sound ripples
**Verification:** Move on beat — no ripples. Move off beat — ripples expand. Ripples stop at walls.

---

## Phase 1: Guard AI + Core Stealth Loop (Week 2)

### Session 3: Guard Hearing + FSM
**Scope:**
- Implement GuardBase scene:
  - Hearing area: Area2D with CircleShape2D (configurable radius, default 5 tiles)
  - Connects to SoundPropagation.sound_emitted signal
  - Filters: only reacts to sounds within hearing area AND with intensity above threshold
  - Wall occlusion: raycast from guard to sound origin, if blocked by tilemap collision → ignore
- Implement Guard FSM with states:
  - **Patrol**: follows a Path2D at fixed speed, grid-snapped movement on beat
  - **Investigate**: moves toward last heard sound position, slower, looking around
  - **Alert**: knows player position, moves toward player at patrol speed
  - **Return**: goes back to patrol path after investigation timeout (3 beats)
- State transitions:
  - Patrol → Investigate: sound detected above threshold
  - Investigate → Alert: sound detected while already investigating (confirms threat)
  - Investigate → Return: no sound for 4 beats
  - Alert → chase player until player escapes hearing range for 6 beats → Return
- Visual indicators: guard color changes by state (green=patrol, yellow=investigate, red=alert)
- Implement Patroller variant: walks a defined Path2D loop
- Implement Sentinel variant: stationary, larger hearing radius (7 tiles)

**Deliverables:** Guards react to player sound, investigate, chase, and return to patrol
**Verification:** Stand still near guard — no reaction. Move off-beat near guard — investigation. Multiple off-beat moves — alert state. Hide and wait — guard returns.

### Session 4: Environmental Sound + Level 1
**Scope:**
- Implement SoundSource scene:
  - Emits continuous sound at configurable interval (e.g., every 2 beats)
  - Configurable radius and intensity
  - Types: machinery (loud, rhythmic), drip (quiet, irregular), vent (medium, constant)
  - Guards ignore environmental sounds they've "heard before" (familiarity system: each guard tracks known sound source IDs)
- Implement sound masking:
  - If player sound_event overlaps with environmental sound_event in same area → player sound is masked (guards don't hear it)
  - Visual: player ripple turns blue (masked) instead of red (exposed)
- Build Level 01 (Tutorial):
  - Small room (12x12 tiles)
  - 1 Patroller guard on simple loop
  - 1 machinery SoundSource near the path
  - Goal: reach the exit tile
  - Teach: move on beat to stay silent, use machinery as cover
  - Exit trigger: Area2D on goal tile, emits level_completed signal
- Implement LevelManager autoload:
  - Tracks current level, loads scenes
  - Handles level_completed → transition to next level
  - Handles player_caught → restart current level

**Deliverables:** Playable tutorial level with one guard and environmental cover
**Verification:** Complete Level 01 by moving on-beat and using machinery cover. Get caught by moving off-beat without cover. Restart works.

---

## Phase 2: Recorder Mechanic + Levels 2-3 (Week 3)

### Session 5: Recorder + Level 2
**Scope:**
- Implement Recorder scene:
  - Player activates recorder at a position (press R key)
  - Recorder captures all sound events in its radius for N beats (configurable, default 4)
  - Player can trigger playback (press R again) — replays captured sounds from recorder position
  - Playback generates real sound events that guards react to (distraction)
  - Recorder has 1 charge — must pick up a new one to record again
  - Visual: recorder object glows when recording, pulses when ready to play
- Build Level 02 (Intermediate):
  - Larger room (16x16 tiles)
  - 2 Patroller guards with intersecting paths
  - 1 Sentinel guard blocking a corridor
  - 1 Recorder pickup
  - Environmental sounds: 2 drip sources, 1 vent
  - Teach: use recorder to distract the Sentinel while sneaking past
  - Multiple valid paths through the level

**Deliverables:** Recorder mechanic works, Level 02 is playable and requires recorder use
**Verification:** Record environmental sounds, play them back to lure guard away, sneak past. Level is completable but requires thought.

### Session 6: Level 3 + Menus + Polish
**Scope:**
- Build Level 03 (Full):
  - Large multi-room layout (24x20 tiles)
  - 3 Patrollers, 2 Sentinels
  - Multiple environmental sound sources
  - 2 Recorder pickups
  - Requires combining all mechanics: beat timing, environmental cover, recorder distractions
  - Hidden bonus exit (reach a specific tile sequence on beat — easter egg)
- Implement MainMenu scene:
  - Title, Start Game, Level Select (unlocked levels only), Quit
  - Minimal visual: dark background, glowing text, ambient sound
- Implement PauseMenu scene:
  - Resume, Restart Level, Return to Menu
  - Triggered by Escape key
- Implement level transitions:
  - Brief fade-to-black between levels
  - "Level Complete" overlay with time taken
- Implement GameState autoload:
  - Tracks unlocked levels (saved to ConfigFile)
  - Tracks best completion time per level
- Audio polish:
  - Add ambient background track (low drone, synced to BPM)
  - Add sound effects: footstep, guard alert sting, level complete chime, recorder activate/playback
  - Audio bus layout: Master, Music, SFX, Ambient

**Deliverables:** Complete 3-level game with menus, transitions, and audio
**Verification:** Play through all 3 levels start to finish. Verify menus work. Verify level unlock persistence across app restarts. Verify 60fps with all effects active.

---

## Context Management

**Session 1-2 files to include:**
- CLAUDE.md
- Constants.gd (once created)
- BeatManager.gd
- SoundPropagation.gd

**Session 3-4 files to include:**
- CLAUDE.md
- Constants.gd
- BeatManager.gd
- SoundPropagation.gd
- Player.gd
- GuardBase.gd

**Session 5-6 files to include:**
- CLAUDE.md
- Constants.gd
- BeatManager.gd
- SoundPropagation.gd
- GuardBase.gd
- Recorder.gd
- LevelManager.gd
