# Making a Swift Package Manager SwiftUI App Launch as a Standalone macOS App

## The Problem

When you build a SwiftUI app with `swift build` and run the binary directly (`.build/debug/AppName`), it runs as a child process of the terminal/IDE that launched it. It doesn't get its own Dock icon and terminates when the parent process dies.

## The Solution

Create a proper **`.app` bundle** with an `Info.plist` file. The critical key is `NSPrincipalClass` set to `NSApplication`.

## Required Structure

```
dist/AppName.app/
└── Contents/
    ├── Info.plist          ← Required: app metadata
    ├── MacOS/
    │   └── AppName         ← The compiled binary
    ├── PkgInfo             ← Optional but standard: "APPL????"
    └── Resources/
        └── AppIcon.icns    ← Optional: app icon
```

## Minimum Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AppName</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.appname</string>
    <key>CFBundleName</key>
    <string>AppName</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
```

## Build Steps

```bash
# 1. Build release binary
swift build -c release

# 2. Create bundle structure
mkdir -p dist/AppName.app/Contents/MacOS
mkdir -p dist/AppName.app/Contents/Resources

# 3. Copy binary
cp .build/release/AppName dist/AppName.app/Contents/MacOS/

# 4. Create Info.plist (see above)
cat > dist/AppName.app/Contents/Info.plist << 'EOF'
... (plist content) ...
EOF

# 5. Create PkgInfo (optional)
echo -n "APPL????" > dist/AppName.app/Contents/PkgInfo

# 6. Launch
open dist/AppName.app
```

## Key Points

1. **`NSPrincipalClass: NSApplication`** — This is the magic key that tells macOS this is a real GUI app
2. **`CFBundleExecutable`** — Must match the binary filename exactly
3. **`CFBundlePackageType: APPL`** — Identifies this as an application bundle
4. **Binary location** — Must be at `Contents/MacOS/AppName`

## Result

The app will:
- Appear in the Dock with its own icon
- Run independently of the terminal/IDE
- Persist after the launching process terminates
- Be installable by dragging to `/Applications`
