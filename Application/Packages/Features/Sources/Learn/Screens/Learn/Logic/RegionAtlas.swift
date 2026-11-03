import Foundation

/// The maps of By region (LEARN-R06): country outlines from Natural Earth (world-atlas, public domain) and the
/// true coordinates of each region course. Built by `Data/Learn/_src/map/build_map.py`.
struct RegionAtlas: Decodable {
    var countries: [CountryShape]
    /// Course id → `[lon, lat]`.
    var regions: [String: [Double]]
    /// Regions far off the mainland, drawn in a corner of the map.
    var insets: [String]

    static let shared: RegionAtlas = {
        guard let url = Bundle.module.url(forResource: "RegionMaps", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let atlas = try? JSONDecoder().decode(RegionAtlas.self, from: data) else {
            return RegionAtlas(countries: [], regions: [:], insets: [])
        }
        return atlas
    }()

    func country(_ name: String) -> CountryShape? {
        countries.first { $0.name == name }
    }
}
