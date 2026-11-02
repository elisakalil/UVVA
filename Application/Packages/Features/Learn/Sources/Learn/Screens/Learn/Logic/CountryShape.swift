import Foundation

/// One country of By region as its map draws it: its outline, the land around it, and the frame the map
/// is fitted to. Rings are flat `[lon, lat, lon, lat, ...]`.
struct CountryShape: Decodable, Equatable {
    var name: String
    /// `[minLon, minLat, maxLon, maxLat]`
    var box: [Double]
    var land: [[Double]]
    var near: [[Double]]
}
