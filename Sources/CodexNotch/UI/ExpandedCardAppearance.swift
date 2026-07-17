import Foundation

enum NotchSurfaceMaterial: Equatable, Sendable {
    case clear
    case black
    case glass
}

enum ExpandedCardAppearance: String, CaseIterable, Identifiable, Sendable {
    case glass
    case black

    static let storageKey = "expandedCardAppearance"
    static let defaultStyle = ExpandedCardAppearance.glass

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glass:
            return "玻璃"
        case .black:
            return "黑色"
        }
    }

    var systemImage: String {
        switch self {
        case .glass:
            return "circle.lefthalf.filled"
        case .black:
            return "circle.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .glass:
            return "使用系统玻璃材质；旧版 macOS 自动使用原生半透明材质。"
        case .black:
            return "使用纯黑卡片，保持更强的文字对比度。"
        }
    }

    static func fromStoredValue(_ rawValue: String) -> ExpandedCardAppearance {
        ExpandedCardAppearance(rawValue: rawValue) ?? defaultStyle
    }

    func surfaceMaterial(
        isExpanded: Bool,
        isHidden: Bool
    ) -> NotchSurfaceMaterial {
        if isHidden {
            return .clear
        }
        guard isExpanded else {
            return .black
        }

        switch self {
        case .glass:
            return .glass
        case .black:
            return .black
        }
    }
}
