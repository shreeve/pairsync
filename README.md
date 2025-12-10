# PairSync

A beautiful dual-pane file synchronization app for macOS, built with SwiftUI.

**No Xcode required** — just `swift build` and run!

## Features

- **Dual-Pane Browser**: View source and destination side-by-side
- **Selective Sync**: Select specific files or sync entire directories
- **Local & Remote**: Sync to local directories or remote servers via SSH
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

1. **Select directories** using the folder icon in each pane
2. **Choose direction** by clicking the arrow toggle (→ or ←)
3. **Select files** (optional) — click to select, click again to deselect
4. **Click Force or Slurp** to sync

### Selective Sync

- **No files selected**: Syncs the entire current directory
- **Files selected**: Syncs only the selected files/folders

### Keyboard Shortcuts

| Keys | Action |
|------|--------|
| ⇧⌘F | Force Sync → |
| ⇧⌘S | Slurp Sync → |
| ⌥⌘F | ← Force Sync |
| ⌥⌘S | ← Slurp Sync |

### Remote Sync

1. Open Settings (gear icon)
2. Set destination to "Remote (SSH)"
3. Enter host: `user@server.com`
4. Enter path: `/home/user/backup`

**Note**: SSH key authentication must be configured (no password prompts in GUI).

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
    ├── FileBrowserPane.swift  # File list view
    ├── SyncControls.swift     # Sync buttons & direction toggle
    ├── LogPanel.swift         # rsync output viewer
    ├── RemotePane.swift       # SSH remote configuration
    └── SettingsSheet.swift    # Settings modal
```

## Version

0.5.0

## License

MIT
