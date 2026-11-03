# Gentle Night

[简体中文](README.zh-CN.md)

Gentle Night is an early macOS project for gradually masking an idle OLED display to black, then quickly revealing the current desktop when activity returns. The intended app keeps the session unlocked and the display connected.

Its main experiment is **probabilistic disappearance**: each covered pixel is either transparent, revealing its original color, or opaque black. Pixels near the edges disappear earlier; a shrinking, increasingly sparse central region remains. A fixed threshold for each pixel prevents repeated random flickering during one fade cycle.

## Current status

This repository is a design and core-model scaffold. It is **not an installable screen-dimming app**.

| Component | Status |
| --- | --- |
| Configurable timeline, deterministic masks, recovery model | Swift core model |
| `gentle-night-preview` | JSON-only model preview; does not control any display |
| Menu-bar app, desktop overlay, idle detection, audio handling | Planned |
| Cursor hiding, fullscreen behavior, HDR and OLED verification | Unverified |

The core has no third-party dependencies and does not request permissions, capture the screen or audio, or change system settings.

## Intended behavior

- Start fading after **10 minutes** of recognized inactivity and reach full black at **60 minutes** total inactivity. Both values will be configurable.
- Compare three modes: uniform dimming, a soft inward iris, and probabilistic disappearance.
- Restore along the same mask sequence in `0.8 × current progress` seconds, up to 0.8 seconds from full black.
- Keep the desktop live beneath the overlay. Do not freeze a screenshot, steal focus, or consume the first input used to restore the screen.
- Consider audio activity separately from video. A running audio output stream does not prove that audible sound is present; the implementation and permission tradeoff remain to be validated.

These are product targets. Overlay behavior and physical display results have not yet been verified. Gentle Night does not promise to prevent burn-in or replace the display's own maintenance features.

## Run the model preview

Use Xcode 16 or later with a Swift 6 toolchain for tests. Command Line Tools alone are not guaranteed to expose the testing libraries. The initial macOS deployment target is macOS 14 or later.

```sh
swift test --disable-xctest
swift run gentle-night-preview --idle-minutes 35 --seed 42
swift run gentle-night-preview --mode probabilistic --idle-minutes 50 --width 96 --height 54 --seed 42
```

If Command Line Tools are selected, choose Xcode for this test command without changing the global developer setting:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test --disable-xctest
```

Supported preview modes are `uniform`, `iris`, and `probabilistic`. The preview prints JSON; it does not draw an overlay or black out your screen. Grid dimensions are model samples, not verified physical OLED pixel coordinates.

## Next steps

1. Build a reversible single-display overlay prototype and verify input, focus, cursor, and fullscreen behavior.
2. Compare the three effects on a real OLED display, including SDR/HDR and display scaling.
3. Validate lightweight audio-state detection, then add the menu-bar controls and adjustable settings.

See [the design](docs/DESIGN.md) for the model and acceptance criteria, and [contributing](CONTRIBUTING.md) for development guidance.

## License

[MIT](LICENSE).
