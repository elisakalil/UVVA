import Core
import DesignSystem
import Foundation

/// Pins the regions of finished courses at their true places, and the tasted wines at their region, or at the middle
/// of their country when the region is not on record. Wines from one place share a pin.
struct ProgressMapBuilder {
    var atlas = WorldAtlas.shared
    var regionCoordinates = RegionAtlas.shared.regions

    func build(regions: [Certificate], content: YouContentModel) -> ProgressMapUIModel {
        ProgressMapUIModel(pins: regionPins(regions, content: content) + bottlePins(content.tasted))
    }

    private func regionPins(_ certificates: [Certificate], content: YouContentModel) -> [ProgressMapPin] {
        certificates.compactMap { certificate in
            let course = content.certificateCourses[certificate.courseID]
            let at: (lon: Double, lat: Double)? = {
                if let known = regionCoordinates[certificate.courseID], known.count == 2 { return (known[0], known[1]) }
                return atlas.coordinate(region: course?.title, country: course?.countries.first)
            }()
            guard let at else { return nil }
            return ProgressMapPin(id: certificate.courseID, kind: .region, lon: at.lon, lat: at.lat,
                                  name: course?.title ?? certificate.courseID)
        }
        .sorted { $0.id < $1.id }
    }

    private func bottlePins(_ tasted: [CellarEntry]) -> [ProgressMapPin] {
        var pins: [String: ProgressMapPin] = [:]
        for entry in tasted {
            guard let at = atlas.coordinate(region: entry.region, country: entry.country) else { continue }
            let id = "\(at.lon),\(at.lat)"
            if pins[id] != nil {
                pins[id]?.count += 1
            } else {
                let name = [entry.region, entry.country].compactMap { $0 }.filter { !$0.isEmpty }.first ?? entry.name
                pins[id] = ProgressMapPin(id: id, kind: .bottle, lon: at.lon, lat: at.lat, name: name)
            }
        }
        return pins.values.sorted { $0.id < $1.id }
    }
}
