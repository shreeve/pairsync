import Foundation
import SwiftUI

// MARK: - Theme

enum AppTheme: String, CaseIterable {
    case dark = "Dark"
    case light = "Light"
    case system = "System"
}

class ThemeManager: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "appTheme") }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "appTheme"),
           let t = AppTheme(rawValue: saved) {
            theme = t
        } else {
            theme = .dark
        }
    }

    var isDark: Bool {
        switch theme {
        case .dark: return true
        case .light: return false
        case .system: return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
    }

    // Background colors
    var bg1: Color { isDark ? Color(r: 0.06, g: 0.06, b: 0.10) : Color(r: 0.96, g: 0.96, b: 0.98) }
    var bg2: Color { isDark ? Color(r: 0.03, g: 0.03, b: 0.06) : Color(r: 0.92, g: 0.92, b: 0.95) }
    var bg3: Color { isDark ? Color(r: 0.09, g: 0.09, b: 0.13) : Color(r: 0.98, g: 0.98, b: 1.0) }
    var bg4: Color { isDark ? Color(r: 0.11, g: 0.11, b: 0.15) : Color(r: 0.94, g: 0.94, b: 0.96) }
    var bg5: Color { isDark ? Color(r: 0.07, g: 0.07, b: 0.10) : Color(r: 0.90, g: 0.90, b: 0.93) }
    var bgHeader: Color { isDark ? Color(r: 0.08, g: 0.08, b: 0.12) : Color(r: 0.95, g: 0.95, b: 0.97) }

    // Text colors
    var text1: Color { isDark ? .white : Color(r: 0.1, g: 0.1, b: 0.12) }
    var text2: Color { isDark ? .white.opacity(0.85) : Color(r: 0.2, g: 0.2, b: 0.25) }
    var text3: Color { isDark ? .white.opacity(0.6) : Color(r: 0.4, g: 0.4, b: 0.45) }
    var textMuted: Color { isDark ? .secondary : .secondary }

    // Border/separator colors
    var border1: Color { isDark ? .white.opacity(0.08) : Color(r: 0.85, g: 0.85, b: 0.88) }
    var border2: Color { isDark ? .white.opacity(0.04) : Color(r: 0.90, g: 0.90, b: 0.92) }

    // Hover/selection
    var hoverBg: Color { isDark ? .white.opacity(0.08) : Color(r: 0.0, g: 0.0, b: 0.0).opacity(0.05) }
    var selectedBg: Color { isDark ? .cyan.opacity(0.18) : .cyan.opacity(0.15) }

    // Shadow
    var shadowColor: Color { isDark ? .black.opacity(0.4) : .black.opacity(0.1) }
}

extension Color {
    init(r: Double, g: Double, b: Double) {
        self.init(nsColor: NSColor(red: r, green: g, blue: b, alpha: 1))
    }
}

