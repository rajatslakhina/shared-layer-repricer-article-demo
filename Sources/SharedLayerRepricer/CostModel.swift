import Foundation

/// The parameters that turn a `Feature` into money.
///
/// The load-bearing asymmetry lives here and is stated rather than hidden:
/// `authoringDiscountMax` applies to work an agent can write, and
/// `parityCostPerChange` / `bridgeCostPerChange` deliberately do not get that
/// discount. Agents made authoring cheap. They did not make *checking that two
/// implementations agree* cheap. If you disagree with that premise, change
/// these numbers — the model is the argument, not the defaults.
public struct CostModel: Hashable, Sendable {

    /// Extra fraction a shared implementation costs over one native
    /// implementation, for abstraction, indirection and two-platform review.
    /// `0.35` means the shared version costs 1.35x a single native build.
    public let sharedAbstractionPremium: Double

    /// Per-platform native escape-hatch cost, as a fraction of
    /// `nativeBuildDays`, scaled by `divergence`. Paid twice (once per platform).
    public let escapeHatchPremium: Double

    /// Cost of the *second* native implementation as a fraction of the first,
    /// with no agent assistance. Near 1: you are building it again.
    public let unassistedPortFactor: Double

    /// Cost of the second native implementation as a fraction of the first at
    /// full agent assistance. This is the number the Shopify argument moves:
    /// porting from a finished implementation is the task agents are best at.
    public let assistedPortFactor: Double

    /// Maximum fraction by which agent assistance reduces *authoring* cost.
    /// Applied to both strategies — the shared layer gets the discount too.
    public let authoringDiscountMax: Double

    /// Engineer-days of verification per change, per unit of
    /// `parityCriticality`, to confirm two native implementations still agree.
    /// Receives no agent discount. This is the term the whole model turns on.
    public let parityCostPerChange: Double

    /// Engineer-days to author one substantive change, before discounts.
    public let changeAuthoringCost: Double

    /// Coordination cost per change that crosses the shared boundary: version
    /// pinning, release-train alignment, two teams agreeing on one API.
    /// Receives no agent discount either — the shared layer is not free of
    /// human-coordination cost just because an agent wrote the diff.
    public let bridgeCostPerChange: Double

    /// Years of ongoing cost to include. Clamped to be non-negative.
    public let horizonYears: Double

    public init(
        sharedAbstractionPremium: Double = 0.35,
        escapeHatchPremium: Double = 0.60,
        unassistedPortFactor: Double = 0.90,
        assistedPortFactor: Double = 0.30,
        authoringDiscountMax: Double = 0.45,
        parityCostPerChange: Double = 0.80,
        changeAuthoringCost: Double = 1.50,
        bridgeCostPerChange: Double = 0.35,
        horizonYears: Double = 3
    ) {
        self.sharedAbstractionPremium = max(0, sharedAbstractionPremium)
        self.escapeHatchPremium = max(0, escapeHatchPremium)
        self.unassistedPortFactor = max(0, unassistedPortFactor)
        self.assistedPortFactor = max(0, assistedPortFactor)
        self.authoringDiscountMax = Feature.unitClamp(authoringDiscountMax)
        self.parityCostPerChange = max(0, parityCostPerChange)
        self.changeAuthoringCost = max(0, changeAuthoringCost)
        self.bridgeCostPerChange = max(0, bridgeCostPerChange)
        self.horizonYears = max(0, horizonYears)
    }

    /// Multiplier on authoring cost at a given agent-assist level.
    /// `assist` is clamped to `0...1`.
    public func authoringMultiplier(assist: Double) -> Double {
        1 - authoringDiscountMax * Feature.unitClamp(assist)
    }

    /// Cost of the second native implementation relative to the first,
    /// interpolated linearly between the unassisted and assisted factors.
    public func portFactor(assist: Double) -> Double {
        let t = Feature.unitClamp(assist)
        return unassistedPortFactor + (assistedPortFactor - unassistedPortFactor) * t
    }

    /// The defaults, spelled out so callers can name what they are using.
    public static let `default` = CostModel()
}
