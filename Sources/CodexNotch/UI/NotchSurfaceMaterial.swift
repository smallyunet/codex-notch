import Foundation

enum NotchSurfaceMaterial: Equatable, Sendable {
    case clear
    case black

    static func resolve(isHidden: Bool) -> NotchSurfaceMaterial {
        isHidden ? .clear : .black
    }
}
