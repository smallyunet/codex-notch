import XCTest
@testable import CodexNotch

final class SmokeTests: XCTestCase {
    func testApplicationIdentifierIsStable() {
        XCTAssertEqual(AppIdentity.bundleIdentifier, "com.david.codexnotch")
    }
}
