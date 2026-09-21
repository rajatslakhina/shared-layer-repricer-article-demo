import Foundation

/// Total cost of one strategy for one feature over the model's horizon,
/// split so a reader can see *which term* is doing the work.
public struct CostBreakdown: Hashable, Sendable {
    /// One-off implementation cost.
    public let build: Double
    /// Ongoing authoring cost over the horizon.
    public let ongoingAuthoring: Double
    /// Ongoing cost that agent assistance does not reduce: parity verification
    /// for the native strategy, boundary coordination for the shared strategy.
    public let ongoingUndiscounted: Double

    public var total: Double { build + ongoingAuthoring + ongoingUndiscounted }

    init(build: Double, ongoingAuthoring: Double, ongoingUndiscounted: Double) {
        self.build = build
        self.ongoingAuthoring = ongoingAuthoring
        self.ongoingUndiscounted = ongoingUndiscounted
    }
}

/// Prices both strategies for a feature at a given agent-assist level.
///
/// `assist` is a single scalar in `0...1` standing for "how much of this
/// team's authoring an agent actually does, end to end, including review
/// rework". It is not a model benchmark and not a seat count.
public struct Repricer: Sendable {

    public let model: CostModel

    public init(model: CostModel = .default) {
        self.model = model
    }

    /// Cost of building once in a shared layer and calling it from both platforms.
    public func sharedCost(for feature: Feature, assist: Double) -> CostBreakdown {
        let author = model.authoringMultiplier(assist: assist)
        let base = feature.nativeBuildDays

        let core = base * (1 + model.sharedAbstractionPremium) * author
        // Escape hatches are native work, paid once per platform.
        let hatches = base * feature.divergence * model.escapeHatchPremium * 2 * author

        let ongoingAuthoring =
            feature.changesPerYear * model.changeAuthoringCost * author * model.horizonYears
        let ongoingUndiscounted =
            feature.changesPerYear * model.bridgeCostPerChange * model.horizonYears

        return CostBreakdown(
            build: core + hatches,
            ongoingAuthoring: ongoingAuthoring,
            ongoingUndiscounted: ongoingUndiscounted
        )
    }

    /// Cost of building the feature twice, natively, on both platforms.
    public func nativeCost(for feature: Feature, assist: Double) -> CostBreakdown {
        let author = model.authoringMultiplier(assist: assist)
        let port = model.portFactor(assist: assist)
        let base = feature.nativeBuildDays

        let build = base * author * (1 + port)

        let ongoingAuthoring =
            feature.changesPerYear * model.changeAuthoringCost * author * (1 + port) * model.horizonYears
        // The parity tax. No agent discount: this is verification, not authoring.
        let ongoingUndiscounted =
            feature.changesPerYear * model.parityCostPerChange * feature.parityCriticality * model.horizonYears

        return CostBreakdown(
            build: build,
            ongoingAuthoring: ongoingAuthoring,
            ongoingUndiscounted: ongoingUndiscounted
        )
    }

    /// `sharedTotal - nativeTotal`. Positive means building twice is cheaper.
    public func delta(for feature: Feature, assist: Double) -> Double {
        sharedCost(for: feature, assist: assist).total
            - nativeCost(for: feature, assist: assist).total
    }
}
