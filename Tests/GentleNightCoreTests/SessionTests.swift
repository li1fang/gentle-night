import Testing
@testable import GentleNightCore

struct SessionTests {
    @Test func acceleratedHourAndRecovery() {
        var session = SessionEngine(now: 0)
        for second in stride(from: 0, through: 3600, by: 10) {
            session.update(now: Double(second), inputIdle: Double(second))
            let expected = max(0, min(1, Double(second-600)/3000))
            #expect(abs(session.progress-expected) < 1e-12)
        }
        session.update(now: 3600.1, inputIdle: 0)
        #expect(session.recovering)
        #expect(session.progress == 1)
        session.update(now: 3600.5, inputIdle: 0)
        #expect(abs(session.progress-0.5) < 1e-9)
        session.update(now: 3601, inputIdle: 0)
        #expect(session.progress == 0)
        #expect(!session.recovering)
        session.update(now: 3700, inputIdle: 99)
        #expect(session.progress == 0)
    }
    @Test func audioPauseAndResumeStartFresh() {
        var session = SessionEngine(now: 0)
        session.update(now: 2100, inputIdle: 2100)
        #expect(session.progress == 0.5)
        session.update(now: 2101, inputIdle: 2101, audio: true)
        session.update(now: 2102, inputIdle: 2102, audio: true)
        #expect(session.progress == 0)
        session.update(now: 7200, inputIdle: 7200, audio: true)
        #expect(session.progress == 0)
        session.update(now: 7500, inputIdle: 7500)
        #expect(session.progress == 0)
        session.update(now: 10800, inputIdle: 10800)
        #expect(session.progress == 1)
        session.update(now: 10801, inputIdle: 10801, paused: true)
        session.update(now: 10802, inputIdle: 10802, paused: true)
        #expect(session.progress == 0)
    }
    @Test func launchAndWakeDoNotInheritOldIdle() {
        var session = SessionEngine(now: 10000)
        session.update(now: 10001, inputIdle: 5000)
        #expect(session.progress == 0)
        session.update(now: 13600, inputIdle: 8600)
        #expect(session.progress == 1)
        session.reset(now: 20000)
        session.update(now: 20001, inputIdle: 15000)
        #expect(session.progress == 0)
        session.update(now: 20002, inputIdle: .nan)
        #expect(session.progress == 0)
    }
    @Test func activityAtPartialFadeUsesProportionalRecovery() {
        var session = SessionEngine(now: 0)
        session.update(now: 2100, inputIdle: 2100)
        session.update(now: 2101, inputIdle: 0)
        session.update(now: 2101.2, inputIdle: 0)
        #expect(abs(session.progress - 0.25) < 1e-9)
        session.update(now: 2101.41, inputIdle: 0)
        #expect(session.progress == 0)
    }
}
