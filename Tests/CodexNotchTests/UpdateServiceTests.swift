import Foundation
import XCTest
@testable import CodexNotch

final class UpdateServiceTests: XCTestCase {
    override func tearDown() {
        UpdateMockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testLatestReleaseUsesBoundedUnauthenticatedGitHubRequest() async throws {
        UpdateMockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, UpdateService.defaultEndpoint)
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            let data = Data(#"{"tag_name":"v0.5.0","html_url":"https://github.com/smallyunet/codex-notch/releases/tag/v0.5.0"}"#.utf8)
            return (self.response(status: 200), data)
        }

        let release = try await makeService().latestRelease()

        XCTAssertEqual(release.tagName, "v0.5.0")
    }

    func testRejectsNonGitHubEndpointBeforeSending() async throws {
        UpdateMockURLProtocol.requestHandler = { _ in
            XCTFail("An unapproved host must not receive a request")
            return (self.response(status: 500), Data())
        }
        let service = UpdateService(
            session: testSession(),
            endpoint: URL(string: "https://example.test/releases/latest")!
        )

        do {
            _ = try await service.latestRelease()
            XCTFail("Expected invalid endpoint")
        } catch let error as UpdateError {
            XCTAssertEqual(error, .invalidEndpoint)
        }
    }

    func testRejectsReleaseLinkOutsideRepository() async throws {
        UpdateMockURLProtocol.requestHandler = { _ in
            let data = Data(#"{"tag_name":"v9.0.0","html_url":"https://example.com/download"}"#.utf8)
            return (self.response(status: 200), data)
        }

        do {
            _ = try await makeService().latestRelease()
            XCTFail("Expected invalid release")
        } catch let error as UpdateError {
            XCTAssertEqual(error, .invalidRelease)
        }
    }

    func testSemanticVersionComparison() {
        XCTAssertTrue(UpdateService.isNewer("v0.5.0", than: "0.4.0"))
        XCTAssertTrue(UpdateService.isNewer("v1.0.0", than: "0.12.9"))
        XCTAssertFalse(UpdateService.isNewer("v0.4.0", than: "0.4.0"))
        XCTAssertFalse(UpdateService.isNewer("v0.3.9", than: "0.4.0"))
        XCTAssertFalse(UpdateService.isNewer("latest", than: "0.4.0"))
    }

    private func makeService() -> UpdateService {
        UpdateService(session: testSession())
    }

    private func testSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UpdateMockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func response(status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: UpdateService.defaultEndpoint,
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }
}

private final class UpdateMockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            guard let handler = Self.requestHandler else { throw URLError(.badServerResponse) }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
