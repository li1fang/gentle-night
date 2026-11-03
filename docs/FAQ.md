# Gentle Night FAQ

[简体中文](FAQ.zh-CN.md) · [Quick start](../README.md#quick-start)

## Can I gradually black out my Mac without locking it?

Yes. Gentle Night is a macOS screen-dimming app that draws a visual overlay over the live desktop. By default it begins at 10 idle minutes and reaches black at 60. Keyboard or mouse activity reverses the effect. It does not invoke the system lock screen, screensaver, or display disconnect.

macOS can still run its own screensaver according to system settings. Gentle Night does not change those settings or override a manual lock. It is not a privacy or security lock.

## Does it work with an LG OLED TV used as a Mac monitor?

That is one of the intended use cases. The overlay does not depend on DDC/CI hardware brightness control, so it does not require the TV to expose a brightness command to macOS. A bounded native test has run on the developer's LG TV setup; that is not certification for every LG model or connection path.

Native output resolution, HiDPI scaling, HDR and physical black level need checking on your setup. The GPU can produce binary black/transparent render pixels while the display pipeline still blends them. See [validation](VALIDATION.md) and [manual acceptance](TESTING.md).

## How is pixel dissolve different from ordinary dimming?

Uniform dimming covers the entire image with increasing black opacity. Pixel dissolve makes each render pixel either transparent or opaque black. Visible areas keep showing current desktop colors. The probability of remaining visible decreases faster at the edges, leaving a shrinking sparse center.

Thresholds remain fixed during the cycle, so the effect does not resample random noise every frame. It currently uses stable coordinate hashes, not blue-noise thresholds. The [design](DESIGN.md) includes the survival model.

## Why does a silent video stop it from fading?

The optional audio hold checks whether any process has an active audio output stream. A silent track or muted video may keep that stream active. This lightweight check does not measure audible sound, record system audio, or open the microphone.

You can turn off **Hold while audio output is active** in the menu. Accurate signal-level silence detection is not implemented. If metadata is unavailable, including on macOS before 14.2, audio hold conservatively keeps the screen visible.

## Why is the mouse pointer still visible?

macOS can draw the system pointer above the overlay. **Try hiding cursor (experimental)** is off by default. Its effectiveness while preserving another app's focus is not guaranteed; API success is not proof that the pointer disappeared. The app does not move the pointer to hide it.

## Does the first click only wake the screen?

No. The overlay is click-through, and the first key or click is delivered to the app underneath. The fade reverses without taking focus. A blind click can therefore activate a control. Use mouse movement to restore before clicking if you need to see the target first.

## Can my automation keep working while the display is black?

The desktop remains unlocked, and the overlay does not intercept input. Background/API tasks can continue. Screenshot, OCR, pixel-color and remote-control automation may see the overlay, so their compatibility must be tested separately. Gentle Night does not promise that all visual automation can see through it.

## Will it prevent OLED burn-in or save power?

No such guarantee is made. The project aims to reduce visible static content during idle time, but has not measured panel energy savings or long-term wear. It does not replace the display's built-in pixel cleaning or maintenance.

## Is there an installer or Homebrew command?

Not yet. Build from source using the [quick start](../README.md#quick-start). The local app is ad-hoc signed, not notarized. Do not assume a third-party download is an official release. The project does not ask you to disable Gatekeeper or remove quarantine attributes.

## What is stored or sent?

Timing, effect and toggles are stored locally using macOS UserDefaults. The app has no account, analytics or network calls and does not capture screenshots or audio samples. Building from source and opening external documentation can access the network. Optional test scripts generate logs locally under `test-results/`.

## How do I remove it and restore normal sleep behavior?

Choose **Quit Gentle Night** from the ☾ menu. Normal quit removes its overlay, restores a cursor hidden by the app, and releases its temporary idle-display-sleep assertion. Then delete the locally built `.app` or source checkout if desired. No login item or background service is installed.

Quitting does not change your global screensaver or password settings. Local preferences may remain in UserDefaults; deleting the app is not a preference reset. Force-kill behavior with experimental cursor hiding needs separate testing.

## How do I pause or reset it?

**Pause for 1 hour** suppresses fading temporarily. **Restore now / cancel preview** removes the current effect immediately; it does not cancel an existing one-hour pause. The source currently has no “resume pause early” command. For shorter trials, use the bounded eight-second preview.

## Where can I contribute?

See [contributing](../CONTRIBUTING.md). Display scaling/HDR, cursor behavior, audio heuristics, accessibility and setup documentation are active areas. Share only the device and reproduction details needed to investigate, rather than private desktop content.
