import AppKit
import Foundation
import XCTest
@testable import CodexNotch

final class MenuBarTextTests: XCTestCase {
    func testStatusButtonUsesCompactNativeImageAndTitleLayout() {
        let button = NSButton(frame: .zero)

        MenuBarButtonStyle.apply(to: button)

        XCTAssertTrue(button.imageHugsTitle)
        XCTAssertEqual(button.imagePosition, .imageLeading)
        XCTAssertEqual(button.alignment, .center)
        XCTAssertEqual(button.font?.pointSize, MenuBarButtonStyle.fontSize)
    }

    func testStatusTitleShowsRoundedWeeklyRemainingPercent() {
        let snapshot = UsageSnapshot(
            windows: [UsageWindow(id: "weekly", kind: .weekly, usedPercent: 31.6)]
        )

        XCTAssertEqual(MenuBarText.statusTitle(snapshot: snapshot), "68%")
        XCTAssertEqual(MenuBarText.summary(snapshot: snapshot, error: nil), "Weekly remaining: 68%")
    }

    func testUnavailableStatesNeverExposeErrorDetails() {
        XCTAssertEqual(MenuBarText.statusTitle(snapshot: nil), "—")
        XCTAssertEqual(
            MenuBarText.summary(snapshot: nil, error: .signInRequired),
            "Sign in to ChatGPT to load quota"
        )
        XCTAssertEqual(
            MenuBarText.summary(snapshot: nil, error: .quotaUnavailable),
            "Quota unavailable"
        )
    }

    func testResetLineUsesStableEnglishFormatting() {
        let snapshot = UsageSnapshot(
            windows: [
                UsageWindow(
                    id: "weekly",
                    kind: .weekly,
                    usedPercent: 10,
                    resetAt: Date(timeIntervalSince1970: 1_768_415_045)
                )
            ]
        )

        XCTAssertTrue(MenuBarText.resetLine(snapshot: snapshot)?.hasPrefix("Resets: ") == true)
    }
}
