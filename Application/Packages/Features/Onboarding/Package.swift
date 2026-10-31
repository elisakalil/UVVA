// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Onboarding",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [.library(name: "Onboarding", targets: ["Onboarding"])],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(name: "Onboarding", dependencies: ["Core", "DesignSystem"], resources: [.process("Resources")]),
        .testTarget(name: "OnboardingTests", dependencies: ["Onboarding", "Core"])
    ]
)
