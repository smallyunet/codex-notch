import Foundation

enum QuotaDisplayStyle: String, CaseIterable, Identifiable, Sendable {
    case clockwiseRing
    case waveBall

    static let storageKey = "quotaDisplayStyle"
    static let defaultStyle: QuotaDisplayStyle = .clockwiseRing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clockwiseRing:
            return "顺时针圆环"
        case .waveBall:
            return "波浪球"
        }
    }

    var subtitle: String {
        switch self {
        case .clockwiseRing:
            return "缺口从12点顺时针展开"
        case .waveBall:
            return "液面高度加轻微波浪动画"
        }
    }

    var systemImage: String {
        switch self {
        case .clockwiseRing:
            return "arrow.clockwise"
        case .waveBall:
            return "water.waves"
        }
    }

    static func fromStoredValue(_ rawValue: String) -> QuotaDisplayStyle {
        Self(rawValue: rawValue) ?? Self.defaultStyle
    }
}

enum QuotaLabelPlacement: String, CaseIterable, Identifiable, Sendable {
    case inside
    case beside

    static let storageKey = "waveQuotaLabelPlacement"
    static let defaultPlacement: QuotaLabelPlacement = .inside

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inside:
            return "球内数字"
        case .beside:
            return "球旁数字"
        }
    }

    var subtitle: String {
        switch self {
        case .inside:
            return "数字叠在液面上，刘海最紧凑"
        case .beside:
            return "数字放在波浪球右侧，动画完整可见"
        }
    }

    var systemImage: String {
        switch self {
        case .inside:
            return "textformat"
        case .beside:
            return "arrow.right"
        }
    }

    static func fromStoredValue(_ rawValue: String) -> QuotaLabelPlacement {
        Self(rawValue: rawValue) ?? Self.defaultPlacement
    }
}

enum QuotaRingMath {
    static let clockwiseStartAngleDegrees = -90.0

    static func clockwiseTrim(progress: CGFloat) -> (from: CGFloat, to: CGFloat) {
        let clamped = min(max(progress, 0), 1)
        return (1 - clamped, 1)
    }
}
