# PairSync

A beautiful dual-pane file synchronization app for macOS, built with SwiftUI.

**No Xcode required** — just `swift build` and run!

## Features

- **Dual-Pane Browser**: View source and destination side-by-side
- **Local & Remote**: Sync to local directories or remote servers via SSH
- **Two Sync Modes**:
  - **Force**: `rsync -haz --info=name,del --delete --force-delete` (mirror, deletes extras)
  - **Slurp**: `rsync -haz --info=name` (copy only, preserves destination)
- **Bidirectional**: Sync left→right or right←left
- **Live Log**: Real-time rsync output

## Requirements

- macOS 14.0+ (Sonoma)
- Swift 5.9+
- rsync (pre-installed on macOS)

## Build & Run

```bash
# Build
swift build

# Run
.build/debug/PairSync
```

Or in one command:

```bash
swift build && .build/debug/PairSync
```

## Usage

1. **Select directories** using the folder icon in each pane
2. **Choose direction** with the arrow buttons (→ or ←)
3. **Click Force or Slurp** to sync

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

**Note**: SSH key auth must be configured (no password prompts in GUI).

## Project Structure

```
pairsync/
├── Package.swift
├── README.md
└── Sources/
    ├── PairSyncApp.swift      # App entry
    ├── Models.swift           # Data models + SyncManager
    ├── ContentView.swift      # Main layout
    ├── FileBrowserPane.swift  # File list view
    ├── SyncControls.swift     # Sync buttons
    ├── LogPanel.swift         # rsync output
    ├── RemotePane.swift       # SSH config
    └── SettingsSheet.swift    # Settings
```

## License

MIT
