# Gentle Night

[简体中文](README.zh-CN.md)

A native macOS menu-bar prototype that gradually masks the live desktop to black without locking the session. Compare uniform dimming, a soft iris, and deterministic probabilistic disappearance. Defaults: begin at 10 idle minutes, black at 60, reverse recovery in at most 0.8 seconds proportional to progress.

## Build and use

Requires macOS 14+, Xcode 16+ / Swift 6. Test scripts also require Python 3.

```sh
bash scripts/build-app.sh
open "dist/Gentle Night.app"
```

The ☾ menu starts with automatic fading disabled. Try the bounded eight-second preview, then enable automatic fading. Timing, recovery speed, effect, pause and audio hold are configurable. No login item or service is installed. The candidate is ad-hoc signed, not notarized.

Audio hold reads output-stream activity without capturing audio. Silent streams can still hold the screen visible. Unavailable audio metadata (including macOS before 14.2) conservatively holds visibility when audio hold is enabled. No screen/audio recording or Accessibility permission is requested.

Cursor hiding is experimental and off by default; the system pointer may remain visible on an otherwise black screen. Automatic fading temporarily prevents idle display/system sleep. Global screensaver/password settings are not changed; configure automatic screensavers separately. Input passes through, including the first click or key used to restore.

## Accelerated checks

```sh
bash scripts/test.sh --with-display
# Optional real full-display test: 3s start, 12s black, 45s automatic exit
bash scripts/run-accelerated.sh
```

Tests cover a virtual hour, nine Swift contracts, CLI, audio metadata, 126 actual GPU renders, a bounded window lifecycle and app packaging/signature verification. See [testing and remaining acceptance](docs/TESTING.md), [execution plan](docs/IMPLEMENTATION.md), and [visual design](docs/DESIGN.md).

The probabilistic renderer uses stable hash thresholds, not blue noise. Binary render pixels do not establish one-to-one physical OLED pixel mapping. HDR, physical black level, cursor behavior, screenshot automation and long-term protection require separate verification. No burn-in prevention or lifespan benefit is guaranteed.

## License

[MIT](LICENSE). See [contributing](CONTRIBUTING.md).
