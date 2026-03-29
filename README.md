# PhantomFrequencies

[![Status](https://img.shields.io/badge/status-early_development-orange?style=flat-square)](#)

> Rhythm-based stealth game where sound is both your weapon and your greatest vulnerability.

You infiltrate a signal tower. Guards navigate entirely by sound — they have no eyes. Move on the beat and you slip through silently. Move off the beat and you broadcast your position. The same sound propagation system that exposes you can be turned against the guards with a pickupable recorder.

## Planned Features

- Beat clock driving 100 BPM gameplay with ±50ms tolerance window
- Sound propagation system with wall occlusion and environmental masking zones
- Four-state guard FSM (Patrol → Investigate → Alert → Return) ticked by beat clock
- Recorder item: capture up to 4 beats of ambient sound, replay as a decoy anywhere
- Canvas-item shader for expanding sound ripple VFX
- Two guard types: Patroller (waypoints) and Sentinel (extended hearing range)

## License

MIT