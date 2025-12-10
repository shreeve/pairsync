import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var syncManager: SyncManager
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var leftBrowser = FileBrowserViewModel(initialPath: FileManager.default.homeDirectoryForCurrentUser)
    @StateObject private var rightBrowser = FileBrowserViewModel(initialPath: FileManager.default.homeDirectoryForCurrentUser)
    @State private var showingSettings = false
    @State private var syncDirection: SyncDirection = .leftToRight

    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [theme.bg1, theme.bg2], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                titleBar

                HStack(spacing: 0) {
                    FileBrowserPane(viewModel: leftBrowser, title: "Local")
                    SyncControls(leftBrowser: leftBrowser, rightBrowser: rightBrowser, direction: $syncDirection)
                    FileBrowserPane(viewModel: rightBrowser, title: "Local")
                }

                if syncManager.showingLog {
                    LogPanel()
                        .frame(height: 180)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .forceSync)) { _ in
            runSync(mode: .force, direction: .leftToRight)
        }
        .onReceive(NotificationCenter.default.publisher(for: .slurpSync)) { _ in
            runSync(mode: .slurp, direction: .leftToRight)
        }
        .onReceive(NotificationCenter.default.publisher(for: .forceSyncReverse)) { _ in
            runSync(mode: .force, direction: .rightToLeft)
        }
        .onReceive(NotificationCenter.default.publisher(for: .slurpSyncReverse)) { _ in
            runSync(mode: .slurp, direction: .rightToLeft)
        }
        .onReceive(NotificationCenter.default.publisher(for: .syncCompleted)) { notification in
            // Refresh the destination pane after successful sync
            if let direction = notification.object as? SyncDirection {
                if direction == .leftToRight {
                    rightBrowser.refresh()
                } else {
                    leftBrowser.refresh()
                }
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsSheet() }
        .animation(.easeInOut(duration: 0.25), value: syncManager.showingLog)
    }

    private func runSync(mode: SyncMode, direction: SyncDirection) {
        // Use syncPath which handles both local and remote paths
        syncManager.leftSyncPath = leftBrowser.syncPath
        syncManager.rightSyncPath = rightBrowser.syncPath

        // Get selected files from the source browser
        let sourceBrowser = direction == .leftToRight ? leftBrowser : rightBrowser

        // Build selected file paths (with remote prefix if needed)
        let selectedPaths: [String] = sourceBrowser.items
            .filter { sourceBrowser.selectedItems.contains($0.id) }
            .map { item in
                if case .remote(let host) = sourceBrowser.mode {
                    return "\(host):\(item.url.path)"
                } else {
                    return item.url.path
                }
            }

        syncManager.selectedFilePaths = selectedPaths
        syncManager.sync(mode: mode, direction: direction)
    }

    private var titleBar: some View {
        ZStack {
            // Centered title
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))

                Text("PairSync")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.text1)
            }

            // Right-aligned buttons
            HStack {
                Spacer()

                HStack(spacing: 12) {
                    // Theme toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            theme.theme = theme.isDark ? .light : .dark
                        }
                    } label: {
                        Image(systemName: theme.isDark ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 13))
                            .foregroundColor(theme.isDark ? .yellow : .indigo)
                    }
                    .buttonStyle(.plain)
                    .help(theme.isDark ? "Switch to Light Mode" : "Switch to Dark Mode")

                    // Settings
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(theme.text3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 36)
        .background(theme.bgHeader.opacity(0.9))
        .overlay(Rectangle().fill(theme.border2).frame(height: 1), alignment: .bottom)
    }
}
