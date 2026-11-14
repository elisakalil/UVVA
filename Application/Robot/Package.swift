// swift-tools-version: 6.0
import PackageDescription

/// The robot that keeps the public catalog (ARCHITECTURE §4.1, §4.3), run once a day by
/// `.github/workflows/catalog-robot.yml`. It reads the users' `WineContribution`, writes `CatalogWine` and publishes
/// the `CatalogSnapshot`, with the same Core and Match code as the app.
let package = Package(
    name: "Robot",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "../Packages/Core")],
    targets: [
        .target(name: "CatalogRobot", dependencies: [.product(name: "Core", package: "Core"),
                                                     .product(name: "Match", package: "Core")]),
        .executableTarget(name: "catalog-robot", dependencies: ["CatalogRobot"]),
        .testTarget(name: "CatalogRobotTests", dependencies: ["CatalogRobot",
                                                              .product(name: "Core", package: "Core"),
                                                              .product(name: "Match", package: "Core")])
    ]
)
