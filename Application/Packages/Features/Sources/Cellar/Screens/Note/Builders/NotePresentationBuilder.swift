import CoreUI
import Core
import Foundation

/// What a saved note shows (CELLAR-R26): the wine as the Home's wine sheet shows it, with the photos and the note.
/// Pure: the entry, the catalog wine and the user's map in, the UI model's parts out.
struct NotePresentationBuilder {
    var entry: CellarEntry
    var wine: Wine?
    var palate: PalateMap?
    var resources = NoteResourcesUIModel()
    var dateStyle = Date.FormatStyle().day().month(.abbreviated)
    var now = Date()

    var date: String { entry.createdAt.formatted(dateStyle) }

    var again: String { resources.verdict(CellarTag(entry)) }

    var coverTag: String? { entry.verdict == nil ? nil : again }

    /// The entry's own copy of the wine first, the catalog's behind it: how to serve it lives only there.
    var paperWine: Wine {
        Wine(id: entry.id, name: entry.name, producer: entry.producer, vintage: entry.vintage, type: entry.type,
             origin: entry.origin, region: entry.region, country: entry.country,
             grapes: entry.grapes.isEmpty ? wine?.grapes ?? [] : entry.grapes, alcohol: entry.alcohol ?? wine?.alcohol,
             classification: entry.classification, profile: entry.wineProfile ?? wine?.profile ?? PalateMap([:]),
             note: entry.wineNotes ?? wine?.note, serving: wine?.serving, howToServe: wine?.howToServe,
             pairings: entry.pairings ?? wine?.pairings ?? [])
    }

    var content: WineSheetContent {
        WineSheetContent(wine: paperWine, palate: palate, now: now, resources: resources.paper)
    }
}
