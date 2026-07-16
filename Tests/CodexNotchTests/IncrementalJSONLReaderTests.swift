import Foundation
import XCTest
@testable import CodexNotch

final class IncrementalJSONLReaderTests: XCTestCase {
    func testSecondReadOnlyReturnsAppendedLines() throws {
        let url = try temporaryFile(contents: Data("first\n".utf8))
        defer { try? FileManager.default.removeItem(at: url) }
        var cursor = FileCursor()
        let reader = IncrementalJSONLReader()

        XCTAssertEqual(try reader.readNewLines(at: url, cursor: &cursor).count, 1)
        try append(Data("second\n".utf8), to: url)
        XCTAssertEqual(String(data: try reader.readNewLines(at: url, cursor: &cursor).first!, encoding: .utf8), "second")
    }

    func testIncompleteLineIsHeldUntilNewlineArrives() throws {
        let url = try temporaryFile(contents: Data("partial".utf8))
        defer { try? FileManager.default.removeItem(at: url) }
        var cursor = FileCursor()
        let reader = IncrementalJSONLReader()

        XCTAssertTrue(try reader.readNewLines(at: url, cursor: &cursor).isEmpty)
        try append(Data("\n".utf8), to: url)
        XCTAssertEqual(String(data: try reader.readNewLines(at: url, cursor: &cursor).first!, encoding: .utf8), "partial")
    }

    func testTruncatedFileResetsCursorAndReadsFromBeginning() throws {
        let url = try temporaryFile(contents: Data("long-content\n".utf8))
        defer { try? FileManager.default.removeItem(at: url) }
        var cursor = FileCursor()
        let reader = IncrementalJSONLReader()

        _ = try reader.readNewLines(at: url, cursor: &cursor)
        try Data("new\n".utf8).write(to: url, options: .atomic)

        let lines = try reader.readNewLines(at: url, cursor: &cursor)
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(String(data: lines[0], encoding: .utf8), "new")
    }

    private func temporaryFile(contents: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("codex-notch-\(UUID().uuidString).jsonl")
        try contents.write(to: url)
        return url
    }

    private func append(_ data: Data, to url: URL) throws {
        var existing = try Data(contentsOf: url)
        existing.append(data)
        try existing.write(to: url, options: .atomic)
    }
}
