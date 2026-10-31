// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Quizz",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [.library(name: "Quizz", targets: ["Quizz"])],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../Match"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(name: "Quizz", dependencies: ["Core", "Match", "DesignSystem"], resources: [.process("Resources")]),
        .testTarget(name: "QuizzTests", dependencies: ["Quizz", "Core"])
    ]
)
