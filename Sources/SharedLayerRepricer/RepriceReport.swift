import Foundation

/// One feature's verdict, with enough detail to argue with.
public struct FeatureVerdict: Identifiable, Hashable, Sendable {
    public var id: String { feature.id }
    public let feature: Feature
    public let breakEven: BreakEven
    /// Shared-strategy cost at the assist level the report was built for.
    public let sharedTotal: Double
    /// Native-strategy cost at the same assist level.
    public let nativeTotal: Double

    /// True when building twice is the cheaper choice at the report's assist level.
    public var nativeWins: Bool { nativeTotal < sharedTotal }

    /// Engineer-days saved by taking the cheaper option. Never negative.
    public var saving: Double { abs(sharedTotal - nativeTotal) }
}

/// A whole catalog priced at one agent-assist level.
public struct RepriceReport: Sendable {

    public let assist: Double
    public let verdicts: [FeatureVerdict]

    /// Features that flip to native at or below this report's assist level.
    public var flipped: [FeatureVerdict] {
        verdicts.filter(\.nativeWins)
    }

    /// Features the shared layer keeps across the whole `0...1` assist range.
    public var neverFlipping: [FeatureVerdict] {
        verdicts.filter { $0.breakEven == .neverFlips }
    }

    /// Total engineer-days if every feature takes its cheaper option.
    public var bestCaseTotal: Double {
        verdicts.reduce(0) { $0 + min($1.sharedTotal, $1.nativeTotal) }
    }

    /// Total engineer-days if everything stays in the shared layer.
    public var allSharedTotal: Double {
        verdicts.reduce(0) { $0 + $1.sharedTotal }
    }

    /// Total engineer-days if everything is built twice.
    public var allNativeTotal: Double {
        verdicts.reduce(0) { $0 + $1.nativeTotal }
    }

    /// Verdicts ordered by the assist level at which they flip, earliest first.
    /// `.alreadyNative` sorts first, `.neverFlips` last; ties break on `id` so
    /// the ordering is stable enough to diff in CI.
    public var orderedByFlipPoint: [FeatureVerdict] {
        verdicts.sorted { lhs, rhs in
            let l = Self.sortKey(lhs.breakEven)
            let r = Self.sortKey(rhs.breakEven)
            if l != r { return l < r }
            return lhs.feature.id < rhs.feature.id
        }
    }

    private static func sortKey(_ breakEven: BreakEven) -> Double {
        switch breakEven {
        case .alreadyNative: return -1
        case .flipsAt(let value): return value
        case .neverFlips: return .greatestFiniteMagnitude
        }
    }

    /// Prices an entire catalog. Order of `verdicts` follows the input order.
    public static func build(
        catalog: [Feature],
        assist: Double,
        model: CostModel = .default,
        solver: BreakEvenSolver = BreakEvenSolver()
    ) -> RepriceReport {
        let repricer = Repricer(model: model)
        let clamped = Feature.unitClamp(assist)

        let verdicts = catalog.map { feature in
            FeatureVerdict(
                feature: feature,
                breakEven: solver.breakEven(for: feature, repricer: repricer),
                sharedTotal: repricer.sharedCost(for: feature, assist: clamped).total,
                nativeTotal: repricer.nativeCost(for: feature, assist: clamped).total
            )
        }

        return RepriceReport(assist: clamped, verdicts: verdicts)
    }
}
