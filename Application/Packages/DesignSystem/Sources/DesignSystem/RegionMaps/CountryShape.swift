import Foundation

/// One country of By region as its map draws it: its outline, the land around it, and the frame the map
/// is fitted to. Rings are flat `[lon, lat, lon, lat, ...]`.
public struct CountryShape: Decodable, Equatable, Sendable {
    public var name: String
    /// `[minLon, minLat, maxLon, maxLat]`
    public var box: [Double]
    public var land: [[Double]]
    /// Complete mainland and nearby islands for Home, independent of Learn's regional crop.
    public var thumbnailLand: [[Double]]?
    public var near: [[Double]]
}
