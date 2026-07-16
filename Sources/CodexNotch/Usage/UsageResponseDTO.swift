import Foundation

struct UsageResponseDTO: Decodable {
    let primaryWindow: WindowDTO?
    let secondaryWindow: WindowDTO?
    let rateLimitResetCredits: ResetCreditsDTO?

    enum CodingKeys: String, CodingKey {
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
        case rateLimitResetCredits = "rate_limit_reset_credits"
    }

    func snapshot(fetchedAt: Date = .now) -> UsageSnapshot {
        let windows = [
            makeWindow(id: "primary", dto: primaryWindow),
            makeWindow(id: "secondary", dto: secondaryWindow)
        ].compactMap { $0 }

        return UsageSnapshot(
            windows: windows,
            resetCreditsAvailable: rateLimitResetCredits?.availableCount,
            fetchedAt: fetchedAt
        )
    }

    private func makeWindow(id: String, dto: WindowDTO?) -> UsageWindow? {
        guard let dto,
              let usedPercent = dto.usedPercent,
              let seconds = dto.limitWindowSeconds else {
            return nil
        }

        return UsageWindow(
            id: id,
            kind: UsageWindowClassifier.kind(seconds: seconds),
            usedPercent: usedPercent,
            resetAt: dto.resetAt
        )
    }
}

struct WindowDTO: Decodable {
    let usedPercent: Double?
    let limitWindowSeconds: Int?
    let resetAt: Date?

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
        case resetAt = "reset_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        usedPercent = try container.decodeIfPresent(Double.self, forKey: .usedPercent)
        limitWindowSeconds = try container.decodeIfPresent(Int.self, forKey: .limitWindowSeconds)

        if let epoch = try? container.decode(Double.self, forKey: .resetAt) {
            let seconds = epoch > 1_000_000_000_000 ? epoch / 1_000 : epoch
            resetAt = Date(timeIntervalSince1970: seconds)
        } else if let text = try? container.decode(String.self, forKey: .resetAt) {
            resetAt = ISO8601DateFormatter().date(from: text)
        } else {
            resetAt = nil
        }
    }
}

struct ResetCreditsDTO: Decodable {
    let availableCount: Int?

    enum CodingKeys: String, CodingKey {
        case availableCount = "available_count"
    }
}
