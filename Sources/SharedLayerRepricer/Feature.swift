import Foundation

/// A unit of product surface that a team must decide how to implement:
/// once in a shared layer, or twice natively.
///
/// The four fields are deliberately the *only* inputs. Everything a team
/// argues about in this decision — "React Native is faster", "native feels
/// better" — collapses into these once you are pricing rather than debating.
public struct Feature: Identifiable, Hashable, Sendable {

    /// Stable identifier. Used for report ordering, so it must be unique
    /// within a catalog; `Repricer` does not deduplicate for you.
    public let id: String

    /// Human-readable name for reports and UI.
    public let name: String

    /// Engineer-days to build this feature *once*, natively, on one platform.
    /// Clamped to be non-negative.
    public let nativeBuildDays: Double

    /// Fraction of this feature's behaviour that genuinely has to differ per
    /// platform (0 = identical everywhere, 1 = nothing is reusable).
    /// Drives the cost of escape hatches out of the shared layer.
    /// Clamped to `0...1`.
    public let divergence: Double

    /// How expensive silent behavioural drift between platforms would be
    /// (0 = nobody notices, 1 = a support incident or a compliance problem).
    /// Drives the parity tax on the build-twice strategy.
    /// Clamped to `0...1`.
    public let parityCriticality: Double

    /// Substantive changes per year after the initial build.
    /// Clamped to be non-negative.
    public let changesPerYear: Double

    public init(
        id: String,
        name: String,
        nativeBuildDays: Double,
        divergence: Double,
        parityCriticality: Double,
        changesPerYear: Double
    ) {
        self.id = id
        self.name = name
        self.nativeBuildDays = max(0, nativeBuildDays)
        self.divergence = Self.unitClamp(divergence)
        self.parityCriticality = Self.unitClamp(parityCriticality)
        self.changesPerYear = max(0, changesPerYear)
    }

    /// Clamps to `0...1`, mapping NaN to 0 rather than propagating it.
    /// A NaN slider value silently poisoning an entire portfolio report is a
    /// worse failure than a wrong-but-visible zero.
    static func unitClamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(1, max(0, value))
    }
}
