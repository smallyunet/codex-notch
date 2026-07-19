import Foundation

enum CodexUsageError: Error, Equatable {
    case reauthenticationRequired
    case invalidHTTPResponse
    case httpStatus(Int)
    case decodingFailed
}

enum SecureUsageSession {
    static func make() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        return URLSession(
            configuration: configuration,
            delegate: SameHostHTTPSRedirectDelegate(),
            delegateQueue: nil
        )
    }
}

private final class SameHostHTTPSRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard request.url?.scheme == "https",
              request.url?.host == task.originalRequest?.url?.host else {
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }
}

struct CodexUsageClient {
    static let defaultEndpoint = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    let credentials: CodexCredentials
    let session: URLSession
    let endpoint: URL

    init(credentials: CodexCredentials,
         session: URLSession = SecureUsageSession.make(),
         endpoint: URL = CodexUsageClient.defaultEndpoint) {
        self.credentials = credentials
        self.session = session
        self.endpoint = endpoint
    }

    func fetch() async throws -> UsageSnapshot {
        let data = try await fetchData(from: endpoint)
        do {
            return try JSONDecoder().decode(UsageResponseDTO.self, from: data).snapshot()
        } catch {
            throw CodexUsageError.decodingFailed
        }
    }

    private func fetchData(from endpoint: URL) async throws -> Data {
        guard endpoint.scheme == "https" else {
            throw CodexUsageError.invalidHTTPResponse
        }
        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 15
        )
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        if let accountID = credentials.accountID, !accountID.isEmpty {
            request.setValue(accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CodexUsageError.invalidHTTPResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw CodexUsageError.reauthenticationRequired
            }
            throw CodexUsageError.httpStatus(httpResponse.statusCode)
        }

        return data
    }
}
