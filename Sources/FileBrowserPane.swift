import SwiftUI

struct FileBrowserPane: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var viewModel: FileBrowserViewModel
    let title: String
    @State private var hoveredItem: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header
            breadcrumbs

            if viewModel.currentPath == nil {
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
                .strokeBorder(LinearGradient(colors: [theme.border1, theme.border2], startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
        .padding(10)
    }

    private var header: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.text2)

            Spacer()

            HStack(spacing: 2) {
                IconButton(icon: "chevron.left", disabled: viewModel.currentPath == nil) { viewModel.navigateUp() }
                IconButton(icon: "house", disabled: false) { viewModel.navigateToHome() }
                IconButton(icon: "arrow.clockwise", disabled: viewModel.currentPath == nil) { viewModel.refresh() }

                Divider().frame(height: 14).padding(.horizontal, 4)

                IconButton(icon: "folder.badge.plus", disabled: false) { viewModel.selectDirectory() }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.bg4)
    }

    private var breadcrumbs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
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
                }
            }
            .padding(.vertical, 4)
        }
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
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(disabled ? theme.textMuted.opacity(0.25) : (isHovered ? theme.text1 : theme.textMuted))
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
