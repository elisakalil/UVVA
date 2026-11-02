// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Core",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Match", targets: ["Match"]),
        .library(name: "Storage", targets: ["Storage"])
    ],
    targets: [
        .target(name: "Core"),
        .target(name: "Match", dependencies: ["Core"], resources: [.process("Resources")]),
        .target(name: "Storage", dependencies: ["Core", "Match"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .testTarget(name: "MatchTests", dependencies: ["Match", "Core"]),
        .testTarget(name: "StorageTests", dependencies: ["Storage", "Core"])
    ]
)
