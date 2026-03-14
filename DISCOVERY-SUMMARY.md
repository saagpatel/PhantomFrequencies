# Phantom Frequencies — Discovery Summary

## Problem Statement
There is no rhythm-stealth hybrid game that uses sound as both the core mechanic and the visual language. Existing stealth games use vision/line-of-sight. Existing rhythm games are reflex-based. Phantom Frequencies combines them: sound propagation IS the stealth system, and the beat IS the movement system. The player must think spatially about noise while staying in rhythm.

## Target User
The player is anyone who enjoys puzzle-like stealth games (Hitman GO, Invisible Inc.) or rhythm games (Crypt of the NecroDancer, BPM: Bullets Per Minute). The builder (Saagar) is learning Godot for the first time and wants a project that's mechanically deep enough to be interesting but scoped enough to ship.

## Success Metrics
1. Core beat-sync loop feels tight: player actions land within ±50ms of beat window and the visual/audio feedback confirms it
2. 3 playable levels with increasing complexity, each completable in 2-5 minutes
3. Guard AI responds correctly to sound events 100% of the time (no false negatives, no detection through walls)
4. Sound ripple VFX renders at 60fps with 10+ simultaneous sound events on M4 Pro
5. At least one "aha moment" mechanic per level (environmental cover in L1, recorder in L2, multi-guard coordination in L3)

## Scope Boundaries

**In scope:**
- Beat-synced player movement on a grid
- Sound propagation system with visual ripple effects
- Guard AI with hearing-based detection (patrol, investigate, alert, chase states)
- Environmental sound sources that mask player noise
- Sound recorder/playback mechanic for distractions
- 3 handcrafted levels (tutorial, intermediate, full)
- Beat indicator UI
- Main menu, pause menu, level select
- Basic sound effects and ambient audio
- macOS build

**Out of scope:**
- Multiplayer or online features
- Procedural level generation
- Level editor (use Godot's scene editor)
- Achievement system
- Leaderboards or scoring
- Controller/gamepad support (keyboard only for MVP)
- Mobile or web builds
- Steam integration
- Save/load mid-level (levels are short enough to restart)
- Voice acting or narrative cutscenes

**Deferred (post-MVP):**
- Additional levels (4-10)
- Difficulty modes (slower/faster BPM)
- New guard types (deaf guard immune to sound, echo guard that reflects sound)
- New environmental mechanics (water puddles amplify footsteps, carpet dampens)
- Gamepad support
- Level editor for community content
- Music system that layers tracks based on alert state

## Technical Constraints
- Godot 4.4 with GDScript only (no C#, no plugins)
- Must run at 60fps on M4 Pro MacBook
- Beat timing precision: ±50ms tolerance window for "on beat" actions
- All audio assets must be royalty-free or self-created
- No external dependencies or network calls
- Sound propagation must respect wall occlusion (Area2D does not pass through TileMap collision)

## Key Integrations
| Service | API | Auth | Rate Limits | Purpose |
|---------|-----|------|-------------|---------|
| None | N/A | N/A | N/A | Fully offline, no integrations |

This is a zero-integration project. All systems are internal to the Godot engine.
