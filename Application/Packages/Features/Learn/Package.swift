// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Learn",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [.library(name: "Learn", targets: ["Learn"])],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(name: "Learn", dependencies: ["Core", "DesignSystem"], resources: [.process("Resources")]),
        .testTarget(name: "LearnTests", dependencies: ["Learn", "Core"])
    ]
)
