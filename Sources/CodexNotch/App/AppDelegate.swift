import AppKit

enum AppIdentity {
    static let bundleIdentifier = "com.david.codexnotch"
    static let chatGPTCodexBundleIdentifier = "com.openai.codex"
    static let repositoryURL = URL(string: "https://github.com/smallyunet/codex-notch")!

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "development"
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let controller = MenuBarController()
        menuBarController = controller
        controller.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarController?.stop()
    }
}
