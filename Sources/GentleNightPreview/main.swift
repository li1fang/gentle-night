import Foundation
import GentleNightCore

private struct Options {
    var idleMinutes = 35.0
    var seed: UInt64 = 42
    var width = 96
    var height = 54
    var mode = FadeMode.probabilistic
}

private struct Preview: Encodable {
    let status = "model-only; no display control"
    let mode: FadeMode
    let idleMinutes: Double
    let startMinutes: Double
    let blackAtMinutes: Double
    let progress: Double
    let recoverySeconds: Double
    let seed: UInt64
    let width: Int
    let height: Int
    let meanMaskOpacity: Double
    let fullyBlackFraction: Double
    let untouchedFraction: Double
}

private enum UsageError: Error, CustomStringConvertible {
    case invalid(String)
    var description: String {
        switch self { case .invalid(let message): return message }
    }
}

private func parse(_ args: [String]) throws -> Options {
    var result = Options()
    var index = 0
    while index < args.count {
        let key = args[index]
        guard index + 1 < args.count else { throw UsageError.invalid("Missing value for \(key)") }
        let value = args[index + 1]
        switch key {
        case "--idle-minutes":
            guard let number = Double(value), number.isFinite, number >= 0,
                  (number * 60).isFinite else { throw UsageError.invalid("Invalid idle minutes") }
            result.idleMinutes = number
        case "--seed":
            guard let number = UInt64(value) else { throw UsageError.invalid("Invalid seed") }
            result.seed = number
        case "--width", "--height":
            guard let number = Int(value), (1...512).contains(number) else {
                throw UsageError.invalid("Grid dimensions must be between 1 and 512")
            }
            if key == "--width" { result.width = number } else { result.height = number }
        case "--mode":
            guard let mode = FadeMode(rawValue: value) else { throw UsageError.invalid("Unknown mode") }
            result.mode = mode
        default:
            throw UsageError.invalid("Unknown option: \(key)")
        }
        index += 2
    }
    return result
}

do {
    let args = Array(CommandLine.arguments.dropFirst())
    if args == ["--help"] || args == ["-h"] {
        print("""
        gentle-night-preview [--idle-minutes 35] [--seed 42]
          [--mode uniform|iris|probabilistic] [--width 96] [--height 54]
        Prints model statistics as JSON. Does not affect your display.
        """)
    } else {
        let options = try parse(args)
        let schedule = FadeSchedule.standard
        let grid = try PixelGrid(width: options.width, height: options.height)
        let model = try MaskModel(seed: options.seed)
        let progress = schedule.progress(idleSeconds: options.idleMinutes * 60)
        var sum = 0.0
        var black = 0
        var untouched = 0
        for y in 0..<grid.height {
            for x in 0..<grid.width {
                let alpha = model.opacity(x: x, y: y, grid: grid, progress: progress, mode: options.mode)
                sum += alpha
                if alpha == 1 { black += 1 }
                if alpha == 0 { untouched += 1 }
            }
        }
        let count = Double(grid.width * grid.height)
        let preview = Preview(
            mode: options.mode, idleMinutes: options.idleMinutes,
            startMinutes: schedule.startAfter / 60, blackAtMinutes: schedule.blackAfter / 60,
            progress: progress, recoverySeconds: schedule.recoveryDuration(from: progress),
            seed: options.seed, width: grid.width, height: grid.height,
            meanMaskOpacity: sum / count, fullyBlackFraction: Double(black) / count,
            untouchedFraction: Double(untouched) / count
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(preview)
        print(String(decoding: data, as: UTF8.self))
    }
} catch {
    FileHandle.standardError.write(Data("gentle-night-preview: \(error)\n".utf8))
    exit(1)
}
