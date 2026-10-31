// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Storage",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "Storage", targets: ["Storage"])],
    dependencies: [.package(path: "../Core")],
    targets: [
        .target(name: "Storage", dependencies: ["Core"]),
        .testTarget(name: "StorageTests", dependencies: ["Storage", "Core"])
    ]
)