// MARK: - FileItem

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date?
    var children: [FileItem]?
    var isExpanded: Bool = false

    var icon: String {
        if isDirectory { return isExpanded ? "folder.fill" : "folder" }
        return iconForExtension(url.pathExtension.lowercased())
    }

    var iconColor: Color {
        if isDirectory { return .cyan }
        return colorForExtension(url.pathExtension.lowercased())
    }

    var formattedSize: String {
        guard !isDirectory else { return "—" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        guard let date = modificationDate else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func iconForExtension(_ ext: String) -> String {
        switch ext {
        case "swift": return "swift"
        case "js", "ts", "jsx", "tsx": return "curlybraces"
        case "py": return "chevron.left.forwardslash.chevron.right"
        case "html", "htm": return "globe"
        case "css", "scss": return "paintbrush"
        case "json", "yaml", "yml": return "doc.text"
        case "md", "txt": return "doc.plaintext"
        case "png", "jpg", "jpeg", "gif", "svg": return "photo"
        case "mp3", "wav": return "music.note"
        case "mp4", "mov": return "film"
        case "pdf": return "doc.richtext"
        case "zip", "tar", "gz": return "archivebox"
        case "sh", "zsh", "bash": return "terminal"
        default: return "doc"
        }
    }

    private func colorForExtension(_ ext: String) -> Color {
        switch ext {
        case "swift": return .orange
        case "js", "jsx": return .yellow
        case "ts", "tsx": return .blue
        case "py": return .green
        case "html": return .red
        case "css", "scss": return .pink
        case "json": return .purple
        case "md": return .cyan
        default: return .secondary
        }
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: FileItem, rhs: FileItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - FileSystemManager

class FileSystemManager {
    static let shared = FileSystemManager()

    func loadDirectory(at url: URL) -> [FileItem] {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            return contents.compactMap { itemURL -> FileItem? in
                guard let values = try? itemURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]) else { return nil }
                return FileItem(
                    url: itemURL,
                    name: itemURL.lastPathComponent,
                    isDirectory: values.isDirectory ?? false,
                    size: Int64(values.fileSize ?? 0),
                    modificationDate: values.contentModificationDate
                )
            }.sorted { a, b in
                if a.isDirectory != b.isDirectory { return a.isDirectory }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        } catch {
            return []
        }
    }
}

// MARK: - SyncMode

enum SyncMode: String, CaseIterable {
    case force = "Force"
    case slurp = "Slurp"

    var description: String {
        switch self {
        case .force: return "Mirror source → destination (deletes extra files)"
        case .slurp: return "Copy new/changed files (preserves destination)"
        }
    }

    var icon: String {
        switch self {
        case .force: return "arrow.triangle.2.circlepath"
        case .slurp: return "square.and.arrow.down"
        }
    }

    var rsyncFlags: [String] {
        switch self {
        case .force: return ["-haz", "--info=name,del", "--delete", "--force-delete"]
        case .slurp: return ["-haz", "--info=name"]
        }
    }
}

enum SyncDirection {
    case leftToRight, rightToLeft
}

struct SyncLog: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let isError: Bool

    var formattedTime: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: timestamp)
    }
}

// MARK: - SyncManager

@MainActor
class SyncManager: ObservableObject {
    @Published var leftPath: URL?
    @Published var rightPath: URL?
    @Published var selectedFiles: [URL] = []  // Selected files to sync
    @Published var isRemoteRight = false
    @Published var remoteHost = ""
    @Published var remotePath = ""
    @Published var isSyncing = false
    @Published var syncProgress = ""
    @Published var syncLogs: [SyncLog] = []
    @Published var showingLog = false

    private var syncTask: Process?

    func sync(mode: SyncMode, direction: SyncDirection) {
        guard !isSyncing else { return }

        // If specific files are selected, sync them individually
        if !selectedFiles.isEmpty {
            syncSelectedFiles(mode: mode, direction: direction)
            return
        }

        // Otherwise sync the entire directory
        let source: String
        let destination: String

        if direction == .leftToRight {
            guard let left = leftPath else { addLog("No source selected", isError: true); return }
            source = left.path + "/"
            if isRemoteRight {
                guard !remoteHost.isEmpty, !remotePath.isEmpty else { addLog("Remote not configured", isError: true); return }
                destination = "\(remoteHost):\(remotePath)/"
            } else {
                guard let right = rightPath else { addLog("No destination selected", isError: true); return }
                destination = right.path + "/"
            }
        } else {
            if isRemoteRight {
                guard !remoteHost.isEmpty, !remotePath.isEmpty else { addLog("Remote not configured", isError: true); return }
                source = "\(remoteHost):\(remotePath)/"
            } else {
                guard let right = rightPath else { addLog("No source selected", isError: true); return }
                source = right.path + "/"
            }
            guard let left = leftPath else { addLog("No destination selected", isError: true); return }
            destination = left.path + "/"
        }

        executeRsync(sources: [source], destination: destination, mode: mode)
    }

    private func syncSelectedFiles(mode: SyncMode, direction: SyncDirection) {
        let destination: String

        if direction == .leftToRight {
            if isRemoteRight {
                guard !remoteHost.isEmpty, !remotePath.isEmpty else { addLog("Remote not configured", isError: true); return }
                destination = "\(remoteHost):\(remotePath)/"
            } else {
                guard let right = rightPath else { addLog("No destination selected", isError: true); return }
                destination = right.path + "/"
            }
        } else {
            guard let left = leftPath else { addLog("No destination selected", isError: true); return }
            destination = left.path + "/"
        }

        // For selected files, add trailing slash only for directories
        let sources = selectedFiles.map { url -> String in
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            return isDir.boolValue ? url.path + "/" : url.path
        }

        executeRsync(sources: sources, destination: destination, mode: mode)
    }

