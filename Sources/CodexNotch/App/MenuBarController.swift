import AppKit
import Foundation

final class MenuBarController: NSObject {
    static let refreshInterval: TimeInterval = 60

    private let statusItem: NSStatusItem
    private let authReader: CodexAuthReader
    private let session: URLSession
    private var refreshTimer: Timer?
    private var refreshTask: Task<Void, Never>?
    private var snapshot: UsageSnapshot?
    private var errorState: MenuBarErrorState?

    init(
        statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength),
        authReader: CodexAuthReader = CodexAuthReader(),
        session: URLSession = SecureUsageSession.make()
    ) {
        self.statusItem = statusItem
        self.authReader = authReader
        self.session = session
        super.init()
    }

    func start() {
        configureStatusButton()
        rebuildMenu()
        refresh()
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: Self.refreshInterval,
            repeats: true
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        refreshTask?.cancel()
        refreshTask = nil
        session.invalidateAndCancel()
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: "chart.pie.fill", accessibilityDescription: "Codex quota")
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageLeading
        button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        button.title = MenuBarText.statusTitle(snapshot: nil)
        button.toolTip = "Codex weekly quota"
    }

    @objc private func refreshNow() {
        refresh()
    }

    private func refresh() {
        refreshTask?.cancel()
        let reader = authReader
        let session = self.session
        refreshTask = Task { [weak self] in
            do {
                let credentials = try reader.read()
                let value = try await CodexUsageClient(
                    credentials: credentials,
                    session: session
                ).fetch()
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.apply(snapshot: value)
                }
            } catch let error as CodexAuthError {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.apply(error: error == .authFileUnavailable ? .signInRequired : .quotaUnavailable)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.apply(error: .quotaUnavailable)
                }
            }
        }
    }

    private func apply(snapshot: UsageSnapshot) {
        self.snapshot = snapshot
        errorState = nil
        statusItem.button?.title = MenuBarText.statusTitle(snapshot: snapshot)
        rebuildMenu()
    }

    private func apply(error: MenuBarErrorState) {
        errorState = error
        if snapshot == nil {
            statusItem.button?.title = MenuBarText.statusTitle(snapshot: nil)
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let summary = NSMenuItem(
            title: MenuBarText.summary(snapshot: snapshot, error: errorState),
            action: nil,
            keyEquivalent: ""
        )
        summary.isEnabled = false
        menu.addItem(summary)

        if let resetLine = MenuBarText.resetLine(snapshot: snapshot) {
            let resetItem = NSMenuItem(title: resetLine, action: nil, keyEquivalent: "")
            resetItem.isEnabled = false
            menu.addItem(resetItem)
        }

        menu.addItem(.separator())
        menu.addItem(actionItem(title: "Refresh Now", action: #selector(refreshNow), keyEquivalent: "r"))
        menu.addItem(actionItem(title: "Open ChatGPT", action: #selector(openChatGPT), keyEquivalent: "o"))
        menu.addItem(.separator())
        menu.addItem(actionItem(title: "Quit CodexNotch", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func actionItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    @objc private func openChatGPT() {
        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: AppIdentity.chatGPTCodexBundleIdentifier
        ) else { return }
        NSWorkspace.shared.open(appURL)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

enum MenuBarErrorState: Equatable {
    case signInRequired
    case quotaUnavailable
}

enum MenuBarText {
    static func statusTitle(snapshot: UsageSnapshot?) -> String {
        guard let remaining = snapshot?.weeklyWindow?.remainingPercent else { return "—" }
        return "\(Int(remaining.rounded()))%"
    }

    static func summary(snapshot: UsageSnapshot?, error: MenuBarErrorState?) -> String {
        if let weekly = snapshot?.weeklyWindow {
            return "Weekly remaining: \(Int(weekly.remainingPercent.rounded()))%"
        }
        switch error {
        case .signInRequired:
            return "Sign in to ChatGPT to load quota"
        case .quotaUnavailable:
            return "Quota unavailable"
        case nil:
            return "Loading quota…"
        }
    }

    static func resetLine(snapshot: UsageSnapshot?) -> String? {
        guard let resetAt = snapshot?.weeklyWindow?.resetAt else { return nil }
        return "Resets: \(resetFormatter.string(from: resetAt))"
    }

    private static let resetFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "MMM d, yyyy 'at' HH:mm"
        return formatter
    }()
}
