import Testing
@testable import GentleNightCore

struct CoreContractTests {
    @Test func scheduleAndProportionalRecovery() throws {
        let schedule = FadeSchedule.standard
        #expect(schedule.progress(idleSeconds: 599) == 0)
        #expect(schedule.progress(idleSeconds: 600) == 0)
        #expect(schedule.progress(idleSeconds: 2_100) == 0.5)
        #expect(schedule.progress(idleSeconds: 3_600) == 1)
        #expect(schedule.progress(idleSeconds: 7_200) == 1)
        #expect(schedule.progress(idleSeconds: .nan) == 0)
        #expect(abs(schedule.recoveryDuration(from: 0.5) - 0.4) <= 1e-12)
        #expect(abs(schedule.recoveryDuration(from: 1) - 0.8) <= 1e-12)
        #expect(abs(schedule.recoveryProgress(from: 0.5, elapsed: 0.2) - 0.25) <= 1e-12)
        #expect(schedule.recoveryProgress(from: 0.5, elapsed: 0.4) == 0)
        #expect(schedule.recoveryProgress(from: 1, elapsed: 1) == 0)
        let custom = try FadeSchedule(startAfter: 900, blackAfter: 3_600)
        #expect(custom.progress(idleSeconds: 900) == 0)
    }

    @Test func rejectsInvalidConfiguration() {
        #expect(throws: ConfigurationError.self) { try FadeSchedule(startAfter: 60, blackAfter: 60) }
        #expect(throws: ConfigurationError.self) { try FadeSchedule(startAfter: -1, blackAfter: 60) }
        #expect(throws: ConfigurationError.self) { try FadeSchedule(startAfter: 0, blackAfter: .infinity) }
        #expect(throws: ConfigurationError.self) {
            try FadeSchedule(startAfter: 0, blackAfter: 60, maximumRecoveryDuration: -1)
        }
        #expect(throws: ConfigurationError.self) { try PixelGrid(width: 0, height: 10) }
        #expect(throws: ConfigurationError.self) { try MaskModel(seed: 42, spatialBias: -.infinity) }
        #expect(throws: ConfigurationError.self) { try MaskModel(seed: 42, spatialBias: -1) }
    }

    @Test func everyModeHasExactEndpointsAndNoRelighting() throws {
        let grid = try PixelGrid(width: 33, height: 19)
        for seed: UInt64 in [0, 42, .max] {
            let model = try MaskModel(seed: seed)
            for mode in FadeMode.allCases {
                for y in 0..<grid.height {
                    for x in 0..<grid.width {
                        #expect(model.opacity(x: x, y: y, grid: grid, progress: 0, mode: mode) == 0)
                        #expect(model.opacity(x: x, y: y, grid: grid, progress: 1, mode: mode) == 1)
                        var previous = 0.0
                        for step in 0...50 {
                            let alpha = model.opacity(x: x, y: y, grid: grid, progress: Double(step) / 50, mode: mode)
                            #expect(alpha >= previous)
                            if mode == .probabilistic { #expect(alpha == 0 || alpha == 1) }
                            previous = alpha
                        }
                    }
                }
            }
        }
    }

    @Test func deterministicFieldAndReversePath() throws {
        let grid = try PixelGrid(width: 32, height: 18)
        let model = try MaskModel(seed: 42)
        let same = try MaskModel(seed: 42)
        let different = try MaskModel(seed: 43)
        var differentThresholds = 0
        for y in 0..<grid.height {
            for x in 0..<grid.width {
                let threshold = model.threshold(x: x, y: y, grid: grid)
                #expect(threshold > 0)
                #expect(threshold < 1)
                #expect(threshold == same.threshold(x: x, y: y, grid: grid))
                if threshold != different.threshold(x: x, y: y, grid: grid) { differentThresholds += 1 }
                // Recovery is compared with the earlier mask at the same
                // progress, without generating a new field or seed.
                for step in 0...8 {
                    let priorProgress = Double(8 - step) / 8
                    let recoveredProgress = FadeSchedule.standard.recoveryProgress(
                        from: 1, elapsed: Double(step) * 0.1
                    )
                    #expect(abs(recoveredProgress - priorProgress) <= 1e-12)
                    #expect(
                        model.opacity(x: x, y: y, grid: grid, progress: recoveredProgress) ==
                        model.opacity(x: x, y: y, grid: grid, progress: priorProgress)
                    )
                }
            }
        }
        #expect(differentThresholds > grid.width * grid.height / 2)
    }

    @Test func outerPixelsHaveLowerSurvivalWithoutAnInitialJump() throws {
        let model = try MaskModel(seed: 0)
        for step in 1..<100 {
            let u = Double(step) / 100
            #expect(
                model.survivalProbability(radiusSquared: 0, progress: u) >=
                model.survivalProbability(radiusSquared: 1, progress: u)
            )
        }
        #expect(model.survivalProbability(radiusSquared: 1, progress: 0) == 1)
        #expect(model.survivalProbability(radiusSquared: 1, progress: 1e-8) > 0.9999999)
        #expect(model.survivalProbability(radiusSquared: 0, progress: 1) == 0)
    }
}