    private func executeRsync(sources: [String], destination: String, mode: SyncMode) {
        isSyncing = true
        syncProgress = "Starting \(mode.rawValue) sync..."
        showingLog = true

        addLog("Starting \(mode.rawValue) sync")
        if sources.count == 1 {
            addLog("Source: \(sources[0])")
        } else {
            addLog("Sources: \(sources.count) items")
            for src in sources {
                addLog("  • \(URL(fileURLWithPath: src).lastPathComponent)")
            }
        }
        addLog("Destination: \(destination)")
        addLog("───")

        let process = Process()
        // Prefer Homebrew rsync (full-featured) over macOS openrsync
        let rsyncPath = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/rsync")
            ? "/opt/homebrew/bin/rsync"
            : "/usr/bin/rsync"
        process.executableURL = URL(fileURLWithPath: rsyncPath)
        process.arguments = mode.rsyncFlags + sources + [destination]

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                Task { @MainActor in
                    for line in output.components(separatedBy: .newlines) where !line.isEmpty {
                        self?.addLog(line)
                        self?.syncProgress = line
                    }
                }
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                Task { @MainActor in
                    for line in output.components(separatedBy: .newlines) where !line.isEmpty {
                        self?.addLog(line, isError: true)
                    }
                }
            }
        }

        process.terminationHandler = { [weak self] proc in
            Task { @MainActor in
                self?.isSyncing = false
                pipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil

                self?.addLog("───")
                if proc.terminationStatus == 0 {
                    self?.addLog("✓ Sync completed successfully")
                    self?.syncProgress = "Sync completed"
                } else {
                    self?.addLog("✗ Sync failed (exit: \(proc.terminationStatus))", isError: true)
                    self?.syncProgress = "Sync failed"
                }
            }
        }

        syncTask = process
        do { try process.run() }
        catch { isSyncing = false; addLog("Failed: \(error)", isError: true) }
    }

    func cancelSync() {
        syncTask?.terminate()
        isSyncing = false
        addLog("Sync cancelled", isError: true)
    }

    func clearLogs() { syncLogs.removeAll() }

    private func addLog(_ message: String, isError: Bool = false) {
        syncLogs.append(SyncLog(timestamp: Date(), message: message, isError: isError))
    }
}

// MARK: - FileBrowserViewModel

@MainActor
class FileBrowserViewModel: ObservableObject {
    @Published var currentPath: URL?
    @Published var items: [FileItem] = []
    @Published var selectedItems: Set<UUID> = []
    @Published var isLoading = false
    @Published var breadcrumbs: [URL] = []

    private nonisolated let fileManager = FileSystemManager.shared

    init(initialPath: URL? = nil) {
        if let path = initialPath { navigateTo(path) }
    }

    func navigateTo(_ url: URL) {
        isLoading = true
        currentPath = url
        updateBreadcrumbs()

        let fm = fileManager
        Task.detached {
            let items = fm.loadDirectory(at: url)
            await MainActor.run {
                self.items = items
                self.isLoading = false
                self.selectedItems.removeAll()
            }
        }
    }

    func refresh() { if let path = currentPath { navigateTo(path) } }
    func navigateUp() { if let c = currentPath { navigateTo(c.deletingLastPathComponent()) } }
    func navigateToHome() { navigateTo(FileManager.default.homeDirectoryForCurrentUser) }

    func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        if let currentPath { panel.directoryURL = currentPath }
        if panel.runModal() == .OK, let url = panel.url { navigateTo(url) }
    }

    private func updateBreadcrumbs() {
        guard let current = currentPath else { breadcrumbs = []; return }
        var crumbs: [URL] = []
        var url = current
        let home = FileManager.default.homeDirectoryForCurrentUser
        while url.path != "/" {
            crumbs.insert(url, at: 0)
            if url == home { break }
            url = url.deletingLastPathComponent()
        }
        if crumbs.first?.path != "/" && current.path.hasPrefix("/") {
            crumbs.insert(URL(fileURLWithPath: "/"), at: 0)
        }
        breadcrumbs = crumbs
    }
}
