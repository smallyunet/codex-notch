import AppKit
import Foundation

final class FrontmostAppMonitor {
    private let workspace: NSWorkspace
    private var observer: NSObjectProtocol?

    var onChange: ((Bool) -> Void)?

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    static func isChatGPTCodex(bundleIdentifier: String?) -> Bool {
        bundleIdentifier == AppIdentity.chatGPTCodexBundleIdentifier
    }

    func start() {
        stop()
        emit(bundleIdentifier: workspace.frontmostApplication?.bundleIdentifier)
        observer = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication
            self?.emit(bundleIdentifier: application?.bundleIdentifier)
        }
    }

    func stop() {
        if let observer {
            workspace.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
    }

    deinit {
        stop()
    }

    private func emit(bundleIdentifier: String?) {
        onChange?(Self.isChatGPTCodex(bundleIdentifier: bundleIdentifier))
    }
}
