# Gentle Night design

Status: initial model and implementation plan, November 3, 2026.

Gentle Night should gradually reduce visible desktop content during inactivity without locking the session or disconnecting the display. The initial implementation isolates the timeline and visual model from operating-system integration so their behavior can be checked before an overlay controls a real screen.

## Timeline and recovery

The default fade begins at 10 minutes of recognized inactivity and reaches black at 60 minutes total. For inactivity `t`, start time `s`, and black time `b`:

```text
u = clamp((t - s) / (b - s), 0, 1)
```

The configuration must require `0 <= s < b`. The default maximum recovery duration is 0.8 seconds:

```text
recovery duration = 0.8 seconds × current u
```

Recovery decreases `u` to zero using the same center, seed, and thresholds. New activity during recovery must not repeatedly restart the animation. Recognized activity resets the idle timeline; the next fade waits for a fresh idle interval.

The first input must reach the original application, and focus should remain unchanged. These requirements intentionally differ from a lock screen. A click made while the display is black can therefore affect the underlying application.

## Three visual modes

| Mode | Model |
| --- | --- |
| Uniform | Increase black overlay opacity across the entire display. |
| Iris | Shrink a central visible region with a soft boundary. |
| Probabilistic | Keep each sample fully visible or fully black using a stable threshold and a spatial survival probability. |

All modes require exact endpoints: no mask at `u = 0`, opaque black everywhere at `u = 1`. A final value near, but below, full opacity is insufficient.

### Probabilistic disappearance

Let `r` be distance from the fixed center, normalized by half the display diagonal. The initial default center is the screen's geometric center. For `0 < u < 1`, use:

```text
P(r, u) = (1 - u) × exp(-β × u × r² / (1 - u))
β = 3 by default
P(r, 0) = 1
P(r, 1) = 0
```

This is an endpoint-normalized, Gaussian-like survival model. It avoids a finite-width Gaussian removing peripheral samples immediately at the start. Increasing progress never increases survival probability at any fixed position. The amplitude term also makes the exact center disappear by the end.

For each sample, derive a fixed threshold `q` in `(0, 1)` from its coordinates and a cycle seed:

```text
visible if q < P(r, u)
black otherwise
```

The initial core uses a stable hash for thresholds. It does not yet implement a blue-noise texture. Blue noise is a later visual comparison, not a current capability or a proven improvement.

The center and thresholds stay fixed during a fade and its recovery. Do not draw new random thresholds every frame. Each sample may disappear at most once during forward progress and reappear in the corresponding reverse order during recovery. A later cycle may use a new seed. Mouse-anchored or slightly shifted centers remain optional experiments; the center must never chase the pointer during a fade.

## Rendering plan

Use a nonactivating, click-through overlay over the live desktop. The probabilistic mask consists of transparent and opaque-black regions; transparent regions reveal current desktop content rather than a captured image. A low-frequency mask update is sufficient for a long fade, while recovery can update at display cadence. A fully black state should not keep recomputing the mask.

Logical desktop points, drawable pixels, and physical panel pixels are different coordinate systems. Display scaling and compositor filtering can blend a binary mask or change its mapping to the panel. The JSON preview only samples the mathematical model; it does not establish pixel-accurate OLED behavior. The real renderer must test backing scale, drawable alignment, SDR/HDR, and the actual display path.

## Activity and audio

Read aggregate input inactivity rather than recording key contents. Physical, synthetic, and remote inputs need explicit compatibility tests.

The intended audio policy is to hold the display visible while audio plays, then begin a fresh idle interval after playback ends. Video alone should not exempt a display from fading.

A lightweight Core Audio query can identify an active output stream without consuming audio samples, but silent streams and muted video may still be active. Actual silence detection requires signal-level analysis and may need system-audio capture permission. Do not describe output-stream activity as proof of audible sound, and do not enable audio capture silently. The initial scaffold implements neither audio route.

## macOS integration questions

- **Cursor:** the system pointer can appear above an overlay. Hiding it while retaining the original app's focus, and restoring it on activity or exit, require a real prototype. Do not move the actual pointer to hide it.
- **Spaces and fullscreen:** verify overlay coverage when changing desktops, entering fullscreen, using Stage Manager, or changing display arrangements.
- **Power and screensaver:** display-sleep prevention, automatic screensaver settings, and session locking are separate from a visual overlay. Any temporary power assertion must be released on exit. Manual lock and system sleep take precedence.
- **Automation:** background/API work can continue, but screen capture, OCR, pixel inspection, synthetic input, and remote desktop behavior need separate validation. Do not promise that every visual automation can see through a black overlay.
- **Accessibility:** provide a simpler effect for reduced-motion preferences and a reliable way to pause or exit.

## Acceptance criteria

1. The configured start and black times refer to total inactivity, and recovery takes the configured maximum duration multiplied by current progress.
2. Every visual mode has exact clear and black endpoints. Fixed-seed probabilistic output is reproducible and monotonic during forward progress.
3. Recovery reuses the same thresholds and reveals the current desktop, without consuming the triggering input or changing the original app's focus.
4. Cursor hiding and restoration work across activation, exit, crash recovery, and the supported display arrangement.
5. Fullscreen apps, Spaces, display changes, SDR/HDR, and display scaling show no unintended uncovered regions or flashes.
6. Audio behavior distinguishes measured facts from output-stream heuristics. Silent video, paused playback, and output-device changes are tested.
7. CPU/GPU activity is measured in active, fading, black, and recovery states. Average visible fraction is a model metric, not a measurement of panel power or lifespan.
8. Subjective OLED testing checks whether sparse pixels look calm and intentional rather than faulty or flickering.

The core tests cover mathematical contracts only. Physical black level, comfort, energy savings, burn-in protection, automation compatibility, and macOS window behavior remain unverified. This project does not replace display firmware maintenance or guarantee freedom from burn-in.
