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
             note: entry.wineNotes ?? wine?.note, serving: wine?.serving,
             appellationInsight: wine?.appellationInsight,
             hasNotableAppellation: wine?.hasNotableAppellation ?? false, howToServe: wine?.howToServe,
             pairings: entry.pairings ?? wine?.pairings ?? [],
             // The certification as the note was saved (CELLAR-R30): only an entry saved before it was kept falls
             // back on the catalog's.
             designation: isCertified ? entry.designation : wine?.designation,
             awards: entry.awards ?? wine?.awards ?? [])
    }

    /// The entry was saved with its certification: what it kept is the note's, even when it kept nothing.
    private var isCertified: Bool { entry.awards != nil }

    var content: WineSheetContent {
        var content = WineSheetContent(wine: paperWine, palate: palate, now: now, resources: resources.paper)
        // The "Top X%" as it was when the note was saved; a new note works it out again (CELLAR-R30).
        if let kept = entry.certificateTop {
            content.certificate = WineCertificateUIModel(wine: paperWine, keptTop: kept)
        }
        return content
    }
}
