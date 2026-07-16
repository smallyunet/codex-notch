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
}
