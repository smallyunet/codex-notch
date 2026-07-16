import Foundation
import XCTest
@testable import CodexNotch

final class CodexAuthReaderTests: XCTestCase {
    func testEnvironmentDirectoryOverridesHomeDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let fixture = try Data(contentsOf: fixtureURL("auth-valid.json"))
        try fixture.write(to: root.appendingPathComponent("auth.json"))

        let reader = CodexAuthReader(
            environment: ["CODEX_HOME": root.path],
            homeDirectory: URL(fileURLWithPath: "/definitely/not/the-test-home")
        )

        let credentials = try reader.read()
        XCTAssertEqual(credentials.accessToken, "fixture-access-token")
        XCTAssertEqual(credentials.accountID, "acct_fixture")
    }

    private func fixtureURL(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent(name)
    }
}
