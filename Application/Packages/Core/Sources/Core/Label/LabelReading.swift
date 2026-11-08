import Foundation

/// Reads the text of the two label photos on the phone (CELLAR-R17), implemented by the app with Vision.
public protocol LabelReading: Sendable {
    func read(front: Data, back: Data) async throws -> LabelText
}
