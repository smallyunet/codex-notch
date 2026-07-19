import Foundation

enum UsageWindowKind: Equatable, Sendable {
    case rolling(hours: Int)
    case daily
    case weekly
    case custom(seconds: Int)
}

struct UsageWindow: Equatable, Identifiable, Sendable {
    let id: String
    let kind: UsageWindowKind
    let usedPercent: Double
    let resetAt: Date?

    init(id: String, kind: UsageWindowKind, usedPercent: Double, resetAt: Date? = nil) {
        self.id = id
        self.kind = kind
        self.usedPercent = UsageWindowClassifier.clampPercent(usedPercent)
        self.resetAt = resetAt
    }

    var remainingPercent: Double {
        max(0, 100 - usedPercent)
    }
}

struct UsageSnapshot: Equatable, Sendable {
    let windows: [UsageWindow]
    let fetchedAt: Date

    init(
        windows: [UsageWindow],
        fetchedAt: Date = .now
    ) {
        self.windows = windows
        self.fetchedAt = fetchedAt
    }

    var weeklyWindow: UsageWindow? {
        windows.first { window in
            if case .weekly = window.kind { return true }
            return false
        }
    }

}

enum WeeklyQuotaLevel: Equatable, Sendable {
    case healthy
    case warning
    case critical
    case unavailable

    init(weeklyWindow: UsageWindow?) {
        guard let weeklyWindow else {
            self = .unavailable
            return
        }
        self.init(remainingPercent: weeklyWindow.remainingPercent)
    }

    init(remainingPercent: Double) {
        guard remainingPercent.isFinite else {
            self = .critical
            return
        }
        if remainingPercent <= 10 {
            self = .critical
        } else if remainingPercent <= 20 {
            self = .warning
        } else {
            self = .healthy
        }
    }
}
