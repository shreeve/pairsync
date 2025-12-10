# PairSync

A beautiful dual-pane file synchronization app for macOS, built with SwiftUI.

**No Xcode required** — just `swift build` and run!

## Features

- **Dual-Pane Browser**: View source and destination side-by-side
- **Remote SSH Browsing**: Connect either pane to a remote server via SFTP
- **Selective Sync**: Select specific files or sync entire directories
- **Two Sync Modes**:
  - **Force**: `rsync -haz --info=name,del --delete --force-delete` (mirror, deletes extras)
  - **Slurp**: `rsync -haz --info=name` (copy only, preserves destination)
- **Bidirectional**: Sync left→right or right←left
- **Light/Dark Theme**: Toggle with sun/moon button, persists across sessions
- **Live Log**: Real-time rsync output with cancel support

## Requirements

- macOS 14.0+ (Sonoma)
- Swift 5.9+
- rsync (uses Homebrew version if available, falls back to system)
- SSH key authentication configured (for remote connections)

## Build & Run

### Quick Start (Debug)

```bash
swift build && .build/debug/PairSync
```

### Standalone App Bundle

Build a proper `.app` that runs independently:

```bash
./Scripts/build-app.sh
open dist/PairSync.app
```

Or create a DMG for distribution:

```bash
./Scripts/build-app.sh --dmg
```

See [LAUNCH.md](LAUNCH.md) for details on how standalone app bundles work.

## Usage

### Local Browsing

1. Both panes start at your home directory
2. Double-click folders to navigate
3. Use breadcrumbs or navigation buttons to move around
4. Click the folder+ icon to open a directory picker

### Remote SSH Browsing

1. Click the **wifi icon** in any pane's header
2. Enter `user@hostname` (e.g., `deploy@server.com`)
3. Click **Connect**
4. Browse the remote filesystem just like local files!

The pane will show a **green border** when connected remotely.

### Syncing

1. **Select files** (optional) — click to select, click again to deselect
2. **Choose direction** by clicking the arrow toggle (→ or ←)
3. Click **Force** or **Slurp** to sync

**Selective Sync:**
- No files selected → syncs entire current directory
- Files selected → syncs only selected items

### Keyboard Shortcuts

| Keys | Action |
|------|--------|
| ⇧⌘F | Force Sync → |
| ⇧⌘S | Slurp Sync → |
| ⌥⌘F | ← Force Sync |
| ⌥⌘S | ← Slurp Sync |

## Sync Combinations

| Left Pane | Right Pane | Use Case |
|-----------|------------|----------|
| Local | Local | Backup between drives |
| Local | Remote | Deploy to server |
| Remote | Local | Download from server |
| Remote | Remote | Server-to-server sync |

## Project Structure

```
pairsync/
├── Package.swift
├── README.md
├── LAUNCH.md
├── Scripts/
│   └── build-app.sh        # Creates standalone .app bundle
└── Sources/
    ├── PairSyncApp.swift      # App entry point
    ├── Models.swift           # Data models, SyncManager, ThemeManager
    ├── ContentView.swift      # Main layout
    ├── FileBrowserPane.swift  # File list + SSH connection
    ├── SyncControls.swift     # Sync buttons & direction toggle
    ├── LogPanel.swift         # rsync output viewer
    └── SettingsSheet.swift    # Settings modal
```

## Version

0.5.0

## License

MIT
