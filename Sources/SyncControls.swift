import SwiftUI

struct SyncControls: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var leftBrowser: FileBrowserViewModel
    @ObservedObject var rightBrowser: FileBrowserViewModel
    @EnvironmentObject var syncManager: SyncManager
    @Binding var direction: SyncDirection

    @State private var showDirectoryConfirm = false
    @State private var pendingSyncMode: SyncMode?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 6) {
                Text("SYNC")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(theme.textMuted.opacity(0.7))

                DirectionToggle(direction: $direction)
            }

            SyncButton(mode: .force, direction: direction, isLoading: syncManager.isSyncing) {
                prepareSyncAndRun(mode: .force)
            }

            SyncButton(mode: .slurp, direction: direction, isLoading: syncManager.isSyncing) {
                prepareSyncAndRun(mode: .slurp)
            }

            Spacer()

            Button {
                withAnimation { syncManager.showingLog.toggle() }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: syncManager.showingLog ? "chevron.down" : "chevron.up")
                        .font(.system(size: 9, weight: .semibold))
                    Text("Log")
                        .font(.system(size: 9))
                }
                .foregroundColor(theme.textMuted)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 6).fill(theme.hoverBg))
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 16)
        }
        .frame(width: 90)
        .alert("Sync Entire Directory?", isPresented: $showDirectoryConfirm) {
            Button("Cancel", role: .cancel) {
                pendingSyncMode = nil
            }
            Button("Sync All") {
                if let mode = pendingSyncMode {
                    executeSync(mode: mode)
                }
                pendingSyncMode = nil
            }
        } message: {
            let sourceBrowser = direction == .leftToRight ? leftBrowser : rightBrowser
            let dirName = sourceBrowser.currentPath?.lastPathComponent ?? sourceBrowser.remotePath
            Text("No files are selected. This will sync the entire \"\(dirName)\" directory.")
        }
    }

    private func prepareSyncAndRun(mode: SyncMode) {
        // Check if any files are selected
        let sourceBrowser = direction == .leftToRight ? leftBrowser : rightBrowser
        let hasSelection = !sourceBrowser.selectedItems.isEmpty

        if hasSelection {
            // Files selected - sync immediately
            executeSync(mode: mode)
        } else {
            // No files selected - show confirmation
            pendingSyncMode = mode
            showDirectoryConfirm = true
        }
    }

    private func executeSync(mode: SyncMode) {
        // Use syncPath which handles both local and remote paths
        syncManager.leftSyncPath = leftBrowser.syncPath
        syncManager.rightSyncPath = rightBrowser.syncPath

        // Get selected files from the source browser based on direction
        let sourceBrowser = direction == .leftToRight ? leftBrowser : rightBrowser

        // Log selection state to sync log
        let selectedCount = sourceBrowser.selectedItems.count
        let directionStr = direction == .leftToRight ? "LEFT → RIGHT" : "RIGHT → LEFT"
        syncManager.addLog("Direction: \(directionStr)")

        if selectedCount > 0 {
            syncManager.addLog("Syncing \(selectedCount) selected item(s)")
        } else {
            syncManager.addLog("Syncing entire directory")
        }

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

        for path in selectedPaths {
            syncManager.addLog("  → \(path)")
        }

        syncManager.selectedFilePaths = selectedPaths
        syncManager.sync(mode: mode, direction: direction)
    }
}

struct DirectionToggle: View {
    @EnvironmentObject var theme: ThemeManager
    @Binding var direction: SyncDirection
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(direction == .leftToRight ? .white : theme.textMuted)
                .frame(width: 32, height: 28)
                .background(
                    direction == .leftToRight
                        ? AnyView(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyView(Color.clear)
                )

            Image(systemName: "arrow.left")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(direction == .rightToLeft ? .white : theme.textMuted)
                .frame(width: 32, height: 28)
                .background(
                    direction == .rightToLeft
                        ? AnyView(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyView(Color.clear)
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .background(RoundedRectangle(cornerRadius: 6).fill(theme.hoverBg))
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                direction = (direction == .leftToRight) ? .rightToLeft : .leftToRight
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}

struct SyncButton: View {
    let mode: SyncMode
    let direction: SyncDirection
    let isLoading: Bool
    let action: () -> Void
    @State private var isHovered = false

    private var arrow: String { direction == .leftToRight ? "→" : "←" }
    private var colors: [Color] { mode == .force ? [.orange, .red] : [.cyan, .blue] }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                if isLoading {
                    ProgressView().scaleEffect(0.55).tint(.white)
                } else {
                    Image(systemName: mode.icon)
                        .font(.system(size: 14, weight: .semibold))
                    Text("\(mode.rawValue) \(arrow)")
                        .font(.system(size: 10, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(width: 66, height: 58)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: colors.map { $0.opacity(isHovered ? 1 : 0.75) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: colors[0].opacity(isHovered ? 0.45 : 0.25), radius: isHovered ? 10 : 6, y: 3)
            )
            .scaleEffect(isHovered ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
    }
}
