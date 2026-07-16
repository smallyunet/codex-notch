import SwiftUI

@main
struct CodexNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            NotchSettingsView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                SettingsLink {
                    Text("设置…")
                }
            }
        }
    }
}
