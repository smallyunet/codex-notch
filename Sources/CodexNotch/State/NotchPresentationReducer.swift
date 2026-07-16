import Foundation

enum NotchPresentationReducer {
    static let completionFeedbackDuration: TimeInterval = 2.5

    static func reduce(_ input: NotchPresentationInput) -> NotchPresentationState {
        let sessions = input.activeSessions.sorted { $0.lastActivityAt > $1.lastActivityAt }

        if input.isHovered {
            return .expanded(expandedContent(input: input, sessions: sessions))
        }
        if let primary = sessions.first {
            return .workingCompact(
                primary: primary,
                count: sessions.count,
                usage: input.usage
            )
        }
        if let completion = input.recentCompletions.first {
            let age = input.now.timeIntervalSince(completion.completedAt)
            if age >= 0, age <= completionFeedbackDuration {
                return .completedCompact(completion.session, usage: input.usage)
            }
        }

        return .quotaCompact(input.usage)
    }

    private static func expandedContent(
        input: NotchPresentationInput,
        sessions: [SessionActivity]
    ) -> ExpandedContent {
        var seenThreadIDs = Set<String>()
        var conversations: [ConversationSummary] = []

        for session in sessions where seenThreadIDs.insert(session.threadID).inserted {
            conversations.append(
                ConversationSummary(
                    session: session,
                    activity: .running(startedAt: session.startedAt)
                )
            )
        }
        for completion in input.recentCompletions
            where seenThreadIDs.insert(completion.session.threadID).inserted {
            conversations.append(
                ConversationSummary(
                    session: completion.session,
                    activity: .completed(completedAt: completion.completedAt)
                )
            )
        }

        return ExpandedContent(
            sessions: sessions,
            conversations: Array(conversations.prefix(2)),
            usage: input.usage
        )
    }
}
