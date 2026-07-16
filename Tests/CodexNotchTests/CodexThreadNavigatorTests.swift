import XCTest
@testable import CodexNotch

final class CodexThreadNavigatorTests: XCTestCase {
    func testThreadURLUsesCodexScheme() throws {
        let url = try CodexThreadNavigator.threadURL(id: "019f-test")
        XCTAssertEqual(url.absoluteString, "codex://threads/019f-test")
    }

    func testInvalidThreadIDReturnsNil() {
        XCTAssertNil(CodexThreadNavigator.threadURLIfValid(id: ""))
        XCTAssertNil(CodexThreadNavigator.threadURLIfValid(id: "thread with spaces"))
    }

    func testOnlyCurrentChatGPTCodexBundleIsRecognized() {
        XCTAssertTrue(FrontmostAppMonitor.isChatGPTCodex(bundleIdentifier: "com.openai.codex"))
        XCTAssertFalse(FrontmostAppMonitor.isChatGPTCodex(bundleIdentifier: "com.openai.chatgpt.classic"))
        XCTAssertFalse(FrontmostAppMonitor.isChatGPTCodex(bundleIdentifier: nil))
    }
}
