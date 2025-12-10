import SwiftUI

struct LogPanel: View {
    @EnvironmentObject var syncManager: SyncManager
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "terminal")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                    Text("Sync Log")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.text2)
                }

                Spacer()

                if syncManager.isSyncing {
                    HStack(spacing: 5) {
                        ProgressView().scaleEffect(0.45).tint(.cyan)
                        Text(syncManager.syncProgress)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.cyan)
                            .lineLimit(1)
                    }

                    Button { syncManager.cancelSync() } label: {
                        Text("Cancel")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 3).fill(Color.red.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                }

                Button { syncManager.clearLogs() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)

                Button { withAnimation { syncManager.showingLog = false } } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(theme.bgHeader)

            Divider().background(theme.border1)

            // Log content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(syncManager.syncLogs) { log in
                            LogLine(log: log).id(log.id)
                        }
                    }
                    .padding(10)
                }
                .onChange(of: syncManager.syncLogs.count) {
                    if let last = syncManager.syncLogs.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .background(theme.bg2)
        }
        .background(theme.bg1)
        .overlay(Rectangle().fill(theme.border2).frame(height: 1), alignment: .top)
    }
}

struct LogLine: View {
    @EnvironmentObject var theme: ThemeManager
    let log: SyncLog

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(log.formattedTime)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(theme.textMuted.opacity(0.5))
                .frame(width: 55, alignment: .leading)

            Text(log.message)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(log.isError ? .red : theme.text3)
                .textSelection(.enabled)
        }
        .padding(.vertical, 1)
    }
}
