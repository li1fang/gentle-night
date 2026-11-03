import AppKit
import MetalKit
import CoreGraphics
import IOKit.pwr_mgt
import GentleNightCore

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let renderer: Renderer
    let defaults = UserDefaults.standard
    var engine = SessionEngine(now: ProcessInfo.processInfo.systemUptime)
    var window: NSWindow?
    var view: MTKView?
    var status: NSStatusItem!
    var timer: Timer?
    var assertion: IOPMAssertionID = 0
    var cursorHidden = false
    var pausedUntil = 0.0
    var previewStart: Double?
    var previewRecovery: (Double, Double)?
    var seed = UInt32.random(in: 1...UInt32.max)
    var lastDraw = -1.0
    var lastProgress: Float = -1
    var drawnFrames = 0
    var lastAudioCheck = -1.0
    var audioActive: Bool? = false
    var smoke: Bool
    let accelerated = CommandLine.arguments.contains("--accelerated")
    var smokeStart = 0.0
    var smokeOriginalApp: pid_t?
    var smokePassed = true
    var sawBlack = false
    var sawClear = false
    var enabled: Bool { accelerated || defaults.bool(forKey: "enabled") }
    var mode: UInt32 { UInt32(max(0, min(2, defaults.integer(forKey: "mode")))) }
    var now: Double { ProcessInfo.processInfo.systemUptime }

    init(renderer: Renderer, smoke: Bool) {
        self.renderer = renderer; self.smoke = smoke
        super.init()
        defaults.register(defaults: ["enabled": false, "mode": 2, "startMinutes": 10.0, "blackMinutes": 60.0, "recoverySeconds": 0.8, "audioHold": true, "hideCursor": false])
        reloadSchedule()
    }
    func reloadSchedule() {
        if accelerated { engine = SessionEngine(schedule: try! FadeSchedule(startAfter: 3, blackAfter: 12), now: now); return }
        engine = SessionEngine(schedule: (try? FadeSchedule(startAfter: defaults.double(forKey: "startMinutes")*60, blackAfter: defaults.double(forKey: "blackMinutes")*60, maximumRecoveryDuration: defaults.double(forKey: "recoverySeconds"))) ?? .standard, now: now)
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "☾"
        rebuildMenu()
        smokeStart = now
        NotificationCenter.default.addObserver(self, selector: #selector(displayChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(suspend), name: NSWorkspace.willSleepNotification, object: nil)
        workspace.addObserver(self, selector: #selector(suspend), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        workspace.addObserver(self, selector: #selector(suspend), name: NSWorkspace.didWakeNotification, object: nil)
        if smoke {
            smokeOriginalApp = NSWorkspace.shared.frontmostApplication?.processIdentifier
            smokeStart = now
            engine = SessionEngine(schedule: try! FadeSchedule(startAfter: 0.2, blackAfter: 1.2), now: smokeStart)
        }
        updatePower()
        scheduleTick(after: 0.05)
    }
    func scheduleTick(after interval: Double) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }
    func tick() {
        let time = now
        if accelerated && time-smokeStart >= 45 {
            print("LIVE SESSION: black endpoint observed = \(sawBlack); terminating and clearing overlay."); fflush(stdout)
            NSApplication.shared.terminate(nil); return
        }
        var u = 0.0
        if smoke {
            let elapsed = time - smokeStart
            let fakeIdle = elapsed < 1.5 ? elapsed : max(0, elapsed - 1.5)
            engine.update(now: time, inputIdle: fakeIdle, paused: elapsed >= 2.5)
            u = engine.progress
            sawBlack = sawBlack || u == 1
            sawClear = sawClear || (elapsed > 2.4 && u == 0)
            if NSWorkspace.shared.frontmostApplication?.processIdentifier != smokeOriginalApp { smokePassed = false }
            if elapsed >= 3 {
                clear(); timer?.invalidate()
                let pass = smokePassed && sawBlack && sawClear && drawnFrames > 5 && window == nil && !cursorHidden && assertion == 0
                print(pass ? "WINDOW PASS: accelerated fade/black/recovery, focus preserved, window removed, no cursor or power assertion leak." : "WINDOW FAIL: focus or lifecycle invariant")
                fflush(stdout); exit(pass ? 0 : 1)
            }
        } else if let start = previewStart {
            let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
            if time-start > 0.3 && idle < time-start-0.15 && previewRecovery == nil {
                previewRecovery = (time, min(1, (time-start)/8))
            }
            if time-start >= 10 && previewRecovery == nil { previewRecovery = (time, 1) }
            if let (began, from) = previewRecovery {
                u = engine.schedule.recoveryProgress(from: from, elapsed: time-began)
                if u == 0 { previewStart = nil; previewRecovery = nil; engine.reset(now: time) }
            } else { u = min(1, (time-start)/8) }
        } else if enabled {
            if time-lastAudioCheck >= 1 {
                audioActive = defaults.bool(forKey: "audioHold") && !accelerated ? AudioState.outputActive() : false
                lastAudioCheck = time
            }
            let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
            // A failed audio query holds the screen visible; it is not evidence of silence.
            engine.update(now: time, inputIdle: idle, audio: audioActive != false, paused: time < pausedUntil)
            u = engine.progress
        }
        if u > 0 {
            if window == nil { createOverlay() }
            if !smoke && defaults.bool(forKey: "hideCursor") && !cursorHidden {
                cursorHidden = CGDisplayHideCursor(CGMainDisplayID()) == .success
            }
            let recovering = engine.recovering || previewRecovery != nil
            if recovering && cursorHidden { CGDisplayShowCursor(CGMainDisplayID()); cursorHidden = false }
            if Float(u) != lastProgress && (time-lastDraw >= (recovering ? 1.0/60 : (previewStart != nil || smoke ? 1.0/30 : 1)) || u == 1) {
                if let view, renderer.draw(view: view, uniforms: .init(progress: Float(u), mode: mode, seed: seed)) {
                    drawnFrames += 1; lastDraw = time; lastProgress = Float(u)
                    if accelerated && u == 1 && !sawBlack {
                        sawBlack = true; print("LIVE SESSION: actual idle reached black endpoint; GPU frame submitted."); fflush(stdout)
                    }
                }
            }
        } else { clear() }
        let interval = u > 0 ? ((engine.recovering || previewRecovery != nil) ? 1.0/60 : 0.1) : (smoke || previewStart != nil ? 0.05 : 1)
        scheduleTick(after: interval)
    }
    func createOverlay() {
        guard let screen = NSScreen.main else { return }
        let frame = smoke ? NSRect(x: screen.frame.minX+40, y: screen.frame.minY+40, width: 256, height: 144) : screen.frame
        let overlay = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
        overlay.isReleasedWhenClosed = false
        overlay.backgroundColor = .clear; overlay.isOpaque = false; overlay.hasShadow = false
        overlay.level = .screenSaver; overlay.ignoresMouseEvents = true
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let metal = MTKView(frame: NSRect(origin: .zero, size: frame.size), device: renderer.device)
        metal.colorPixelFormat = .bgra8Unorm; metal.isPaused = true; metal.enableSetNeedsDisplay = false
        metal.clearColor = MTLClearColorMake(0,0,0,0); metal.layer?.isOpaque = false
        metal.wantsLayer = true; metal.layer?.isOpaque = false
        overlay.contentView = metal
        window = overlay; view = metal; lastDraw = -1; lastProgress = -1
        overlay.orderFrontRegardless()
    }
    func clear() {
        window?.orderOut(nil); window?.close(); window = nil; view = nil; lastDraw = -1; lastProgress = -1
        if cursorHidden { CGDisplayShowCursor(CGMainDisplayID()); cursorHidden = false }
    }
    func updatePower() {
        if enabled && !smoke && assertion == 0 {
            IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), "Gentle Night visual idle protection" as CFString, &assertion)
        } else if (!enabled || smoke) && assertion != 0 {
            IOPMAssertionRelease(assertion); assertion = 0
        }
    }
    func rebuildMenu() {
        let menu = NSMenu()
        func item(_ title: String, _ action: Selector, checked: Bool = false, tag: Int = 0) {
            let entry = NSMenuItem(title: title, action: action, keyEquivalent: "")
            entry.target = self; entry.state = checked ? .on : .off; entry.tag = tag; menu.addItem(entry)
        }
        item("Enable automatic fading", #selector(toggleEnabled), checked: enabled)
        item("Pause for 1 hour", #selector(pause))
        item("Restore now / cancel preview", #selector(restore))
        item("Preview: 8 seconds (auto-restores)", #selector(preview))
        menu.addItem(.separator())
        for (i, name) in ["Uniform", "Soft iris", "Probabilistic disappearance"].enumerated() {
            item(name, #selector(changeMode(_:)), checked: mode == UInt32(i), tag: i)
        }
        menu.addItem(.separator())
        item("Hold while audio output is active", #selector(toggleAudio), checked: defaults.bool(forKey: "audioHold"))
        item("Try hiding cursor (experimental)", #selector(toggleCursor), checked: defaults.bool(forKey: "hideCursor"))
        item("Timing settings…", #selector(settings))
        item("Quit Gentle Night", #selector(quit))
        status.menu = menu
    }
    @objc func toggleEnabled() { if accelerated { quit(); return }; defaults.set(!enabled, forKey: "enabled"); restore(); updatePower(); rebuildMenu() }
    @objc func pause() { pausedUntil = now+3600; restore() }
    @objc func restore() { previewStart = nil; previewRecovery = nil; engine.reset(now: now); clear() }
    @objc func preview() { restore(); seed = .random(in: 1...UInt32.max); previewStart = now }
    @objc func changeMode(_ item: NSMenuItem) { defaults.set(item.tag, forKey: "mode"); restore(); rebuildMenu() }
    @objc func toggleAudio() { defaults.set(!defaults.bool(forKey: "audioHold"), forKey: "audioHold"); lastAudioCheck = -1; restore(); rebuildMenu() }
    @objc func toggleCursor() { defaults.set(!defaults.bool(forKey: "hideCursor"), forKey: "hideCursor"); restore(); rebuildMenu() }
    @objc func suspend() { restore() }
    @objc func displayChanged() { restore() }
    @objc func settings() {
        restore()
        let alert = NSAlert(); alert.messageText = "Gentle Night timing"
        alert.informativeText = "Start / full black in total idle minutes; maximum recovery in seconds. Audio detection checks output streams, including possibly silent streams. Automatic screensavers must be configured separately."
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 8
        let keys = ["startMinutes", "blackMinutes", "recoverySeconds"]
        let labels = ["Start after minutes", "Black at minutes", "Maximum recovery seconds"]
        var fields = [NSTextField]()
        for (key,label) in zip(keys,labels) {
            stack.addArrangedSubview(NSTextField(labelWithString: label))
            let field = NSTextField(string: String(defaults.double(forKey:key))); fields.append(field); stack.addArrangedSubview(field)
        }
        stack.frame = NSRect(x:0,y:0,width:320,height:160); alert.accessoryView = stack
        alert.addButton(withTitle:"Save"); alert.addButton(withTitle:"Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        guard let start = Double(fields[0].stringValue), let black = Double(fields[1].stringValue), let recovery = Double(fields[2].stringValue),
              recovery <= 5, (try? FadeSchedule(startAfter:start*60, blackAfter:black*60, maximumRecoveryDuration: recovery)) != nil else {
            let error = NSAlert(); error.messageText = "Use finite values: 0 ≤ start < black, recovery 0–5 seconds."; error.runModal(); return
        }
        for (key,field) in zip(keys,fields) { defaults.set(Double(field.stringValue)!,forKey:key) }; reloadSchedule()
    }
    @objc func quit() { NSApplication.shared.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate(); clear(); if assertion != 0 { IOPMAssertionRelease(assertion); assertion = 0 } }
}

@main struct Entry {
    @MainActor static func main() {
        do {
            let renderer = try Renderer()
            if CommandLine.arguments.contains("--diagnostics") {
                let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
                let audio: Any = AudioState.outputActive().map { $0 as Any } ?? NSNull()
                let data = try JSONSerialization.data(withJSONObject: ["inputIdleSeconds": idle, "audioOutputActive": audio], options: [.sortedKeys])
                print(String(decoding: data, as: UTF8.self)); return
            }
            if CommandLine.arguments.contains("--self-test") { try renderer.selfTest(); return }
            let application = NSApplication.shared
            if let id = Bundle.main.bundleIdentifier,
               NSRunningApplication.runningApplications(withBundleIdentifier: id).contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
                FileHandle.standardError.write(Data("Gentle Night is already running. Quit the existing instance first.\n".utf8)); exit(1)
            }
            application.setActivationPolicy(.accessory)
            let delegate = AppDelegate(renderer: renderer, smoke: CommandLine.arguments.contains("--smoke-test"))
            application.delegate = delegate
            withExtendedLifetime(delegate) { application.run() }
        } catch {
            FileHandle.standardError.write(Data("Gentle Night: \(error)\n".utf8)); exit(1)
        }
    }
}
