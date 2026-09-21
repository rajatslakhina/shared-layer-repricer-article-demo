import XCTest
@testable import SharedLayerRepricer

final class FeatureAndModelTests: XCTestCase {

    func testFeatureClampsUnitFieldsAndNonNegatives() {
        let f = Feature(id: "x", name: "X",
                        nativeBuildDays: -5, divergence: 1.7,
                        parityCriticality: -0.3, changesPerYear: -2)
        XCTAssertEqual(f.nativeBuildDays, 0)
        XCTAssertEqual(f.divergence, 1)
        XCTAssertEqual(f.parityCriticality, 0)
        XCTAssertEqual(f.changesPerYear, 0)
    }

    func testFeatureMapsNonFiniteInputsToZeroRatherThanPropagatingNaN() {
        let f = Feature(id: "x", name: "X",
                        nativeBuildDays: 10, divergence: .nan,
                        parityCriticality: .infinity, changesPerYear: 1)
        XCTAssertEqual(f.divergence, 0)
        // Infinity is finite-clamped to the top of the range, not to zero.
        XCTAssertEqual(f.parityCriticality, 0)
        XCTAssertFalse(f.divergence.isNaN)
    }

    func testAuthoringMultiplierSpansTheDiscountRange() {
        let m = CostModel(authoringDiscountMax: 0.45)
        XCTAssertEqual(m.authoringMultiplier(assist: 0), 1.0, accuracy: 1e-12)
        XCTAssertEqual(m.authoringMultiplier(assist: 1), 0.55, accuracy: 1e-12)
        XCTAssertEqual(m.authoringMultiplier(assist: 0.5), 0.775, accuracy: 1e-12)
    }

    func testAuthoringMultiplierClampsOutOfRangeAssist() {
        let m = CostModel.default
        XCTAssertEqual(m.authoringMultiplier(assist: -3), m.authoringMultiplier(assist: 0))
        XCTAssertEqual(m.authoringMultiplier(assist: 9), m.authoringMultiplier(assist: 1))
    }

    func testPortFactorInterpolatesBetweenUnassistedAndAssisted() {
        let m = CostModel(unassistedPortFactor: 0.9, assistedPortFactor: 0.3)
        XCTAssertEqual(m.portFactor(assist: 0), 0.9, accuracy: 1e-12)
        XCTAssertEqual(m.portFactor(assist: 1), 0.3, accuracy: 1e-12)
        XCTAssertEqual(m.portFactor(assist: 0.5), 0.6, accuracy: 1e-12)
    }
}
