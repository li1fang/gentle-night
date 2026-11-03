# Gentle Night documentation

Gentle Night is a free, MIT-licensed macOS menu-bar screen dimmer for idle OLED displays. It gradually masks the live desktop to black without invoking the lock screen or disconnecting the display. The native prototype uses Swift, AppKit and Metal; it is currently built from source.

| I want to… | Read |
| --- | --- |
| Build and try the app | [English quick start](../README.md#quick-start) · [中文快速开始](../README.zh-CN.md#快速开始) |
| Understand behavior, privacy and limitations | [FAQ](FAQ.md) · [中文常见问题](FAQ.zh-CN.md) |
| Understand probabilistic pixel disappearance | [Visual design and model](DESIGN.md) |
| Run accelerated checks | [Testing](TESTING.md) |
| See what was actually verified | [Candidate validation](VALIDATION.md) |
| Follow the implementation plan | [Native prototype plan](IMPLEMENTATION.md) |
| Make a contribution | [Contributing](../CONTRIBUTING.md) |
| Report a vulnerability | [Security policy](../SECURITY.md) |

## Documentation artwork

The README animation and comparison images depict an original illustrated desktop. They explain the survival model at enlarged pixel scale; they are not screenshots, runtime recordings or panel measurements. The SVG banner is original project artwork.

To regenerate the artwork, use Python 3.11+ and install the pinned Pillow version in a separate environment:

```sh
python3 -m venv .build/docs-tools
.build/docs-tools/bin/python -m pip install -r docs/requirements.txt
.build/docs-tools/bin/python scripts/generate-doc-assets.py
```

This optional documentation dependency is not an app runtime dependency. Artwork is provided under the project's MIT license.
