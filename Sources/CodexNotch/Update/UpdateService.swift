import Foundation

struct GitHubRelease: Decodable, Equatable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

enum UpdateError: Error, Equatable {
    case invalidEndpoint
    case invalidHTTPResponse
    case httpStatus(Int)
    case invalidRelease
}

struct UpdateService {
    static let defaultEndpoint = URL(
        string: "https://api.github.com/repos/smallyunet/codex-notch/releases/latest"
    )!

    let session: URLSession
    let endpoint: URL

    init(
        session: URLSession = SecureUsageSession.make(),
        endpoint: URL = Self.defaultEndpoint
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    func latestRelease() async throws -> GitHubRelease {
        guard endpoint == Self.defaultEndpoint else {
            throw UpdateError.invalidEndpoint
        }

        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 15
        )
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("CodexNotch/\(AppIdentity.version)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidHTTPResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw UpdateError.httpStatus(httpResponse.statusCode)
        }

        guard let release = try? JSONDecoder().decode(GitHubRelease.self, from: data),
              release.htmlURL.scheme == "https",
              release.htmlURL.host == AppIdentity.repositoryURL.host,
              release.htmlURL.path.hasPrefix("/smallyunet/codex-notch/releases/") else {
            throw UpdateError.invalidRelease
        }
        return release
    }

    static func isNewer(_ tag: String, than current: String) -> Bool {
        guard let candidate = versionComponents(tag),
              let installed = versionComponents(current) else { return false }
        return candidate.lexicographicallyPrecedes(installed) == false && candidate != installed
    }

    private static func versionComponents(_ value: String) -> [Int]? {
        let normalized = value.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let parts = normalized.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        return parts.map(String.init).compactMap(Int.init).count == 3
            ? parts.compactMap { Int($0) }
            : nil
    }
}
