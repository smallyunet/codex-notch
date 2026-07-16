import AppKit

enum AppIdentity {
    static let bundleIdentifier = "com.david.codexnotch"
    static let chatGPTCodexBundleIdentifier = "com.openai.codex"
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var runtimeCoordinator: NotchRuntimeCoordinator?
    private var settingsWindowObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        observeSettingsWindowActivation()
        runtimeCoordinator = NotchRuntimeCoordinator()
        runtimeCoordinator?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        runtimeCoordinator?.stop()
        stopObservingSettingsWindowActivation()
    }

    deinit {
        stopObservingSettingsWindowActivation()
    }

    private func observeSettingsWindowActivation() {
        settingsWindowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let window = notification.object as? NSWindow,
                  SettingsWindowPresenter.isSettingsWindow(window) else {
                return
            }
            SettingsWindowPresenter.bringToFront(window)
        }
    }

    private func stopObservingSettingsWindowActivation() {
        if let settingsWindowObserver {
            NotificationCenter.default.removeObserver(settingsWindowObserver)
        }
        settingsWindowObserver = nil
    }
}
