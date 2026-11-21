import Core
import Foundation

/// Turns the entries, the filters and the search into what the Cellar shows. Pure: no state, no storage.
struct CellarPresentationBuilder {
    var entries: [CellarEntry]
    var filters: [CellarFacet: String]
    var openFacet: CellarFacet?
    var query: String
    /// False until the entries are read for the first time.
    var isLoaded = true
    /// The user's map, for the match of each wine; nil before the Quiz.
    var palate: PalateMap? = nil
    var resources = CellarResourcesUIModel()
    var dateStyle = Date.FormatStyle().day().month(.abbreviated)

    /// The entries every filter lets through (CELLAR-R10): within a filter the one value picked, across filters all of them.
    var filtered: [CellarEntry] { entries.filter { matches($0) } }

    var state: CellarListState {
        if !isLoaded { return .idle }
        if entries.isEmpty { return .empty }
        return filtered.isEmpty ? .noMatches : .items
    }

    /// The order of `entries` is kept: newest first (CELLAR-R02).
    var items: [CellarItemUIModel] {
        filtered.enumerated().map { index, entry in
            let tag = resources.tag(CellarTag(entry))
            let vintage = entry.vintage.map(String.init) ?? ""
            let match = CellarMatch.percent(entry, palate: palate).map(resources.match) ?? ""
            let place = [entry.region, entry.country].compactMap { $0 }.first { !$0.isEmpty } ?? ""
            return CellarItemUIModel(
                id: entry.id, name: entry.name, vintage: vintage, match: match, place: place,
                tag: tag, photo: entry.photoFront, updatedAt: entry.updatedAt,
                cover: .at(index),
                accessibilityLabel: [entry.name, vintage, match, place, tag].filter { !$0.isEmpty }.joined(separator: ", ")
            )
        }
    }

    var chips: [CellarChipUIModel] {
        // Without a map there is nothing to match against: the Match filter waits for the Quiz.
        CellarFacet.allCases.filter { $0 != .match || palate != nil }.map { facet in
            CellarChipUIModel(facet: facet, label: filters[facet] ?? resources.facet(facet), isActive: filters[facet] != nil)
        }
    }

    var filterSheet: CellarFilterSheetUIModel? {
        guard let facet = openFacet else { return nil }
        // Each value counts the bottles it would show with the other filters as they are.
        let others = entries.filter { matches($0, skipping: facet) }
        var counts: [String: Int] = [:]
        for entry in others {
            for value in Set(facet.values(of: entry, palate: palate, resources: resources)) { counts[value, default: 0] += 1 }
        }
        // The other filters show only what the user's entries have.
        let present = Set(entries.flatMap { facet.values(of: $0, palate: palate, resources: resources) })
        let values: [String] = switch facet {
        // Tag always shows its four values, in their own order.
        case .tag: CellarTag.allCases.map(resources.tag)
        // Match shows its bands closest first, those no bottle has faded.
        case .match: CellarMatch.Band.allCases.map(resources.matchBand)
        // Vintages run newest first.
        case .vintage: present.sorted { $0.localizedStandardCompare($1) == .orderedDescending }
        default: present.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
        let options = values.map { value in
            let count = counts[value] ?? 0
            return CellarFilterOptionUIModel(value: value, count: String(count),
                                             isSelected: filters[facet] == value, isDimmed: count == 0)
        }
        return CellarFilterSheetUIModel(facet: facet, title: resources.facet(facet), options: options,
                                        showText: resources.showBottles(filtered.count), anyText: resources.anyValue(facet))
    }

    var isSearching: Bool { !CellarSearchText.fold(query).isEmpty }

    var searchResults: [CellarSearchResultUIModel] {
        guard isSearching else { return [] }
        return entries.filter { CellarSearchText.matches($0, query: query) }.map { entry in
            CellarSearchResultUIModel(
                id: entry.id,
                title: [entry.name, entry.vintage.map(String.init)].compactMap { $0 }.joined(separator: " "),
                meta: [entry.region, grapes(entry), entry.createdAt.formatted(dateStyle)]
                    .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "),
                tag: resources.tag(CellarTag(entry))
            )
        }
    }

    private func matches(_ entry: CellarEntry, skipping skipped: CellarFacet? = nil) -> Bool {
        filters.allSatisfy { facet, value in
            facet == skipped || facet.values(of: entry, palate: palate, resources: resources).contains(value)
        }
    }

    private func grapes(_ entry: CellarEntry) -> String? {
        entry.grapes.isEmpty ? nil : entry.grapes.joined(separator: " & ")
    }
}
