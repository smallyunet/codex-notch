import Foundation

enum CodexUsageError: Error, Equatable {
    case reauthenticationRequired
    case invalidHTTPResponse
    case httpStatus(Int)
    case decodingFailed
}

struct CodexUsageClient {
    static let defaultEndpoint = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    let credentials: CodexCredentials
    let session: URLSession
    let endpoint: URL

    init(credentials: CodexCredentials,
         session: URLSession = .shared,
         endpoint: URL = CodexUsageClient.defaultEndpoint) {
        self.credentials = credentials
        self.session = session
        self.endpoint = endpoint
    }

    func fetch() async throws -> UsageSnapshot {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
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

        do {
            return try JSONDecoder().decode(UsageResponseDTO.self, from: data).snapshot()
        } catch {
            throw CodexUsageError.decodingFailed
        }
    }
}
