# Testing Gentle Night

## Automated checks

Run `bash scripts/test.sh --with-display` on a logged-in Mac with Xcode 16+ and Python 3. It writes a timestamped log under `test-results/` and builds an ad-hoc signed candidate at `dist/Gentle Night.app`.

The script checks:

1. Nine Swift tests: endpoints, deterministic masks, no relighting, reverse recovery, invalid settings, and session transitions. A virtual monotonic clock traverses a complete hour without waiting. Audio, pause, launch and wake resets are simulated.
2. CLI JSON at 0, 10, 35, 60 and 120 idle minutes in all modes; invalid arguments must fail.
3. Real Core Audio metadata and aggregate input-idle queries. A generated silent WAV plays briefly, demonstrating that output activity does not establish audible sound. No recording or microphone is used. Other playing audio can also make the status true; this is not a sound-level test.
4. The actual Metal shader executes 126 offscreen renders: three modes, forward and reverse. Tests read back black RGB, exact alpha endpoints, monotonicity and binary probabilistic alpha. These are GPU render pixels, not measured panel light.
5. A real 256×144 click-through window follows an accelerated fade / black / recovery cycle in about three seconds. It verifies frames were submitted, the foreground app remained unchanged, the window was removed and no cursor or power assertion remained. No keyboard or mouse events are injected.
6. Release packaging, plist validation and ad-hoc signature verification.

`bash scripts/test.sh` omits steps requiring a graphical login / audio output, making it suitable for hosted CI. CI success is not evidence for the omitted checks. Read logs for the checks actually run.

## Optional full-display accelerated check

`bash scripts/test.sh --full-screen` additionally runs the real full-display idle test, checks its temporary power assertion, waits for automatic exit, and verifies release. It takes about 45 seconds. User input can interrupt the fade and make this test fail; retain that result rather than retrying automatically.

Quit an existing Gentle Night instance, then run:

```sh
bash scripts/run-accelerated.sh
```

This explicitly starts the real main-display overlay: 3 seconds to begin, 12 seconds to black, proportional recovery up to 0.8 seconds. Move the mouse or type to restore. Audio hold is bypassed only in this test session. It exits after 45 seconds and releases its temporary display-awake assertion. Timing settings are not rewritten.

The regular menu preview compresses fading into eight seconds, holds black briefly, then restores automatically. Input can reverse it earlier. Preview does not prevent display sleep on its own.

## Checks still requiring observation

- At partial fade and full black, move the mouse, scroll, and type into a disposable document. Confirm first input reaches the original app, focus stays unchanged, and recovery has no flash. A blind click can activate the underlying control by design.
- Switch modes; compare sparse pixels against uniform and iris. GPU and CPU use different stable coordinate hashes, not blue noise. The survival law and endpoint contracts match; their random patterns are not identical.
- Test silent video, audible playback, paused playback, and headphones / HDMI changes. Output-active audio hold is a heuristic; actual silence detection is not implemented.
- Test the optional cursor-hiding switch. The default is off because macOS may require foreground ownership to hide the pointer. API success alone does not verify cursor invisibility. Restore on activity, disable and quit; do not claim cursor-free black without observing it.
- Test Spaces, fullscreen apps, display replug and resolution changes. The app currently targets the main display at overlay creation; it does not manage individual display profiles.
- Confirm backing-scale / native-output alignment and SDR/HDR on the actual OLED. Display scaling may blend binary render pixels. Do not infer physical pixel-off or energy savings from the shader results.
- Test normal quit, disabled state, wake, session changes and manual lock. Inspect `pmset -g assertions` before / during / after enabling. The app never changes global screensaver or password settings; configure automatic screensavers separately if needed.
- Check screenshot/OCR/remote automation separately. The overlay may be present in captured images.

No automated result establishes burn-in prevention, long-term wear reduction, physical black level, or all automation compatibility. Force-kill recovery of an experimentally hidden cursor is not covered by the normal-quit smoke test.
