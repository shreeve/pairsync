import SwiftUI

struct FileBrowserPane: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var viewModel: FileBrowserViewModel
    let title: String
    @State private var hoveredItem: UUID?
    @State private var showConnectionBar = false
    @State private var itemToDelete: FileItem?
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            header

            if showConnectionBar || viewModel.mode.isRemote {
                connectionBar
            }

            breadcrumbs

            if viewModel.mode.isRemote && viewModel.connectionStatus != .connected {
                connectionState
            } else if viewModel.currentPath == nil && !viewModel.mode.isRemote {
                emptyState
            } else if viewModel.isLoading {
                loadingState
            } else if viewModel.items.isEmpty {
                emptyDirectory
            } else {
                fileList
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.bg3)
                .shadow(color: theme.shadowColor, radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    viewModel.mode.isRemote
                        ? LinearGradient(colors: [.green.opacity(0.5), .green.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [theme.border1, theme.border2], startPoint: .top, endPoint: .bottom),
                    lineWidth: viewModel.mode.isRemote ? 2 : 1
                )
        )
        .padding(10)
        .alert("Delete \(itemToDelete?.isDirectory == true ? "Folder" : "File")?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    viewModel.deleteItem(item)
                    itemToDelete = nil
                }
            }
        } message: {
            if let item = itemToDelete {
                Text("Are you sure you want to delete \"\(item.name)\"?\n\nThis action cannot be undone.")
            }
        }
    }

    private var header: some View {
        HStack {
            // Title with connection indicator
            HStack(spacing: 6) {
                if viewModel.mode.isRemote {
                    Circle()
                        .fill(viewModel.connectionStatus == .connected ? .green : .orange)
                        .frame(width: 6, height: 6)
                }
                Text(viewModel.mode.isRemote ? (viewModel.mode.host ?? "Remote") : title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.text2)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 2) {
                // SSH toggle button - server icon
                Button {
                    if viewModel.mode.isRemote {
                        viewModel.disconnect()
                        showConnectionBar = false
                    } else {
                        showConnectionBar.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 10, weight: .medium))
                        Text(viewModel.mode.isRemote ? "SSH" : "SSH")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(viewModel.mode.isRemote ? .green : (showConnectionBar ? .cyan : theme.textMuted))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(viewModel.mode.isRemote ? Color.green.opacity(0.15) : (showConnectionBar ? Color.cyan.opacity(0.15) : theme.hoverBg))
                    )
                }
                .buttonStyle(.plain)

                Divider().frame(height: 14).padding(.horizontal, 2)

                IconButton(icon: "chevron.left", disabled: viewModel.currentPath == nil) { viewModel.navigateUp() }
                IconButton(icon: "house", disabled: false) { viewModel.navigateToHome() }
                IconButton(icon: "arrow.clockwise", disabled: viewModel.currentPath == nil) { viewModel.refresh() }

                if !viewModel.mode.isRemote {
                    Divider().frame(height: 14).padding(.horizontal, 2)
                    IconButton(icon: "folder.badge.plus", disabled: false) { viewModel.selectDirectory() }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.bg4)
    }

    private var connectionBar: some View {
        HStack(spacing: 8) {
            // Connection status indicator
            if viewModel.connectionStatus == .connecting {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: "server.rack")
                    .font(.system(size: 10))
                    .foregroundColor(viewModel.mode.isRemote ? .green : .cyan)
            }

            TextField("user@hostname", text: $viewModel.remoteHost)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(theme.text1)
                .disabled(viewModel.mode.isRemote || viewModel.connectionStatus == .connecting)

            if viewModel.mode.isRemote {
                Button("Disconnect") {
                    viewModel.disconnect()
                    showConnectionBar = false
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.red.opacity(0.15)))
                .buttonStyle(.plain)
            } else if viewModel.connectionStatus == .connecting {
                // Connecting state
                HStack(spacing: 4) {
                    Text("Connecting")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.orange.opacity(0.15)))

                Button {
                    viewModel.disconnect()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            } else {
                Button("Connect") {
                    viewModel.connect(to: viewModel.remoteHost)
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.green.opacity(0.8)))
                .buttonStyle(.plain)
                .disabled(viewModel.remoteHost.isEmpty)

                Button {
                    showConnectionBar = false
                    viewModel.remoteHost = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(theme.bg5)
    }

    private var breadcrumbs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if viewModel.mode.isRemote {
                    Image(systemName: "server.rack")
                        .font(.system(size: 9))
                        .foregroundColor(.green)
                }

                ForEach(Array(viewModel.breadcrumbs.enumerated()), id: \.element) { i, url in
                    if i > 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(theme.textMuted.opacity(0.5))
                    }
                    BreadcrumbButton(url: url, isLast: i == viewModel.breadcrumbs.count - 1) {
                        viewModel.navigateTo(url)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(height: 36)
        .background(theme.bg5)
    }

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.items) { item in
                    FileRow(
                        item: item,
                        isHovered: hoveredItem == item.id,
                        isSelected: viewModel.selectedItems.contains(item.id),
                        onTap: { viewModel.selectedItems.formSymmetricDifference([item.id]) },
                        onDoubleTap: { if item.isDirectory { viewModel.navigateTo(item.url) } }
                    )
                    .onHover { hoveredItem = $0 ? item.id : nil }
                    .contextMenu {
                        Button {
                            if item.isDirectory {
                                viewModel.navigateTo(item.url)
                            }
                        } label: {
                            Label("Open", systemImage: "folder")
                        }
                        .disabled(!item.isDirectory)

                        Divider()

                        Button {
                            viewModel.selectedItems.formSymmetricDifference([item.id])
                        } label: {
                            Label(viewModel.selectedItems.contains(item.id) ? "Deselect" : "Select",
                                  systemImage: viewModel.selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                        }

                        Divider()

                        Button(role: .destructive) {
                            itemToDelete = item
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var connectionState: some View {
        VStack(spacing: 14) {
            switch viewModel.connectionStatus {
            case .connecting:
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.cyan)
                Text("Connecting...")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textMuted)

            case .failed(let message):
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 36))
                    .foregroundColor(.red.opacity(0.7))
                Text("Connection Failed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.text2)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMuted)
                    .multilineTextAlignment(.center)
                Button("Try Again") {
                    viewModel.connect(to: viewModel.remoteHost)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan))
                .buttonStyle(.plain)

            case .disconnected:
                Image(systemName: "server.rack")
                    .font(.system(size: 36))
                    .foregroundColor(theme.textMuted.opacity(0.5))
                Text("Not Connected")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textMuted)

            case .connected:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(LinearGradient(colors: [theme.textMuted.opacity(0.5), theme.textMuted.opacity(0.2)], startPoint: .top, endPoint: .bottom))

            Text("No Directory Selected")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textMuted)

            Button { viewModel.selectDirectory() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                    Text("Select Directory")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyDirectory: some View {
        VStack(spacing: 10) {
            Image(systemName: "folder")
                .font(.system(size: 32))
                .foregroundColor(theme.textMuted.opacity(0.4))
            Text("Empty Directory")
                .font(.system(size: 13))
                .foregroundColor(theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView().scaleEffect(0.7).tint(.cyan)
            Text("Loading...")
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Components

struct IconButton: View {
    @EnvironmentObject var theme: ThemeManager
    let icon: String
    let disabled: Bool
    var highlighted: Bool = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(
                    disabled ? theme.textMuted.opacity(0.25) :
                    (highlighted ? .green : (isHovered ? theme.text1 : theme.textMuted))
                )
                .frame(width: 22, height: 22)
                .background(RoundedRectangle(cornerRadius: 5).fill(isHovered && !disabled ? theme.hoverBg : .clear))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { isHovered = $0 }
    }
}

struct BreadcrumbButton: View {
    @EnvironmentObject var theme: ThemeManager
    let url: URL
    let isLast: Bool
    let action: () -> Void
    @State private var isHovered = false

    private var displayName: String {
        if url.path == "/" { return "/" }
        if url == FileManager.default.homeDirectoryForCurrentUser { return "~" }
        return url.lastPathComponent
    }

    var body: some View {
        Button(action: action) {
            Text(displayName)
                .font(.system(size: 12, weight: isLast ? .semibold : .medium, design: .monospaced))
                .foregroundColor(isLast ? .cyan : (isHovered ? theme.text1 : theme.text3))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 4).fill(isHovered ? theme.hoverBg : .clear))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct FileRow: View {
    @EnvironmentObject var theme: ThemeManager
    let item: FileItem
    let isHovered: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 13))
                .foregroundColor(item.iconColor)
                .frame(width: 18)

            Text(item.name)
                .font(.system(size: 12))
                .foregroundColor(theme.text2)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(item.formattedSize)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(theme.textMuted)
                .frame(width: 60, alignment: .trailing)

            Text(item.formattedDate)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(theme.textMuted)
                .frame(width: 110, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? theme.selectedBg : (isHovered ? theme.hoverBg : .clear))
                .padding(.horizontal, 6)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onDoubleTap() }
        .onTapGesture(count: 1) { onTap() }
    }
}
