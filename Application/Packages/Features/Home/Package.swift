// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Home",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [.library(name: "Home", targets: ["Home"])],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(name: "Home", dependencies: ["Core", .product(name: "Match", package: "Core"), "DesignSystem"], resources: [.process("Resources")]),
        .testTarget(name: "HomeTests", dependencies: ["Home", "Core", .product(name: "Match", package: "Core")])
    ]
)
