import CoreGraphics
import Foundation

/// The world map of You › Progress: the coastlines of the land from Natural Earth (world-atlas, public domain), the
/// middle of each country and the true places of the wine regions. Built by `Data/Learn/_src/map/build_world.py`.
public struct WorldAtlas: Sendable {
    /// `[minLon, minLat, maxLon, maxLat]`: the frame the map is fitted to.
    public let box: [Double]
    /// Rings of the land, flat `[lon, lat, lon, lat, ...]`; the lakes are rings too, drawn even-odd.
    public let land: [[Double]]
    private let countries: [String: [Double]]
    private let places: [String: [Double]]
    private let placesByName: [String: [Double]]

    public static let shared: WorldAtlas = {
        guard let url = Bundle.module.url(forResource: "WorldMap", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            return WorldAtlas(file: File(box: [-168, -56, 180, 76], land: [], countries: [:], places: []))
        }
        return WorldAtlas(file: file)
    }()

    private init(file: File) {
        box = file.box
        land = file.land
        countries = Dictionary(file.countries.map { (Self.key($0.key), $0.value) }, uniquingKeysWith: { first, _ in first })
        places = Dictionary(file.places.map { (Self.key($0.name, $0.country), $0.at) }, uniquingKeysWith: { first, _ in first })
        // A region name alone, for a wine whose country is missing; a name two countries share is left out.
        let byName = Dictionary(grouping: file.places, by: { Self.key($0.name) })
        placesByName = byName.compactMapValues { $0.count == 1 ? $0[0].at : nil }
    }

    /// Where a wine from `region`, `country` sits: its region when it is listed, else the middle of its country.
    public func coordinate(region: String?, country: String?) -> (lon: Double, lat: Double)? {
        let region = region?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let country = country?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let found: [Double]? = {
            if !region.isEmpty, !country.isEmpty, let place = places[Self.key(region, country)] { return place }
            if !region.isEmpty, country.isEmpty, let place = placesByName[Self.key(region)] { return place }
            if !country.isEmpty, let middle = countries[Self.key(country)] { return middle }
            return nil
        }()
        guard let found, found.count == 2 else { return nil }
        return (found[0], found[1])
    }

    /// Case, accents and punctuation do not count: "Dão" is "dao", "Hawke's Bay" is "hawkesbay".
    static func key(_ parts: String...) -> String {
        parts.map { part in
            part.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
                .unicodeScalars.filter(CharacterSet.alphanumerics.contains).map(String.init).joined()
        }.joined(separator: "|")
    }

    private struct File: Decodable {
        var box: [Double]
        var land: [[Double]]
        var countries: [String: [Double]]
        var places: [Place]
    }

    private struct Place: Decodable {
        var name: String
        var country: String
        var at: [Double]
    }
}

/// Miller cylindrical fitted to a lon/lat frame inside a size: the whole world without Mercator's swollen north.
public struct WorldProjection {
    private let scale: Double
    private let origin: (x: Double, y: Double)
    private let offset: CGPoint

    public init(box: [Double], size: CGSize) {
        let low = Self.miller(lon: box[0], lat: box[1])
        let high = Self.miller(lon: box[2], lat: box[3])
        scale = min(Double(size.width) / max(high.x - low.x, .ulpOfOne),
                    Double(size.height) / max(high.y - low.y, .ulpOfOne))
        origin = (low.x, high.y)
        offset = CGPoint(x: (Double(size.width) - (high.x - low.x) * scale) / 2,
                         y: (Double(size.height) - (high.y - low.y) * scale) / 2)
    }

    public func point(lon: Double, lat: Double) -> CGPoint {
        let m = Self.miller(lon: lon, lat: lat)
        return CGPoint(x: offset.x + (m.x - origin.x) * scale, y: offset.y + (origin.y - m.y) * scale)
    }

    /// Every ring in one path, so the lakes come out of the land when it is filled even-odd.
    public func path(_ rings: [[Double]]) -> CGPath {
        let path = CGMutablePath()
        for ring in rings {
            for index in stride(from: 0, to: ring.count - 1, by: 2) {
                let p = point(lon: ring[index], lat: ring[index + 1])
                if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
        return path
    }

    /// Width over height of the frame.
    public static func aspectRatio(box: [Double]) -> Double {
        let low = miller(lon: box[0], lat: box[1])
        let high = miller(lon: box[2], lat: box[3])
        return (high.x - low.x) / max(high.y - low.y, .ulpOfOne)
    }

    private static func miller(lon: Double, lat: Double) -> (x: Double, y: Double) {
        let phi = min(max(lat, -89), 89) * .pi / 180
        return (lon * .pi / 180, 1.25 * log(tan(.pi / 4 + 0.4 * phi)))
    }
}
