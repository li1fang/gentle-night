# Contributing

Gentle Night is currently a native macOS overlay prototype. Discuss changes to the visual model or operating-system behavior in an issue before expanding the scope.

## Development

Use Xcode 16 or later with a Swift 6 toolchain for tests. Command Line Tools alone are not guaranteed to expose the testing libraries. The initial macOS deployment target is macOS 14 or later.

```sh
bash scripts/test.sh
# Logged-in Mac: include GPU, audio and bounded window checks
bash scripts/test.sh --with-display
```

If Command Line Tools are selected, use a process-scoped Xcode selection without changing the global developer setting:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test --disable-xctest
```

The preview only prints JSON. Keep it safe to run without changing the display, recording audio, requesting permissions, or installing background services.

## Changes and evidence

- Preserve exact clear/black endpoints, reproducibility for a fixed seed, monotonic disappearance, and proportional reverse recovery.
- Add focused tests when changing those contracts. Avoid tests that merely copy the implementation's expression.
- Keep the core independent of AppKit rendering and audio/input integration.
- State whether a result comes from model tests, an overlay prototype, or a physical display check. Do not treat one as evidence for another.
- Document new permissions and persistent system changes before implementing them. Do not add automatic installation, recording, or startup behavior to the model preview.
- Keep personal paths, private documents, credentials, and device identifiers out of commits and issues.

See [the design](docs/DESIGN.md) for the intended behavior and unresolved integration questions. Contributions are provided under the repository's [MIT license](LICENSE).
