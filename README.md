![Godot 4.6](https://img.shields.io/badge/Godot-4.6-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/language-GDScript-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)

# Phantom Frequencies

A rhythm-based stealth game where sound is both your weapon and your greatest vulnerability. Move in silence, exploit environmental noise, and stay one step ahead of guards who can only hear you.

## Overview

You play a ghost infiltrating a signal tower. Guards have no eyes — they navigate entirely by sound. Every footstep you take off the beat radiates a sound wave that they can track through walls using line-of-sight occlusion. Move on the beat and you slip through silently. Move off the beat and you broadcast your position.

The twist: the same sound propagation system that exposes you can be turned against the guards. Environmental machinery, dripping pipes, and ventilation create masking zones that swallow your footsteps. A pickupable recorder lets you capture ambient sound events and replay them as a decoy anywhere on the map.

## Tech Stack

| Layer | Choice |
|---|---|
| Engine | Godot 4.6 |
| Language | GDScript (no C#, no plugins) |
| Renderer | GL Compatibility (2D) |
| Target platform | macOS |

## How It Works

**Beat clock** — A singleton `BeatManager` drives a 100 BPM clock (80–120 BPM range). Player actions are checked against a ±50ms tolerance window. On-beat moves are silent; off-beat moves emit a sound event.

**Sound propagation** — `SoundPropagation` manages a pool of active sound events, each with a position, radius, intensity, and time-to-live. Wall occlusion is computed with a Bresenham line-of-sight check against the TileMap. Guards connect to the `sound_emitted` signal and filter events by range, intensity, wall occlusion, and environmental masking before reacting.

**Guard AI** — Guards run a four-state FSM (Patrol → Investigate → Alert → Return) ticked by the beat clock, not by frame time. A Patroller follows waypoints; a Sentinel has an extended hearing range of 7 tiles versus the base 5. Guards learn to ignore familiar environmental sound sources after one exposure.

**Sound ripple VFX** — A pooled `SoundWave` scene uses a canvas-item shader (`SoundRipple.gdshader`) that expands a ring outward as `progress` goes 0→1, fading as it grows.

**Recorder** — An interactable item that captures up to 4 beats of nearby sound events and replays them at a chosen location as a distraction.

## Prerequisites

- [Godot 4.6](https://godotengine.org/download/) (standard build, no .NET required)

## Getting Started

1. Clone the repository:
   ```
   git clone https://github.com/<your-username>/PhantomFrequencies.git
   ```
2. Open Godot 4.6 and choose **Import** → select the `project.godot` file.
3. Press **F5** (or the Play button) to run from the main menu.

**Controls**

| Key | Action |
|---|---|
| W / A / S / D | Move on the grid |
| R | Use recorder (first press: place and record, second press: play back) |
| Escape | Pause |

## Project Structure

```
PhantomFrequencies/
├── Scenes/
│   ├── Systems/        # Singletons: BeatManager, SoundPropagation, AudioManager, GameState, LevelManager
│   ├── Player/         # Player character and SoundWave VFX
│   ├── Guards/         # GuardBase FSM, Patroller, Sentinel
│   ├── Environment/    # SoundSource (machinery/drip/vent), Recorder pickup
│   ├── Levels/         # Level01 (Tutorial), Level02 (Intermediate), Level03 (Full Run)
│   └── UI/             # MainMenu, PauseMenu, BeatIndicator
├── Assets/
│   ├── Audio/          # Sound effects, ambient audio, bus layout
│   ├── Fonts/
│   └── Sprites/
├── Shaders/
│   └── SoundRipple.gdshader
└── project.godot
```

## Screenshot

_Screenshot placeholder — add gameplay screenshot here._

## License

MIT — see [LICENSE](LICENSE).
