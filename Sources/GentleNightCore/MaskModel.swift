import Foundation

public enum FadeMode: String, CaseIterable, Codable, Sendable {
    case uniform
    case iris
    case probabilistic
}

/// A render grid, not a claim about physical OLED pixel mapping.
public struct PixelGrid: Equatable, Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) throws {
        guard width > 0, height > 0 else { throw ConfigurationError.invalidGrid }
        self.width = width
        self.height = height
    }

    /// Squared distance from screen center, normalized by the half-diagonal.
    public func radiusSquared(x: Int, y: Int) -> Double {
        precondition((0..<width).contains(x) && (0..<height).contains(y))
        let halfWidth = Double(width) / 2
        let halfHeight = Double(height) / 2
        let dx = Double(x) + 0.5 - halfWidth
        let dy = Double(y) + 0.5 - halfHeight
        return (dx * dx + dy * dy) / (halfWidth * halfWidth + halfHeight * halfHeight)
    }
}

/// One seed per fade cycle. No frame index or wall clock participates in the
/// thresholds, so a pixel cannot relight while progress increases.
public struct MaskModel: Equatable, Sendable {
    public let seed: UInt64
    public let spatialBias: Double

    public init(seed: UInt64, spatialBias: Double = 3) throws {
        guard spatialBias.isFinite, spatialBias >= 0 else {
            throw ConfigurationError.invalidSpatialBias
        }
        self.seed = seed
        self.spatialBias = spatialBias
    }

    /// Endpoint-normalized Gaussian-like survival probability. The explicit
    /// endpoints avoid division by zero and guarantee a complete black finish.
    public func survivalProbability(radiusSquared: Double, progress: Double) -> Double {
        let u = unitProgress(progress)
        if u == 0 { return 1 }
        if u == 1 { return 0 }
        precondition(radiusSquared.isFinite && radiusSquared >= 0)
        return (1 - u) * exp(-spatialBias * radiusSquared * u / (1 - u))
    }

    /// Stable independent hash thresholds; this is NOT a blue-noise sampler.
    public func threshold(x: Int, y: Int, grid: PixelGrid) -> Double {
        precondition((0..<grid.width).contains(x) && (0..<grid.height).contains(y))
        var key = seed
        key ^= UInt64(x) &* 0x9e3779b97f4a7c15
        key ^= UInt64(y) &* 0xbf58476d1ce4e5b9
        key ^= UInt64(grid.width) &* 0x94d049bb133111eb
        key ^= UInt64(grid.height) &* 0xd6e8feb86659fd93
        let bits = Self.mix(key) >> 12
        // 52 bits plus a half-step gives q strictly between zero and one.
        return (Double(bits) + 0.5) / 4_503_599_627_370_496
    }

    /// Zero leaves the CURRENT desktop untouched; one means opaque RGB zero.
    /// A future compositor must preserve binary alpha for probabilistic mode.
    public func opacity(
        x: Int, y: Int, grid: PixelGrid, progress: Double,
        mode: FadeMode = .probabilistic
    ) -> Double {
        let u = unitProgress(progress)
        if u == 0 { return 0 }
        if u == 1 { return 1 }
        switch mode {
        case .uniform:
            return u
        case .iris:
            let radius = 1 - u
            let inner = max(0, radius - 0.08)
            let r = sqrt(grid.radiusSquared(x: x, y: y))
            let t = min(1, max(0, (r - inner) / (radius - inner)))
            return t * t * (3 - 2 * t)
        case .probabilistic:
            let probability = survivalProbability(
                radiusSquared: grid.radiusSquared(x: x, y: y), progress: u
            )
            return threshold(x: x, y: y, grid: grid) < probability ? 0 : 1
        }
    }

    private static func mix(_ input: UInt64) -> UInt64 {
        var z = input &+ 0x9e3779b97f4a7c15
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
