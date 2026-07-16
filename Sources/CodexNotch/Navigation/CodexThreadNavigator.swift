import AppKit
import Foundation

enum CodexThreadNavigationError: Error, Equatable {
    case invalidThreadID
}

struct CodexThreadNavigator {
    private let workspace: NSWorkspace

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    static func threadURL(id: String) throws -> URL {
        guard !id.isEmpty,
              id.unicodeScalars.allSatisfy({ scalar in
                  CharacterSet.alphanumerics.contains(scalar)
                      || scalar == "-"
                      || scalar == "_"
                      || scalar == "."
              }) else {
            throw CodexThreadNavigationError.invalidThreadID
        }

        var components = URLComponents()
        components.scheme = "codex"
        components.host = "threads"
        components.path = "/\(id)"
        guard let url = components.url else {
            throw CodexThreadNavigationError.invalidThreadID
        }
        return url
    }

    static func threadURLIfValid(id: String) -> URL? {
        try? threadURL(id: id)
    }

    @discardableResult
    func open(threadID: String) -> Bool {
        guard let url = Self.threadURLIfValid(id: threadID) else {
            return activateCodex()
        }
        return workspace.open(url) || activateCodex()
    }

    @discardableResult
    func activateCodex() -> Bool {
        guard let appURL = workspace.urlForApplication(
            withBundleIdentifier: AppIdentity.chatGPTCodexBundleIdentifier
        ) else {
            return false
        }
        return workspace.open(appURL)
    }
}
