// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Match",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "Match", targets: ["Match"])],
    dependencies: [.package(path: "../Core")],
    targets: [
        .target(name: "Match", dependencies: ["Core"], resources: [.process("Resources")]),
        .testTarget(name: "MatchTests", dependencies: ["Match", "Core"])
    ]
)
