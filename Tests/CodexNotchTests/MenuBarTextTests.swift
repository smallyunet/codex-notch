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

    func testProgressPresentationUsesRemainingQuotaAndExactWindowDuration() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let snapshot = UsageSnapshot(
            windows: [
                UsageWindow(
                    id: "weekly",
                    kind: .weekly,
                    usedPercent: 19,
                    resetAt: now.addingTimeInterval(2 * 24 * 60 * 60),
                    durationSeconds: 7 * 24 * 60 * 60
                )
            ]
        )

        let presentation = QuotaProgressPresentation(snapshot: snapshot, error: nil, now: now)

        XCTAssertEqual(presentation.quotaValue, "81%")
        XCTAssertEqual(try XCTUnwrap(presentation.quotaProgress), 0.81, accuracy: 0.0001)
        XCTAssertEqual(presentation.resetValue, "2d 0h")
        XCTAssertEqual(try XCTUnwrap(presentation.resetProgress), 2.0 / 7.0, accuracy: 0.0001)
        XCTAssertNotNil(presentation.resetDetail)
    }

    func testResetProgressIsClampedAndUnavailableDataIsNotFabricated() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let expired = UsageSnapshot(
            windows: [
                UsageWindow(
                    id: "weekly",
                    kind: .weekly,
                    usedPercent: 50,
                    resetAt: now.addingTimeInterval(-60),
                    durationSeconds: 604_800
                )
            ]
        )
        let missingDuration = UsageSnapshot(
            windows: [
                UsageWindow(
                    id: "weekly",
                    kind: .weekly,
                    usedPercent: 50,
                    resetAt: now.addingTimeInterval(60)
                )
            ]
        )

        XCTAssertEqual(
            QuotaProgressPresentation(snapshot: expired, error: nil, now: now).resetProgress,
            0
        )
        let unavailable = QuotaProgressPresentation(snapshot: missingDuration, error: nil, now: now)
        XCTAssertNil(unavailable.resetProgress)
        XCTAssertEqual(unavailable.resetValue, "Unavailable")
    }

    func testProgressMenuViewContainsTwoNativeProgressIndicators() {
        let presentation = QuotaProgressPresentation(snapshot: nil, error: nil, now: .now)
        let view = QuotaProgressMenuView(presentation: presentation)

        XCTAssertEqual(progressIndicators(in: view).count, 2)
        XCTAssertEqual(view.frame.size.width, QuotaProgressMenuView.width)
        XCTAssertEqual(view.frame.size.height, QuotaProgressMenuView.height)
    }

    private func progressIndicators(in view: NSView) -> [NSProgressIndicator] {
        view.subviews.flatMap { child in
            (child as? NSProgressIndicator).map { [$0] } ?? progressIndicators(in: child)
        }
    }
}
