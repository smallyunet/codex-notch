import Foundation
import XCTest
@testable import CodexNotch

final class QuotaDisplayStyleTests: XCTestCase {
    func testOnlyRingAndWaveStylesAreAvailable() {
        XCTAssertEqual(
            QuotaDisplayStyle.allCases,
            [.clockwiseRing, .waveBall]
        )
    }

    func testStoredValueFallsBackToClockwiseRing() {
        XCTAssertEqual(
            QuotaDisplayStyle.fromStoredValue("unknown"),
            .clockwiseRing
        )
    }

    func testStyleMetadataIsUserFacing() {
        XCTAssertEqual(QuotaDisplayStyle.clockwiseRing.title, "顺时针圆环")
        XCTAssertEqual(QuotaDisplayStyle.waveBall.title, "波浪球")
        XCTAssertFalse(QuotaDisplayStyle.waveBall.subtitle.isEmpty)
    }

    func testClockwiseRingGapExpandsFromTwelveOClockAnchor() {
        let trim = QuotaRingMath.clockwiseTrim(progress: 0.43)
        XCTAssertEqual(trim.from, 0.57, accuracy: 0.0001)
        XCTAssertEqual(trim.to, 1, accuracy: 0.0001)
        XCTAssertEqual(QuotaRingMath.clockwiseStartAngleDegrees, -90)
    }

    func testQuotaLabelPlacementHasInsideAndBesideChoices() {
        XCTAssertEqual(
            QuotaLabelPlacement.allCases,
            [.inside, .beside]
        )
    }

    func testStoredQuotaLabelPlacementFallsBackToInside() {
        XCTAssertEqual(
            QuotaLabelPlacement.fromStoredValue("unknown"),
            .inside
        )
    }

    func testQuotaLabelPlacementMetadataIsUserFacing() {
        XCTAssertEqual(QuotaLabelPlacement.inside.title, "指标内数字")
        XCTAssertEqual(QuotaLabelPlacement.beside.title, "指标旁数字")
        XCTAssertFalse(QuotaLabelPlacement.beside.subtitle.isEmpty)
    }

    func testLegacyWavePlacementMigratesToGenericSetting() throws {
        let suiteName = "QuotaDisplayStyleTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw XCTSkip("Unable to create isolated defaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(
            QuotaLabelPlacement.beside.rawValue,
            forKey: QuotaLabelPlacement.legacyStorageKey
        )

        QuotaLabelPlacement.migrateLegacyValue(in: defaults)

        XCTAssertEqual(
            defaults.string(forKey: QuotaLabelPlacement.storageKey),
            QuotaLabelPlacement.beside.rawValue
        )
    }
}
