import AppKit
import Foundation

enum MenuBarButtonStyle {
    static let fontSize: CGFloat = 12

    static func apply(to button: NSButton) {
        let image = NSImage(systemSymbolName: "chart.pie.fill", accessibilityDescription: "Codex quota")
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageLeading
        button.imageHugsTitle = true
        button.alignment = .center
        button.font = .monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
        button.toolTip = "Codex weekly quota"
    }
}

final class MenuBarController: NSObject {
    static let refreshInterval: TimeInterval = 60

    private let statusItem: NSStatusItem
    private let authReader: CodexAuthReader
    private let session: URLSession
    private let updateService: UpdateService
    private var refreshTimer: Timer?
    private var refreshTask: Task<Void, Never>?
    private var updateTask: Task<Void, Never>?
    private var snapshot: UsageSnapshot?
    private var errorState: MenuBarErrorState?
    private var updateState = UpdateState.idle

    init(
        statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength),
        authReader: CodexAuthReader = CodexAuthReader(),
        session: URLSession = SecureUsageSession.make(),
        updateService: UpdateService = UpdateService()
    ) {
        self.statusItem = statusItem
        self.authReader = authReader
        self.session = session
        self.updateService = updateService
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
        updateTask?.cancel()
        updateTask = nil
        session.invalidateAndCancel()
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else { return }
        MenuBarButtonStyle.apply(to: button)
        button.title = MenuBarText.statusTitle(snapshot: nil)
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
        let progressItem = NSMenuItem()
        progressItem.view = QuotaProgressMenuView(
            presentation: QuotaProgressPresentation(
                snapshot: snapshot,
                error: errorState,
                now: .now
            )
        )
        menu.addItem(progressItem)

        menu.addItem(.separator())
        menu.addItem(actionItem(title: "Refresh Now", action: #selector(refreshNow), keyEquivalent: "r"))
        menu.addItem(actionItem(title: "Open ChatGPT", action: #selector(openChatGPT), keyEquivalent: "o"))
        menu.addItem(.separator())
        let versionItem = NSMenuItem(title: "Version \(AppIdentity.version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
        addUpdateItems(to: menu)
        menu.addItem(.separator())
        menu.addItem(actionItem(title: "Quit CodexNotch", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func addUpdateItems(to menu: NSMenu) {
        switch updateState {
        case .idle:
            menu.addItem(actionItem(title: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: ""))
        case .checking:
            let item = NSMenuItem(title: "Checking for Updates…", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        case .upToDate:
            let item = NSMenuItem(title: "You’re Up to Date", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(actionItem(title: "Check Again", action: #selector(checkForUpdates), keyEquivalent: ""))
        case let .available(release):
            menu.addItem(actionItem(title: "View \(release.tagName) Release…", action: #selector(openAvailableRelease), keyEquivalent: ""))
        case .failed:
            let item = NSMenuItem(title: "Couldn’t Check for Updates", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(actionItem(title: "Try Again", action: #selector(checkForUpdates), keyEquivalent: ""))
        }
    }

    @objc private func checkForUpdates() {
        updateTask?.cancel()
        updateState = .checking
        rebuildMenu()
        let service = updateService
        updateTask = Task { [weak self] in
            do {
                let release = try await service.latestRelease()
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.updateState = UpdateService.isNewer(release.tagName, than: AppIdentity.version)
                        ? .available(release)
                        : .upToDate
                    self?.rebuildMenu()
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.updateState = .failed
                    self?.rebuildMenu()
                }
            }
        }
    }

    @objc private func openAvailableRelease() {
        guard case let .available(release) = updateState else { return }
        NSWorkspace.shared.open(release.htmlURL)
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

enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate
    case available(GitHubRelease)
    case failed
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

struct QuotaProgressPresentation: Equatable {
    let quotaValue: String
    let quotaProgress: Double?
    let resetValue: String
    let resetDetail: String?
    let resetProgress: Double?
    let resetCreditsValue: String?

    init(snapshot: UsageSnapshot?, error: MenuBarErrorState?, now: Date) {
        resetCreditsValue = snapshot?.availableResetCredits.map { "\($0) available" }
        guard let weekly = snapshot?.weeklyWindow else {
            switch error {
            case .signInRequired:
                quotaValue = "Sign in required"
            case .quotaUnavailable:
                quotaValue = "Unavailable"
            case nil:
                quotaValue = "Loading…"
            }
            quotaProgress = nil
            resetValue = "—"
            resetDetail = nil
            resetProgress = nil
            return
        }

        quotaValue = "\(Int(weekly.remainingPercent.rounded()))%"
        quotaProgress = Self.clamp(weekly.remainingPercent / 100)

        guard let resetAt = weekly.resetAt,
              let duration = weekly.durationSeconds,
              duration.isFinite,
              duration > 0 else {
            resetValue = "Unavailable"
            resetDetail = MenuBarText.resetLine(snapshot: snapshot)
            resetProgress = nil
            return
        }

        let remaining = max(0, resetAt.timeIntervalSince(now))
        resetValue = Self.durationText(remaining)
        resetDetail = MenuBarText.resetLine(snapshot: snapshot)
        resetProgress = Self.clamp(remaining / duration)
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(1, max(0, value))
    }

    private static func durationText(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval / 60))
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60

        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

final class QuotaProgressMenuView: NSView {
    static let width: CGFloat = 260
    static let height: CGFloat = 116
    static let heightWithResetCredits: CGFloat = 124

    init(presentation: QuotaProgressPresentation) {
        let viewHeight = presentation.resetCreditsValue == nil ? Self.height : Self.heightWithResetCredits
        super.init(frame: NSRect(x: 0, y: 0, width: Self.width, height: viewHeight))
        translatesAutoresizingMaskIntoConstraints = false

        let quotaRow = Self.labelRow(title: "Weekly remaining", value: presentation.quotaValue)
        let quotaBar = Self.progressBar(
            value: presentation.quotaProgress,
            accessibilityLabel: "Weekly quota remaining"
        )
        let resetRow = Self.labelRow(title: "Until weekly reset", value: presentation.resetValue)
        let resetBar = Self.progressBar(
            value: presentation.resetProgress,
            accessibilityLabel: "Time remaining until weekly reset"
        )

        let stack = NSStackView(views: [quotaRow, quotaBar, resetRow, resetBar])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        for view in [quotaRow, quotaBar, resetRow, resetBar] {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }

        if let detail = presentation.resetDetail {
            let detailLabel = NSTextField(labelWithString: detail)
            detailLabel.font = .systemFont(ofSize: 11)
            detailLabel.textColor = .secondaryLabelColor
            detailLabel.lineBreakMode = .byTruncatingTail
            detailLabel.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(detailLabel)
            detailLabel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        if let creditsValue = presentation.resetCreditsValue {
            let creditsRow = Self.labelRow(title: "Reset credits", value: creditsValue)
            stack.addArrangedSubview(creditsRow)
            creditsRow.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.width),
            heightAnchor.constraint(equalToConstant: viewHeight),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func labelRow(title: String, value: String) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .labelColor

        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.alignment = .right
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = NSStackView(views: [titleLabel, valueLabel])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .fill
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }

    private static func progressBar(value: Double?, accessibilityLabel: String) -> NSProgressIndicator {
        let progress = NSProgressIndicator()
        progress.style = .bar
        progress.controlSize = .small
        progress.isIndeterminate = false
        progress.minValue = 0
        progress.maxValue = 1
        progress.doubleValue = value ?? 0
        progress.toolTip = accessibilityLabel
        progress.setAccessibilityLabel(accessibilityLabel)
        progress.setAccessibilityValue(value.map { "\(Int(($0 * 100).rounded())) percent" } ?? "Unavailable")
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.heightAnchor.constraint(equalToConstant: 6).isActive = true
        return progress
    }
}
