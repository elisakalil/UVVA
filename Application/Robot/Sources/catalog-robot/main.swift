import CatalogRobot
import Core
import Foundation

/// `catalog-robot [--dry-run]`, configured by the environment:
///
/// - `CLOUDKIT_KEY_ID`, `CLOUDKIT_PRIVATE_KEY`: the server-to-server key of the CloudKit Dashboard (PEM).
/// - `CLOUDKIT_ENVIRONMENT`: `development` or `production`.
/// - `CLOUDKIT_CONTAINER`: `iCloud.app.uvva` unless given.
/// - `CATALOG_SEED`: the file `pack_content.py --seed` wrote.
let environment = ProcessInfo.processInfo.environment

func required(_ name: String) -> String {
    guard let value = environment[name], !value.isEmpty else {
        FileHandle.standardError.write(Data("Missing \(name)\n".utf8))
        exit(2)
    }
    return value
}

do {
    let cloud = try CloudKitWeb(container: environment["CLOUDKIT_CONTAINER"] ?? "iCloud.app.uvva",
                                environment: required("CLOUDKIT_ENVIRONMENT"),
                                keyID: required("CLOUDKIT_KEY_ID"),
                                privateKeyPEM: required("CLOUDKIT_PRIVATE_KEY"))
    let seed = try JSONDecoder().decode(CatalogWinesFile.self,
                                        from: Data(contentsOf: URL(fileURLWithPath: required("CATALOG_SEED")))).wines
    let robot = CatalogRobot(cloud: cloud, seed: seed, dryRun: CommandLine.arguments.contains("--dry-run"))
    try await robot.run()
} catch {
    FileHandle.standardError.write(Data("Robot failed: \(error.localizedDescription)\n".utf8))
    exit(1)
}
