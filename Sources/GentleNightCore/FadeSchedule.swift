import Foundation

public enum ConfigurationError: Error, Equatable, Sendable {
    case invalidSchedule
    case invalidGrid
    case invalidSpatialBias
}

/// All times are seconds. Read a monotonic idle clock in the future macOS adapter.
public struct FadeSchedule: Equatable, Sendable {
    public let startAfter: TimeInterval
    public let blackAfter: TimeInterval
    public let maximumRecoveryDuration: TimeInterval

    public static let standard = FadeSchedule(
        validatedStart: 600, black: 3_600, recovery: 0.8
    )

    public init(
        startAfter: TimeInterval,
        blackAfter: TimeInterval,
        maximumRecoveryDuration: TimeInterval = 0.8
    ) throws {
        guard startAfter.isFinite, blackAfter.isFinite,
              maximumRecoveryDuration.isFinite, startAfter >= 0,
              blackAfter > startAfter, maximumRecoveryDuration >= 0 else {
            throw ConfigurationError.invalidSchedule
        }
        self.init(
            validatedStart: startAfter, black: blackAfter,
            recovery: maximumRecoveryDuration
        )
    }

    private init(validatedStart: Double, black: Double, recovery: Double) {
        startAfter = validatedStart
        blackAfter = black
        maximumRecoveryDuration = recovery
    }

    /// Invalid clock samples fail clear rather than blanking the display.
    public func progress(idleSeconds: TimeInterval) -> Double {
        guard idleSeconds.isFinite, idleSeconds > startAfter else { return 0 }
        guard idleSeconds < blackAfter else { return 1 }
        return (idleSeconds - startAfter) / (blackAfter - startAfter)
    }

    public func recoveryDuration(from progress: Double) -> TimeInterval {
        maximumRecoveryDuration * unitProgress(progress)
    }

    /// Reverse the same mask at a constant progress speed; repeated input must
    /// not reset the recovery's start time in the future runtime controller.
    public func recoveryProgress(from progress: Double, elapsed: TimeInterval) -> Double {
        let initial = unitProgress(progress)
        guard maximumRecoveryDuration > 0 else { return 0 }
        guard !elapsed.isNaN, elapsed > 0 else { return initial }
        return max(0, initial - elapsed / maximumRecoveryDuration)
    }
}

func unitProgress(_ value: Double) -> Double {
    guard value.isFinite else { return 0 }
    return min(1, max(0, value))
}
