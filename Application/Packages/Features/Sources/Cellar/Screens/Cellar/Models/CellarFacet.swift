import Core
import Foundation

/// The six filters above the Cellar (CELLAR-R10).
public enum CellarFacet: String, CaseIterable, Identifiable, Sendable {
    case tag, type, grape, region, producer, vintage

    public var id: String { rawValue }

    /// The values an entry has for this filter. A blend has one per grape; a missing fact has none.
    func values(of entry: CellarEntry, resources: CellarResourcesUIModel) -> [String] {
        switch self {
        case .tag: [resources.tag(CellarTag(entry))]
        case .type: entry.type.isEmpty ? [] : [entry.type]
        case .grape: entry.grapes
        case .region: entry.region.map { [$0] } ?? []
        case .producer: entry.producer.isEmpty ? [] : [entry.producer]
        case .vintage: entry.vintage.map { [String($0)] } ?? []
        }
    }
}
