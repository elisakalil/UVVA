import Foundation

/// A label reading as the camera gave it, before anything was put together (CELLAR-R17): the front photo's lines, the
/// back photo's and every frame of the back label's scan. Debug builds export it, so a real bottle can be replayed in
/// a test and every change to the scan measured on it.
public struct LabelScanExport: Codable, Equatable, Sendable {
    public var front: [LabelLine]
    public var backPhoto: [LabelLine]
    public var frames: [[LabelLine]]

    public init(front: [LabelLine], backPhoto: [LabelLine], frames: [[LabelLine]]) {
        self.front = front
        self.backPhoto = backPhoto
        self.frames = frames
    }

    /// The label's text as the reading puts it together: the scan's frames, then the back photo as one frame more.
    public var text: LabelText {
        guard !frames.isEmpty else { return LabelText(front + backPhoto) }
        var scan = LabelScan()
        for frame in frames { scan.add(frame) }
        scan.add(backPhoto)
        return LabelText(front + scan.lines(side: .back))
    }

    public var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(self)).map { String(decoding: $0, as: UTF8.self) } ?? "{}"
    }

    public init(json: String) throws {
        self = try JSONDecoder().decode(Self.self, from: Data(json.utf8))
    }
}
