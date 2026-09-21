import XCTest
@testable import SharedLayerRepricer

final class RepricerTests: XCTestCase {

    private let repricer = Repricer(model: .default)

    private func feature(
        build: Double = 20,
        divergence: Double = 0.2,
        parity: Double = 0.5,
        churn: Double = 10
    ) -> Feature {
        Feature(id: "f", name: "F",
                nativeBuildDays: build, divergence: divergence,
                parityCriticality: parity, changesPerYear: churn)
    }

    // MARK: - The claim the whole article rests on

    func testParityTaxIsInvariantToAgentAssist() {
        let f = feature()
        let atZero = repricer.nativeCost(for: f, assist: 0).ongoingUndiscounted
        let atHalf = repricer.nativeCost(for: f, assist: 0.5).ongoingUndiscounted
        let atFull = repricer.nativeCost(for: f, assist: 1).ongoingUndiscounted

        XCTAssertGreaterThan(atZero, 0)
        XCTAssertEqual(atZero, atHalf, accuracy: 1e-12)
        XCTAssertEqual(atZero, atFull, accuracy: 1e-12)
    }

    func testAuthoringTermsDoShrinkWithAgentAssist() {
        let f = feature()
        XCTAssertLessThan(
            repricer.nativeCost(for: f, assist: 1).ongoingAuthoring,
            repricer.nativeCost(for: f, assist: 0).ongoingAuthoring
        )
        XCTAssertLessThan(
            repricer.sharedCost(for: f, assist: 1).ongoingAuthoring,
            repricer.sharedCost(for: f, assist: 0).ongoingAuthoring
        )
    }

    func testBridgeCostOnTheSharedSideIsAlsoInvariantToAssist() {
        // The model is not rigged: the shared strategy has an undiscounted
        // coordination term too. The asymmetry is in the size, not the presence.
        let f = feature()
        XCTAssertEqual(
            repricer.sharedCost(for: f, assist: 0).ongoingUndiscounted,
            repricer.sharedCost(for: f, assist: 1).ongoingUndiscounted,
            accuracy: 1e-12
        )
    }

    // MARK: - Structure

    func testBreakdownTotalIsTheSumOfItsParts() {
        let b = repricer.nativeCost(for: feature(), assist: 0.4)
        XCTAssertEqual(b.total, b.build + b.ongoingAuthoring + b.ongoingUndiscounted, accuracy: 1e-9)
    }

    func testZeroBuildDaysAndZeroChurnCostNothingEitherWay() {
        let f = feature(build: 0, churn: 0)
        XCTAssertEqual(repricer.sharedCost(for: f, assist: 0.5).total, 0, accuracy: 1e-12)
        XCTAssertEqual(repricer.nativeCost(for: f, assist: 0.5).total, 0, accuracy: 1e-12)
        XCTAssertEqual(repricer.delta(for: f, assist: 0.5), 0, accuracy: 1e-12)
    }

    func testHighDivergenceMakesTheSharedLayerMoreExpensive() {
        let low = feature(divergence: 0.0, churn: 0)
        let high = feature(divergence: 1.0, churn: 0)
        XCTAssertGreaterThan(
            repricer.sharedCost(for: high, assist: 0).total,
            repricer.sharedCost(for: low, assist: 0).total
        )
        // ...and does not touch the native side at all.
        XCTAssertEqual(
            repricer.nativeCost(for: high, assist: 0).total,
            repricer.nativeCost(for: low, assist: 0).total,
            accuracy: 1e-12
        )
    }

    func testZeroHorizonPricesBuildCostOnly() {
        let model = CostModel(horizonYears: 0)
        let r = Repricer(model: model)
        let f = feature(churn: 50)
        XCTAssertEqual(r.nativeCost(for: f, assist: 0).ongoingAuthoring, 0, accuracy: 1e-12)
        XCTAssertEqual(r.nativeCost(for: f, assist: 0).ongoingUndiscounted, 0, accuracy: 1e-12)
        XCTAssertEqual(r.nativeCost(for: f, assist: 0).total,
                       r.nativeCost(for: f, assist: 0).build, accuracy: 1e-12)
    }
}
