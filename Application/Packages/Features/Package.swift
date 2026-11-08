// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Features",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .singleTargetLibrary("Cellar"),
        .singleTargetLibrary("Home"),
        .singleTargetLibrary("Learn"),
        .singleTargetLibrary("Onboarding"),
        .singleTargetLibrary("Quizz"),
        .singleTargetLibrary("You")
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(name: "Cellar",
                dependencies: Dependencies.common + [Dependencies.match],
                resources: [.process("Resources")]),

        .target(name: "Home",
                dependencies: Dependencies.common + [Dependencies.match],
                resources: [.process("Resources")]),

        .target(name: "Learn",
                dependencies: Dependencies.common,
                resources: [.process("Resources")]),

        .target(name: "Onboarding",
                dependencies: Dependencies.common + [Dependencies.match],
                resources: [.process("Resources")]),

        .target(name: "Quizz",
                dependencies: Dependencies.common + [Dependencies.match],
                resources: [.process("Resources")]),

        .target(name: "You",
                dependencies: Dependencies.common + [Dependencies.match],
                resources: [.process("Resources")]),

        .testTarget(name: "CellarTests",
                    dependencies: ["Cellar"] + Dependencies.tests + [Dependencies.match]),

        .testTarget(name: "HomeTests",
                    dependencies: ["Home", "Learn", .product(name: "Storage", package: "Core")] + Dependencies.tests + [Dependencies.match]),

        .testTarget(name: "LearnTests",
                    dependencies: ["Learn"] + Dependencies.tests),

        .testTarget(name: "OnboardingTests",
                    dependencies: ["Onboarding"] + Dependencies.tests),

        .testTarget(name: "QuizzTests",
                    dependencies: ["Quizz"] + Dependencies.tests),

        .testTarget(name: "YouTests",
                    dependencies: ["You"] + Dependencies.tests)
    ]
)

// MARK: - Extensions
private extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}

enum Dependencies {
    /// What every feature imports.
    static var common: [Target.Dependency] {
        [
            .product(name: "Core", package: "Core"),
            .product(name: "DesignSystem", package: "DesignSystem")
        ]
    }

    /// What every feature test imports.
    static var tests: [Target.Dependency] {
        [.product(name: "Core", package: "Core")]
    }

    static var match: Target.Dependency {
        .product(name: "Match", package: "Core")
    }
}
