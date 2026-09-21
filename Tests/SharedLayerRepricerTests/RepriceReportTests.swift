import XCTest
@testable import SharedLayerRepricer

final class RepriceReportTests: XCTestCase {

    func testEmptyCatalogProducesAnEmptyReportWithoutCrashing() {
        let report = RepriceReport.build(catalog: [], assist: 0.5)
        XCTAssertTrue(report.verdicts.isEmpty)
        XCTAssertTrue(report.flipped.isEmpty)
        XCTAssertTrue(report.neverFlipping.isEmpty)
        XCTAssertEqual(report.bestCaseTotal, 0)
        XCTAssertEqual(report.allSharedTotal, 0)
        XCTAssertEqual(report.allNativeTotal, 0)
        XCTAssertTrue(report.orderedByFlipPoint.isEmpty)
    }

    func testReportClampsOutOfRangeAssist() {
        XCTAssertEqual(RepriceReport.build(catalog: SampleCatalog.shoppingApp, assist: 4).assist, 1)
        XCTAssertEqual(RepriceReport.build(catalog: SampleCatalog.shoppingApp, assist: -4).assist, 0)
    }

    func testBestCaseNeverExceedsEitherPureStrategy() {
        for assist in stride(from: 0.0, through: 1.0, by: 0.1) {
            let r = RepriceReport.build(catalog: SampleCatalog.shoppingApp, assist: assist)
            XCTAssertLessThanOrEqual(r.bestCaseTotal, r.allSharedTotal + 1e-9)
            XCTAssertLessThanOrEqual(r.bestCaseTotal, r.allNativeTotal + 1e-9)
        }
    }

    func testFlippedCountIsMonotonicAcrossTheAssistRangeForThisCatalog() {
        var previous = -1
        for step in 0...20 {
            let assist = Double(step) / 20
            let count = RepriceReport.build(catalog: SampleCatalog.shoppingApp, assist: assist).flipped.count
            XCTAssertGreaterThanOrEqual(count, previous,
                                        "flip count went backwards at assist \(assist)")
            previous = count
        }
    }

    func testOrderingIsStableAndPutsNeverFlipsLast() {
        let report = RepriceReport.build(catalog: SampleCatalog.shoppingApp, assist: 0.6)
        let ordered = report.orderedByFlipPoint
        XCTAssertEqual(ordered.count, SampleCatalog.shoppingApp.count)

        let neverIndices = ordered.enumerated()
            .filter { $0.element.breakEven == .neverFlips }
            .map(\.offset)
        if let firstNever = neverIndices.first {
            XCTAssertEqual(Array(firstNever..<ordered.count), neverIndices,
                           "never-flipping features must form a suffix of the ordering")
        }
        XCTAssertEqual(ordered.map(\.id), report.orderedByFlipPoint.map(\.id))
    }

    func testEveryCatalogEntryGetsExactlyOneVerdict() {
        let report = RepriceReport.build(catalog: SampleCatalog.shoppingApp, assist: 0.5)
        XCTAssertEqual(Set(report.verdicts.map(\.id)).count, SampleCatalog.shoppingApp.count)
    }

    func testSavingIsNeverNegative() {
        let report = RepriceReport.build(catalog: SampleCatalog.shoppingApp, assist: 0.7)
        for v in report.verdicts {
            XCTAssertGreaterThanOrEqual(v.saving, 0)
        }
    }

    // MARK: - The finding the article quotes

    func testFeatureSizeDoesNotPredictFlipOrder() {
        // If "agents are good at big rote work" were the right intuition, the
        // largest features would flip first. Assert they do not: the largest
        // feature in the catalog must not be the earliest to flip.
        let report = RepriceReport.build(catalog: SampleCatalog.shoppingApp, assist: 1.0)
        let flippers = report.orderedByFlipPoint.filter {
            if case .flipsAt = $0.breakEven { return true }
            if case .alreadyNative = $0.breakEven { return true }
            return false
        }
        guard let earliest = flippers.first else { return XCTFail("expected some features to flip") }
        let largest = SampleCatalog.shoppingApp.max(by: { $0.nativeBuildDays < $1.nativeBuildDays })
        XCTAssertNotEqual(earliest.feature.id, largest?.id,
                          "the largest feature should not be the first to flip")
    }
}
