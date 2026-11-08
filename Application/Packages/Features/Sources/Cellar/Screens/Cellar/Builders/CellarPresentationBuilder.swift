import Core
import Foundation

/// Turns the entries, the filters and the search into what the Cellar shows. Pure: no state, no storage.
struct CellarPresentationBuilder {
    var entries: [CellarEntry]
    var filters: [CellarFacet: String]
    var openFacet: CellarFacet?
    var query: String
    var resources = CellarResourcesUIModel()
    var dateStyle = Date.FormatStyle().day().month(.abbreviated)

    /// The entries every filter lets through (CELLAR-R10): within a filter the one value picked, across filters all of them.
    var filtered: [CellarEntry] { entries.filter { matches($0) } }

    var state: CellarListState {
        if entries.isEmpty { return .empty }
        return filtered.isEmpty ? .noMatches : .items
    }

    /// The order of `entries` is kept: newest first (CELLAR-R02).
    var items: [CellarItemUIModel] {
        filtered.enumerated().map { index, entry in
            let tag = resources.tag(CellarTag(entry))
            let vintage = entry.vintage.map(String.init) ?? ""
            return CellarItemUIModel(
                id: entry.id, name: entry.name, vintage: vintage,
                meta: [entry.region, entry.country, grapes(entry)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "),
                tag: tag, isNotYet: CellarTag(entry) == .notYet, photo: entry.photoFront,
                cover: .at(index),
                accessibilityLabel: [entry.name, vintage, tag].filter { !$0.isEmpty }.joined(separator: ", ")
            )
        }
    }

    var chips: [CellarChipUIModel] {
        CellarFacet.allCases.map { facet in
            CellarChipUIModel(facet: facet, label: filters[facet] ?? resources.facet(facet), isActive: filters[facet] != nil)
        }
    }

    var filterSheet: CellarFilterSheetUIModel? {
        guard let facet = openFacet else { return nil }
        // Each value counts the bottles it would show with the other filters as they are.
        let others = entries.filter { matches($0, skipping: facet) }
        var counts: [String: Int] = [:]
        for entry in others {
            for value in Set(facet.values(of: entry, resources: resources)) { counts[value, default: 0] += 1 }
        }
        let values: [String] = facet == .tag
            // Tag always shows its four values, in their own order.
            ? CellarTag.allCases.map(resources.tag)
            // The other filters show only what the user's entries have.
            : Set(entries.flatMap { facet.values(of: $0, resources: resources) })
                .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
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
        entries.filter { CellarSearchText.matches($0, query: query) }.map { entry in
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
            facet == skipped || facet.values(of: entry, resources: resources).contains(value)
        }
    }

    private func grapes(_ entry: CellarEntry) -> String? {
        entry.grapes.isEmpty ? nil : entry.grapes.joined(separator: " & ")
    }
}
