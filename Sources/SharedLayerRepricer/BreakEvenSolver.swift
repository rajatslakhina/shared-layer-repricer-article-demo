import Foundation

/// Where a feature's shared-vs-native decision flips as agent assistance rises.
public enum BreakEven: Hashable, Sendable {
    /// Building twice natively is already cheaper at zero agent assistance.
    case alreadyNative
    /// Building twice becomes cheaper at this assist level in `0...1`.
    case flipsAt(Double)
    /// The shared layer stays cheaper across the entire `0...1` range.
    /// This is the interesting bucket: no amount of agent help pays for the
    /// parity tax on these features.
    case neverFlips
}

/// Finds the agent-assist level at which a feature flips from shared to native.
///
/// Deliberately does *not* assume `delta(assist)` is monotonic. It is not:
/// the native strategy's build and authoring terms both carry the product
/// `authoringMultiplier(assist) * (1 + portFactor(assist))`, which is quadratic
/// in `assist`, so `delta` is a parabola and can cross zero twice. A plain
/// bisection over `[0, 1]` would silently return whichever root the endpoints
/// happened to bracket, or miss both. This scans for sign changes first and
/// then bisects the earliest bracket.
public struct BreakEvenSolver: Sendable {

    /// Number of sample intervals across `0...1` used to bracket roots.
    /// 200 is comfortably finer than the curvature of a parabola on a unit
    /// interval; it exists as a parameter so tests can starve it on purpose.
    public let samples: Int

    /// Bisection tolerance on the assist axis.
    public let tolerance: Double

    public init(samples: Int = 200, tolerance: Double = 1e-6) {
        self.samples = max(2, samples)
        self.tolerance = max(1e-12, tolerance)
    }

    public func breakEven(for feature: Feature, repricer: Repricer) -> BreakEven {
        let f: (Double) -> Double = { repricer.delta(for: feature, assist: $0) }

        let atZero = f(0)
        if atZero > 0 { return .alreadyNative }
        // Exactly zero at the left edge counts as flipping there, not as
        // "never" — a tie at no assistance already means native is no worse.
        if atZero == 0 { return .flipsAt(0) }

        var previousX = 0.0
        var previousY = atZero

        for step in 1...samples {
            let x = Double(step) / Double(samples)
            let y = f(x)

            if y == 0 { return .flipsAt(x) }
            if y > 0 {
                return .flipsAt(bisect(f, low: previousX, high: x, lowValue: previousY))
            }
            previousX = x
            previousY = y
        }

        return .neverFlips
    }

    /// Bisects a bracket known to contain a sign change from negative to positive.
    private func bisect(
        _ f: (Double) -> Double,
        low: Double,
        high: Double,
        lowValue: Double
    ) -> Double {
        var lo = low
        var hi = high
        var loValue = lowValue

        // The bracket is at most 1/samples wide, so the iteration count is
        // bounded by log2(1 / (samples * tolerance)); the cap is a belt-and-braces
        // guard against a pathological non-finite delta, not an expected path.
        var iterations = 0
        while hi - lo > tolerance && iterations < 200 {
            let mid = (lo + hi) / 2
            let midValue = f(mid)
            if midValue == 0 { return mid }
            if (midValue < 0) == (loValue < 0) {
                lo = mid
                loValue = midValue
            } else {
                hi = mid
            }
            iterations += 1
        }
        return (lo + hi) / 2
    }
}
