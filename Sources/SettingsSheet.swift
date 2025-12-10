import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject var syncManager: SyncManager
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.text1)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(theme.bgHeader)

            ScrollView {
                VStack(spacing: 20) {
                    // Theme
                    SettingsSection(title: "Appearance", icon: "paintbrush") {
                        Picker("Theme", selection: $theme.theme) {
                            ForEach(AppTheme.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // SSH Connection Info
                    SettingsSection(title: "Remote Connections", icon: "server.rack") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Each pane can connect to a remote server via SSH.")
                                .font(.system(size: 11))
                                .foregroundColor(theme.textMuted)

                            HStack(spacing: 6) {
                                Image(systemName: "1.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.cyan)
                                Text("Click the wifi icon in a pane's header")
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.text3)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "2.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.cyan)
                                Text("Enter user@hostname and click Connect")
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.text3)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "3.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.cyan)
                                Text("Browse and sync just like local files")
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.text3)
                            }

                            Divider().background(theme.border1).padding(.vertical, 4)

                            Text("⚠️ SSH key authentication must be configured")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                    }

                    // Sync Modes Info
                    SettingsSection(title: "Sync Modes", icon: "info.circle") {
                        VStack(alignment: .leading, spacing: 14) {
                            ModeInfo(mode: .force, cmd: "rsync -haz --info=name,del --delete --force-delete")
                            Divider().background(theme.border1)
                            ModeInfo(mode: .slurp, cmd: "rsync -haz --info=name")
                        }
                    }

                    // Shortcuts
                    SettingsSection(title: "Keyboard Shortcuts", icon: "keyboard") {
                        VStack(spacing: 6) {
                            ShortcutRow(keys: "⇧⌘F", action: "Force Sync →")
                            ShortcutRow(keys: "⇧⌘S", action: "Slurp Sync →")
                            ShortcutRow(keys: "⌥⌘F", action: "← Force Sync")
                            ShortcutRow(keys: "⌥⌘S", action: "← Slurp Sync")
                        }
                    }

                    // About
                    SettingsSection(title: "About", icon: "info.circle") {
                        HStack {
                            Text("PairSync")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.text2)
                            Spacer()
                            Text("v0.5.0")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(theme.textMuted)
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 460, height: 580)
        .background(theme.bg1)
    }
}

struct SettingsSection<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.text2)
            }

            VStack { content }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.hoverBg)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(theme.border1, lineWidth: 1))
                )
        }
    }
}

struct ModeInfo: View {
    @EnvironmentObject var theme: ThemeManager
    let mode: SyncMode
    let cmd: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 11))
                    .foregroundColor(mode == .force ? .orange : .cyan)
                Text(mode.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.text2)
            }
            Text(mode.description)
                .font(.system(size: 11))
                .foregroundColor(theme.textMuted)
            Text(cmd)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.75))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.cyan.opacity(0.08)))
        }
    }
}

struct ShortcutRow: View {
    @EnvironmentObject var theme: ThemeManager
    let keys: String
    let action: String

    var body: some View {
        HStack {
            Text(keys)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.cyan)
                .frame(width: 50, alignment: .leading)
            Text(action)
                .font(.system(size: 11))
                .foregroundColor(theme.textMuted)
            Spacer()
        }
    }
}
