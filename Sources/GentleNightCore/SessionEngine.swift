import Foundation

/// The caller supplies monotonic seconds and aggregate input idle seconds.
public struct SessionEngine: Sendable {
    public var schedule: FadeSchedule
    public private(set) var progress = 0.0
    public private(set) var recovering = false
    private var resetAt: Double
    private var recoveryStart = 0.0
    private var recoveryFrom = 0.0
    private var lastNow: Double

    public init(schedule: FadeSchedule = .standard, now: Double) {
        self.schedule = schedule
        resetAt = now
        lastNow = now
    }

    public mutating func update(now: Double, inputIdle: Double, audio: Bool = false, paused: Bool = false) {
        guard now.isFinite, inputIdle.isFinite, inputIdle >= 0, now >= lastNow else {
            progress = 0; recovering = false; return
        }
        lastNow = now
        let active = audio || paused || inputIdle < now - resetAt
        if active {
            resetAt = now - min(inputIdle, now - resetAt)
            if audio || paused { resetAt = now }
            if progress > 0 && !recovering {
                recovering = true; recoveryStart = now; recoveryFrom = progress
            }
        }
        if recovering {
            progress = schedule.recoveryProgress(from: recoveryFrom, elapsed: now - recoveryStart)
            if progress == 0 { recovering = false; resetAt = now }
        } else {
            progress = schedule.progress(idleSeconds: min(inputIdle, max(0, now - resetAt)))
        }
    }

    public mutating func reset(now: Double) {
        self = SessionEngine(schedule: schedule, now: now)
    }
}
