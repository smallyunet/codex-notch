import Foundation

actor ActiveSessionStore {
    private struct RolloutState {
        let active: [SessionActivity]
        let lastModifiedAt: Date
    }

    private let staleAfter: TimeInterval
    private var rollouts: [String: RolloutState] = [:]

    init(staleAfter: TimeInterval = 6 * 60 * 60) {
        self.staleAfter = staleAfter
    }

    func replace(
        rolloutID: String,
        reduction: ActiveSessionReduction,
        lastModifiedAt: Date
    ) {
        rollouts[rolloutID] = RolloutState(
            active: reduction.active,
            lastModifiedAt: lastModifiedAt
        )
    }

    func activeSessions(now: Date = .now) -> [SessionActivity] {
        let cutoff = now.addingTimeInterval(-staleAfter)
        rollouts = rollouts.filter { $0.value.lastModifiedAt >= cutoff }

        return rollouts.values
            .flatMap(\.active)
            .sorted { $0.lastActivityAt > $1.lastActivityAt }
    }

    func remove(rolloutID: String) {
        rollouts.removeValue(forKey: rolloutID)
    }
}
