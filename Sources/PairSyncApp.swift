import SwiftUI

@main
struct PairSyncApp: App {
    @StateObject private var syncManager = SyncManager()
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncManager)
                .environmentObject(theme)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1400, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Sync") {
                Button("Force Sync →") {
                    NotificationCenter.default.post(name: .forceSync, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Button("Slurp Sync →") {
                    NotificationCenter.default.post(name: .slurpSync, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Divider()

                Button("← Force Sync") {
                    NotificationCenter.default.post(name: .forceSyncReverse, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .option])

                Button("← Slurp Sync") {
                    NotificationCenter.default.post(name: .slurpSyncReverse, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
        }
    }
}

extension Notification.Name {
    static let forceSync = Notification.Name("forceSync")
    static let slurpSync = Notification.Name("slurpSync")
    static let forceSyncReverse = Notification.Name("forceSyncReverse")
    static let slurpSyncReverse = Notification.Name("slurpSyncReverse")
}
