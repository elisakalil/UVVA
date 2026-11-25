import Foundation

/// Reads the text of a photo of a wine list on the phone (WINELIST-R03), implemented by the app with Vision.
public protocol WineListReading: Sendable {
    func read(_ photo: Data) async throws -> [WineListLine]
}
