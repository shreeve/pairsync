import SwiftUI

struct RemotePane: View {
    @EnvironmentObject var syncManager: SyncManager
    @EnvironmentObject var theme: ThemeManager

    private var fullPath: String {
        guard !syncManager.remoteHost.isEmpty else { return "Not configured" }
        return "\(syncManager.remoteHost):\(syncManager.remotePath)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Remote")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.text2)

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(syncManager.remoteHost.isEmpty ? .gray : .green)
                        .frame(width: 5, height: 5)
                    Text(syncManager.remoteHost.isEmpty ? "Not configured" : "Ready")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textMuted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(theme.bg4)

            // Path display
            HStack {
                Image(systemName: "server.rack")
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
                Text(fullPath)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(theme.bg5)

            // Configuration
            VStack(spacing: 18) {
                Spacer()

                Image(systemName: "cloud")
                    .font(.system(size: 42))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))

                Text("Remote Destination")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.text2)

                VStack(spacing: 10) {
                    RemoteField(label: "Host", placeholder: "user@hostname", text: $syncManager.remoteHost)
                    RemoteField(label: "Path", placeholder: "/path/to/directory", text: $syncManager.remotePath)
                }
                .frame(maxWidth: 280)

                Text("Ensure SSH key authentication is configured")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textMuted.opacity(0.5))

                Spacer()
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.bg3)
                .shadow(color: theme.shadowColor, radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(LinearGradient(colors: [.cyan.opacity(0.25), .blue.opacity(0.08)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
        .padding(10)
    }
}

struct RemoteField: View {
    @EnvironmentObject var theme: ThemeManager
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(theme.textMuted)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(theme.text1)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(theme.hoverBg)
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(theme.border1, lineWidth: 1))
                )
        }
    }
}
