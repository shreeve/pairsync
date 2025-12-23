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
    var selectedBg: Color { isDark ? .cyan.opacity(0.35) : .cyan.opacity(0.3) }

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

    var icon: String {
        if isDirectory { return "folder" }
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
        formatter.dateFormat = "MM/dd/yy, hh:mm a"
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

// MARK: - FileSystemManager (Local)

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

// MARK: - RemoteFileSystemManager (SFTP)

class RemoteFileSystemManager {
    let host: String
    var remoteRsyncPath: String?

    init(host: String) {
        self.host = host
    }

    /// Detect the best rsync path on the remote machine
    func detectRsyncPath() async -> String? {
        let candidates = [
            "/opt/homebrew/bin/rsync",  // macOS Apple Silicon
            "/usr/local/bin/rsync",      // macOS Intel / Linux custom
            "/usr/bin/rsync"             // System default
        ]

        for candidate in candidates {
            if await testRemoteRsync(path: candidate) {
                remoteRsyncPath = candidate
                return candidate
            }
        }
        return nil
    }

    private func testRemoteRsync(path: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.arguments = [host, "\(path) --version"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""
                // Check it's actually rsync (not openrsync which may lack --info)
                return output.contains("rsync  version 3") || output.contains("rsync version 3")
            }
            return false
        } catch {
            return false
        }
    }

    func loadDirectory(at path: String) async -> [FileItem] {
        // Use sftp in batch mode to list directory
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sftp")
        process.arguments = ["-b", "-", host]

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // SFTP commands: cd to path, then list with details
        let commands = "cd \"\(path)\"\nls -la\n"

        do {
            try process.run()
            inputPipe.fileHandleForWriting.write(commands.data(using: .utf8)!)
            inputPipe.fileHandleForWriting.closeFile()

            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: outputData, encoding: .utf8) else { return [] }

            return parseLsOutput(output, basePath: path)
        } catch {
            return []
        }
    }

    private func parseLsOutput(_ output: String, basePath: String) -> [FileItem] {
        var items: [FileItem] = []
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            // Skip empty lines, headers, and . / .. entries
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("sftp>") || trimmed.hasPrefix("total") { continue }
            if trimmed.hasSuffix(" .") || trimmed.hasSuffix(" ..") { continue }

            // Parse ls -la output: drwxr-xr-x  5 user group  160 Jan  1 12:00 filename
            let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 9 else { continue }

            let permissions = String(parts[0])
            let isDirectory = permissions.hasPrefix("d")
            let size = Int64(parts[4]) ?? 0
            let name = parts[8...].joined(separator: " ")

            // Skip hidden files
            if name.hasPrefix(".") { continue }

            // Parse date (approximate - ls format varies)
            let dateStr = "\(parts[5]) \(parts[6]) \(parts[7])"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d HH:mm"
            let date = dateFormatter.date(from: dateStr)

            let fullPath = basePath.hasSuffix("/") ? basePath + name : basePath + "/" + name
            let url = URL(fileURLWithPath: fullPath)

            items.append(FileItem(
                url: url,
                name: name,
                isDirectory: isDirectory,
                size: size,
                modificationDate: date
            ))
        }

        return items.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    func testConnection() async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sftp")
        process.arguments = ["-b", "-", host]

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            inputPipe.fileHandleForWriting.write("pwd\nquit\n".data(using: .utf8)!)
            inputPipe.fileHandleForWriting.closeFile()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    func getHomeDirectory() async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sftp")
        process.arguments = ["-b", "-", host]

        let inputPipe = Pipe()
        let outputPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
            inputPipe.fileHandleForWriting.write("pwd\nquit\n".data(using: .utf8)!)
            inputPipe.fileHandleForWriting.closeFile()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: outputData, encoding: .utf8) else { return nil }

            // Parse: Remote working directory: /home/user
            for line in output.components(separatedBy: .newlines) {
                if line.contains("working directory:") {
                    let parts = line.components(separatedBy: ":")
                    if parts.count >= 2 {
                        return parts[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
            return nil
        } catch {
            return nil
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
    @Published var leftSyncPath: String = ""      // Can be local path or user@host:/path
    @Published var rightSyncPath: String = ""     // Can be local path or user@host:/path
    @Published var selectedFilePaths: [String] = []  // Selected file paths (can include remote prefix)
    @Published var isSyncing = false
    @Published var syncProgress = ""
    @Published var syncLogs: [SyncLog] = []
    @Published var showingLog = false
    @Published var lastSyncDirection: SyncDirection?  // Track direction for refresh
    var remoteRsyncPath: String?  // Path to rsync on remote machine

    private var syncTask: Process?

    func sync(mode: SyncMode, direction: SyncDirection) {
        guard !isSyncing else { return }

        // Track direction for post-sync refresh
        lastSyncDirection = direction

        // If specific files are selected, sync them individually
        if !selectedFilePaths.isEmpty {
            addLog("Syncing \(selectedFilePaths.count) selected item(s)")
            syncSelectedFiles(mode: mode, direction: direction)
            return
        }

        addLog("No files selected - syncing entire directory")

        // Otherwise sync the entire directory
        let source: String
        let destination: String

        if direction == .leftToRight {
            guard !leftSyncPath.isEmpty else { addLog("No source selected", isError: true); return }
            guard !rightSyncPath.isEmpty else { addLog("No destination selected", isError: true); return }
            source = leftSyncPath.hasSuffix("/") ? leftSyncPath : leftSyncPath + "/"
            destination = rightSyncPath.hasSuffix("/") ? rightSyncPath : rightSyncPath + "/"
        } else {
            guard !rightSyncPath.isEmpty else { addLog("No source selected", isError: true); return }
            guard !leftSyncPath.isEmpty else { addLog("No destination selected", isError: true); return }
            source = rightSyncPath.hasSuffix("/") ? rightSyncPath : rightSyncPath + "/"
            destination = leftSyncPath.hasSuffix("/") ? leftSyncPath : leftSyncPath + "/"
        }

        executeRsync(sources: [source], destination: destination, mode: mode)
    }

    private func syncSelectedFiles(mode: SyncMode, direction: SyncDirection) {
        let destination: String

        if direction == .leftToRight {
            guard !rightSyncPath.isEmpty else { addLog("No destination selected", isError: true); return }
            destination = rightSyncPath.hasSuffix("/") ? rightSyncPath : rightSyncPath + "/"
        } else {
            guard !leftSyncPath.isEmpty else { addLog("No destination selected", isError: true); return }
            destination = leftSyncPath.hasSuffix("/") ? leftSyncPath : leftSyncPath + "/"
        }

        // For selected items, do NOT add trailing slash - we want to sync the item itself
        // (trailing slash would sync the contents, not the folder)
        executeRsync(sources: selectedFilePaths, destination: destination, mode: mode)
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
        // Check both Apple Silicon (/opt/homebrew) and Intel (/usr/local) paths
        let rsyncPath: String
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/rsync") {
            rsyncPath = "/opt/homebrew/bin/rsync"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/rsync") {
            rsyncPath = "/usr/local/bin/rsync"
        } else {
            rsyncPath = "/usr/bin/rsync"
        }
        process.executableURL = URL(fileURLWithPath: rsyncPath)

        // Check if this is a remote sync (source or destination contains @)
        let isRemoteSync = sources.contains { $0.contains("@") } || destination.contains("@")

        var arguments = mode.rsyncFlags
        if isRemoteSync, let remotePath = remoteRsyncPath {
            arguments.append("--rsync-path=\(remotePath)")
            addLog("Using local: \(rsyncPath)")
            addLog("Using remote: \(remotePath)")
        } else {
            addLog("Using: \(rsyncPath)")
        }
        arguments.append(contentsOf: sources)
        arguments.append(destination)

        process.arguments = arguments

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
                    // Notify to refresh destination pane
                    NotificationCenter.default.post(name: .syncCompleted, object: self?.lastSyncDirection)
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

    func addLog(_ message: String, isError: Bool = false) {
        syncLogs.append(SyncLog(timestamp: Date(), message: message, isError: isError))
    }
}

// MARK: - FileBrowserViewModel

enum ConnectionMode: Equatable {
    case local
    case remote(host: String)

    var isRemote: Bool {
        if case .remote = self { return true }
        return false
    }

    var host: String? {
        if case .remote(let h) = self { return h }
        return nil
    }
}

enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)

    var isConnected: Bool { self == .connected }
}

@MainActor
class FileBrowserViewModel: ObservableObject {
    @Published var currentPath: URL?
    @Published var remotePath: String = ""
    @Published var items: [FileItem] = []
    @Published var selectedItems: Set<UUID> = []
    @Published var isLoading = false
    @Published var breadcrumbs: [URL] = []

    // Remote connection
    @Published var mode: ConnectionMode = .local
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var remoteHost: String = ""

    private nonisolated let fileManager = FileSystemManager.shared
    private var remoteFileManager: RemoteFileSystemManager?

    /// The rsync path detected on the remote machine (if connected)
    var remoteRsyncPath: String? {
        remoteFileManager?.remoteRsyncPath
    }

    init(initialPath: URL? = nil) {
        if let path = initialPath { navigateTo(path) }
    }

    // MARK: - Connection Management

    func connect(to host: String) {
        guard !host.isEmpty else { return }

        connectionStatus = .connecting
        remoteFileManager = RemoteFileSystemManager(host: host)

        Task {
            let success = await remoteFileManager!.testConnection()
            if success {
                mode = .remote(host: host)
                connectionStatus = .connected

                // Detect rsync path on remote machine
                if let rsyncPath = await remoteFileManager!.detectRsyncPath() {
                    print("Remote rsync detected: \(rsyncPath)")
                } else {
                    print("Warning: No compatible rsync found on remote (need rsync 3.x)")
                }

                // Navigate to home directory
                if let home = await remoteFileManager!.getHomeDirectory() {
                    remotePath = home
                    await loadRemoteDirectory(home)
                } else {
                    remotePath = "/"
                    await loadRemoteDirectory("/")
                }
            } else {
                connectionStatus = .failed("Connection failed. Check SSH key auth.")
                remoteFileManager = nil
            }
        }
    }

    func disconnect() {
        mode = .local
        connectionStatus = .disconnected
        remoteFileManager = nil
        remotePath = ""
        items = []
        breadcrumbs = []
        selectedItems.removeAll()

        // Return to local home
        navigateTo(FileManager.default.homeDirectoryForCurrentUser)
    }

    // MARK: - Navigation

    func navigateTo(_ url: URL) {
        if case .remote = mode {
            Task { await loadRemoteDirectory(url.path) }
        } else {
            loadLocalDirectory(url)
        }
    }

    func navigateToRemotePath(_ path: String) {
        Task { await loadRemoteDirectory(path) }
    }

    private func loadLocalDirectory(_ url: URL) {
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

    private func loadRemoteDirectory(_ path: String) async {
        guard let rfm = remoteFileManager else { return }

        isLoading = true
        remotePath = path
        currentPath = URL(fileURLWithPath: path)
        updateBreadcrumbs()
        selectedItems.removeAll()

        let loadedItems = await rfm.loadDirectory(at: path)
        items = loadedItems
        isLoading = false
    }

    func refresh() {
        if case .remote = mode {
            Task { await loadRemoteDirectory(remotePath) }
        } else if let path = currentPath {
            navigateTo(path)
        }
    }

    func deleteItem(_ item: FileItem) {
        if case .remote(let host) = mode {
            // Delete remote file via SSH
            deleteRemoteItem(host: host, path: item.url.path)
        } else {
            // Delete local file
            deleteLocalItem(at: item.url)
        }
    }

    private func deleteLocalItem(at url: URL) {
        Task.detached { [weak self] in
            do {
                try FileManager.default.removeItem(at: url)
                await MainActor.run {
                    self?.refresh()
                }
            } catch {
                await MainActor.run {
                    print("Delete failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func deleteRemoteItem(host: String, path: String) {
        Task.detached { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            // Pass the full command as a single argument - SSH will execute it on the remote
            let escapedPath = path.replacingOccurrences(of: "'", with: "'\\''")
            process.arguments = [host, "rm -rf '\(escapedPath)'"]

            let errorPipe = Pipe()
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

                await MainActor.run {
                    if process.terminationStatus == 0 {
                        self?.refresh()
                    } else {
                        print("Remote delete failed (\(path)): \(errorOutput)")
                    }
                }
            } catch {
                await MainActor.run {
                    print("Remote delete error: \(error.localizedDescription)")
                }
            }
        }
    }

    func navigateUp() {
        if case .remote = mode {
            let parent = (remotePath as NSString).deletingLastPathComponent
            Task { await loadRemoteDirectory(parent) }
        } else if let c = currentPath {
            navigateTo(c.deletingLastPathComponent())
        }
    }

    func navigateToHome() {
        if case .remote = mode {
            Task {
                if let home = await remoteFileManager?.getHomeDirectory() {
                    await loadRemoteDirectory(home)
                }
            }
        } else {
            navigateTo(FileManager.default.homeDirectoryForCurrentUser)
        }
    }

    func selectDirectory() {
        // Only works for local mode
        guard case .local = mode else { return }

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
        if case .remote = mode {
            // Remote breadcrumbs from path string
            var crumbs: [URL] = []
            var path = remotePath
            while path != "/" && !path.isEmpty {
                crumbs.insert(URL(fileURLWithPath: path), at: 0)
                path = (path as NSString).deletingLastPathComponent
            }
            crumbs.insert(URL(fileURLWithPath: "/"), at: 0)
            breadcrumbs = crumbs
        } else {
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

    // MARK: - Path for Sync

    var syncPath: String {
        if case .remote(let host) = mode {
            return "\(host):\(remotePath)"
        }
        return currentPath?.path ?? ""
    }
}
