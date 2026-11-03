# Native candidate validation

Local execution, November 3, 2026:

- Nine Swift model/session tests passed, including a virtual hour and proportional recovery under repeated input.
- CLI timeline / invalid-input checks passed.
- Real audio metadata queries passed. A generated silent output stream reported active, confirming the documented false-positive boundary.
- 126 actual offscreen Metal renders passed exact endpoint, black RGB, binary probability-mask, monotonicity and reverse-path checks.
- A real bounded overlay-window test passed focus retention, frame submission and cleanup checks.
- A real full-display accelerated session reached the black endpoint using aggregate input inactivity. Automatic exit occurred within 45 seconds and its temporary display-awake assertion was released.
- Release app packaging, plist and ad-hoc signature checks passed. The packaged executable also passed the GPU shader test.

The full-display check was run once, without retrying to obtain a favorable outcome. No hour-long wait or system lock was required. It establishes submission of a full-black frame, not measured OLED black level. Cursor hiding remained off.

Physical pixel mapping, subjective comfort, SDR/HDR display behavior, optional cursor hiding, real keyboard/mouse pass-through, Spaces/fullscreen switching and visual automation compatibility remain manual acceptance items; see [TESTING.md](TESTING.md). Hosted CI deliberately omits graphical/audio tests.
