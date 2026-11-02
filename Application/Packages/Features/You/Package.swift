// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "You",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [.library(name: "You", targets: ["You"])],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(name: "You", dependencies: ["Core", .product(name: "Match", package: "Core"), "DesignSystem"], resources: [.process("Resources")]),
        .testTarget(name: "YouTests", dependencies: ["You", "Core"])
    ]
)
