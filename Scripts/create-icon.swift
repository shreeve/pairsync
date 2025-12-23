#!/usr/bin/env swift

import AppKit
import Foundation

// Create iconset directory
let resourcesDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .deletingLastPathComponent()
    .appendingPathComponent("Resources")
let iconsetDir = resourcesDir.appendingPathComponent("AppIcon.iconset")

try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

// Required sizes
let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

func createIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = CGFloat(size) * 0.22
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Background gradient
    let gradient = NSGradient(colors: [
        NSColor(red: 0.18, green: 0.22, blue: 0.28, alpha: 1.0),
        NSColor(red: 0.10, green: 0.13, blue: 0.17, alpha: 1.0)
    ])!
    gradient.draw(in: path, angle: -45)

    // Subtle top highlight
    let highlightRect = NSRect(x: CGFloat(size) * 0.04, y: CGFloat(size) * 0.85,
                               width: CGFloat(size) * 0.92, height: CGFloat(size) * 0.12)
    let highlightPath = NSBezierPath(roundedRect: highlightRect, xRadius: cornerRadius, yRadius: CGFloat(size) * 0.06)
    NSColor(white: 1.0, alpha: 0.06).setFill()
    highlightPath.fill()

    // Draw sync symbol using SF Symbol
    let config = NSImage.SymbolConfiguration(pointSize: CGFloat(size) * 0.5, weight: .semibold)
    if let symbolImage = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {

        // Cyan color
        let tintedImage = symbolImage.copy() as! NSImage
        tintedImage.lockFocus()
        NSColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 1.0).set()
        NSRect(origin: .zero, size: tintedImage.size).fill(using: .sourceAtop)
        tintedImage.unlockFocus()

        let symbolSize = tintedImage.size
        let x = (CGFloat(size) - symbolSize.width) / 2
        let y = (CGFloat(size) - symbolSize.height) / 2
        tintedImage.draw(at: NSPoint(x: x, y: y), from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    image.unlockFocus()
    return image
}

for (size, filename) in sizes {
    let image = createIcon(size: size)

    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let outputURL = iconsetDir.appendingPathComponent(filename)
        try? pngData.write(to: outputURL)
        print("Created \(filename) (\(size)x\(size))")
    }
}

print("\nCreating icns file...")

// Create icns using iconutil
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", resourcesDir.appendingPathComponent("AppIcon.icns").path]
try? process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("✅ AppIcon.icns created successfully!")
    // Clean up iconset
    try? FileManager.default.removeItem(at: iconsetDir)
} else {
    print("❌ Failed to create icns file")
}

