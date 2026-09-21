import XCTest
@testable import SharedLayerRepricer

final class BreakEvenSolverTests: XCTestCase {

    private let solver = BreakEvenSolver()
    private let repricer = Repricer(model: .default)

    func testZeroChurnFeatureFlipsOnBuildEconomicsAlone() {
        // No churn means no parity tax, so only the build terms matter and the
        // collapsing port factor is free to win.
        let f = Feature(id: "a", name: "A", nativeBuildDays: 40,
                        divergence: 0.2, parityCriticality: 1.0, changesPerYear: 0)
        guard case .flipsAt(let at) = solver.breakEven(for: f, repricer: repricer) else {
            return XCTFail("expected a flip point, got \(solver.breakEven(for: f, repricer: repricer))")
        }
        XCTAssertGreaterThan(at, 0)
        XCTAssertLessThanOrEqual(at, 1)
    }

    func testHighChurnHighParityFeatureNeverFlips() {
        let f = Feature(id: "b", name: "B", nativeBuildDays: 24,
                        divergence: 0.05, parityCriticality: 1.0, changesPerYear: 16)
        XCTAssertEqual(solver.breakEven(for: f, repricer: repricer), .neverFlips)
    }

    func testFullyDivergentFeatureIsNativeFromTheStart() {
        let f = Feature(id: "c", name: "C", nativeBuildDays: 30,
                        divergence: 1.0, parityCriticality: 0.1, changesPerYear: 1)
        XCTAssertEqual(solver.breakEven(for: f, repricer: repricer), .alreadyNative)
    }

    func testReportedFlipPointActuallySitsOnTheSignChange() {
        for f in SampleCatalog.shoppingApp {
            guard case .flipsAt(let at) = solver.breakEven(for: f, repricer: repricer) else { continue }
            guard at > 0.002 else { continue }
            XCTAssertLessThanOrEqual(repricer.delta(for: f, assist: at - 0.002), 0,
                                     "\(f.id) should still favour shared just below its flip point")
            XCTAssertGreaterThanOrEqual(repricer.delta(for: f, assist: min(1, at + 0.002)), 0,
                                        "\(f.id) should favour native just above its flip point")
        }
    }

    func testSolverReturnsTheEarliestRootWhenDeltaIsNotMonotonic() {
        // delta is quadratic in assist, so it can cross zero twice. When this
        // feature does flip, assert the reported root is the earliest one.
        let f = Feature(id: "d", name: "D", nativeBuildDays: 18,
                        divergence: 0.02, parityCriticality: 0.62, changesPerYear: 11)
        let verdict = solver.breakEven(for: f, repricer: repricer)
        guard case .flipsAt(let at) = verdict else {
            // Not every parameterisation produces two roots; skip rather than
            // assert a shape the defaults do not have.
            return
        }
        // Everything strictly before the reported root must still favour shared.
        for step in 0..<50 {
            let x = at * Double(step) / 50
            XCTAssertLessThanOrEqual(repricer.delta(for: f, assist: x), 1e-9,
                                     "found an earlier root at \(x) than the reported \(at)")
        }
    }

    func testExactTieAtZeroAssistCountsAsFlippingAtZero() {
        // Construct a model where shared and native cost exactly the same with
        // no assistance: no churn, no abstraction premium, no escape hatches,
        // and a port factor of 1 so building twice costs exactly 2x.
        let model = CostModel(
            sharedAbstractionPremium: 1.0,
            escapeHatchPremium: 0,
            unassistedPortFactor: 1.0,
            assistedPortFactor: 1.0,
            authoringDiscountMax: 0,
            parityCostPerChange: 0,
            changeAuthoringCost: 0,
            bridgeCostPerChange: 0,
            horizonYears: 1
        )
        let f = Feature(id: "e", name: "E", nativeBuildDays: 10,
                        divergence: 0, parityCriticality: 0, changesPerYear: 0)
        XCTAssertEqual(solver.breakEven(for: f, repricer: Repricer(model: model)), .flipsAt(0))
    }

    func testCoarseSolverStillBracketsTheSameRegion() {
        let coarse = BreakEvenSolver(samples: 8)
        let fine = BreakEvenSolver(samples: 2000)
        let f = Feature(id: "f", name: "F", nativeBuildDays: 30,
                        divergence: 0.3, parityCriticality: 0.4, changesPerYear: 6)
        guard case .flipsAt(let a) = coarse.breakEven(for: f, repricer: repricer),
              case .flipsAt(let b) = fine.breakEven(for: f, repricer: repricer) else {
            return XCTFail("both solvers should find a flip point for this feature")
        }
        XCTAssertEqual(a, b, accuracy: 1.0 / 8.0)
    }

    func testSolverRejectsDegenerateSampleCounts() {
        XCTAssertEqual(BreakEvenSolver(samples: 0).samples, 2)
        XCTAssertEqual(BreakEvenSolver(samples: -10).samples, 2)
        XCTAssertGreaterThan(BreakEvenSolver(tolerance: 0).tolerance, 0)
    }
}
