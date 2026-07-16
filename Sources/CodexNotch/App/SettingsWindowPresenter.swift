import AppKit

enum SettingsWindowPresenter {
    private static let settingsWindowIdentifier = "com_apple_SwiftUI_Settings_window"

    static func isSettingsWindow(_ window: NSWindow) -> Bool {
        window.identifier?.rawValue == settingsWindowIdentifier
            || window.title == "CodexNotch Settings"
    }

    static func bringToFront(_ explicitWindow: NSWindow? = nil) {
        DispatchQueue.main.async {
            guard let window = explicitWindow ?? settingsWindow else { return }
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }

    private static var settingsWindow: NSWindow? {
        NSApp.windows.first(where: isSettingsWindow)
    }
}
