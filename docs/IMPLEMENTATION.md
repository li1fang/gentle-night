# Native prototype execution plan

The first native candidate implements the supplied probabilistic disappearance design without capturing the desktop.

1. Separate monotonic idle / audio / pause / recovery logic into a pure session engine and test a virtual hour.
2. Render transparent / opaque-black masks with Metal over the live main display. Keep fixed coordinate thresholds during a cycle and reverse the same field during recovery.
3. Add a nonactivating, click-through menu-bar app, persisted timing / mode settings, audio-output-state hold, optional cursor hiding and temporary display-awake assertion.
4. Add bounded accelerated preview, display / sleep cleanup, diagnostics, release packaging and repeatable test scripts.
5. Run model, CLI, actual GPU and bounded window tests locally; run build / package checks in CI. Keep panel and user-input acceptance separate.

Steps 1–4 are implemented in this candidate. Test coverage and remaining acceptance items are in [TESTING.md](TESTING.md). Blue noise, accurate signal-level silence detection, per-display profiles, signed/notarized distribution and guaranteed cursor hiding are not implemented. Normal launch starts disabled until the user explicitly enables automatic fading. There is no login item or background service installation.
