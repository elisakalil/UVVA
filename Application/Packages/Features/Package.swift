// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Features",
    platforms: [.iOS(.v18)],
    products: [.library(name: "Features", targets: ["Features"])],
    dependencies: [
        .package(path: "Home"),
        .package(path: "Learn"),
        .package(path: "Onboarding"),
        .package(path: "Quizz"),
        .package(path: "You")
    ],
    targets: [
        .target(name: "Features", dependencies: ["Home", "Learn", "Onboarding", "Quizz", "You"])
    ]
)
