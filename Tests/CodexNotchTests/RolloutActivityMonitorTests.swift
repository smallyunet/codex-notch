import Foundation
import XCTest
@testable import CodexNotch

final class RolloutActivityMonitorTests: XCTestCase {
    func testMonitorPublishesActiveSessionWithParsedTimestamp() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("codex-notch-monitor-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("rollout-active.jsonl")
        let rolloutURL = rootURL.appendingPathComponent("live.jsonl")
        try FileManager.default.copyItem(at: fixtureURL, to: rolloutURL)

        let store = ActiveSessionStore()
        let monitor = RolloutActivityMonitor(rootURL: rootURL, store: store)
        monitor.start()
        defer { monitor.stop() }

        var snapshot = await store.snapshot()
        for _ in 0..<20 where snapshot.activeSessions.isEmpty {
            try await Task.sleep(nanoseconds: 50_000_000)
            snapshot = await store.snapshot()
        }

        XCTAssertEqual(snapshot.activeSessions.count, 1)
        XCTAssertEqual(snapshot.activeSessions.first?.threadID, "thread-live")
        XCTAssertEqual(snapshot.activeSessions.first?.cwd, "/tmp/codex-notch-live")
        XCTAssertEqual(
            snapshot.activeSessions.first?.startedAt,
            Date(timeIntervalSince1970: 1_784_192_401)
        )
    }

    func testRescanPicksUpSessionsDirectoryCreatedAfterStart() async throws {
        let codexHome = FileManager.default.temporaryDirectory
            .appendingPathComponent("codex-notch-late-\(UUID().uuidString)", isDirectory: true)
        let sessionsURL = codexHome.appendingPathComponent("sessions", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: codexHome)
        }

        let store = ActiveSessionStore()
        let monitor = RolloutActivityMonitor(rootURL: sessionsURL, store: store)
        monitor.start()
        defer { monitor.stop() }

        try FileManager.default.createDirectory(at: sessionsURL, withIntermediateDirectories: true)
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("rollout-active.jsonl")
        try FileManager.default.copyItem(
            at: fixtureURL,
            to: sessionsURL.appendingPathComponent("live.jsonl")
        )
        monitor.rescan()

        var snapshot = await store.snapshot()
        for _ in 0..<20 where snapshot.activeSessions.isEmpty {
            try await Task.sleep(nanoseconds: 50_000_000)
            snapshot = await store.snapshot()
        }

        XCTAssertEqual(snapshot.activeSessions.first?.threadID, "thread-live")
    }
}
