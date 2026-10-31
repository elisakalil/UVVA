// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Home",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [.library(name: "Home", targets: ["Home"])],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../Match"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(name: "Home", dependencies: ["Core", "Match", "DesignSystem"]),
        .testTarget(name: "HomeTests", dependencies: ["Home", "Core", "Match"])
    ]
)
