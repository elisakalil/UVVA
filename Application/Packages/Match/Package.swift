// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Match",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "Match", targets: ["Match"])],
    dependencies: [.package(path: "../Core")],
    targets: [
        .target(name: "Match", dependencies: ["Core"]),
        .testTarget(name: "MatchTests", dependencies: ["Match", "Core"])
    ]
)
