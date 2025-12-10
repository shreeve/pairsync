// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PairSync",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "PairSync",
            path: "Sources"
        )
    ]
)
