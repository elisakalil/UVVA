import Core
import Foundation

/// "Fill in by hand" (CELLAR-R23): the name, producer, vintage and alcohol typed; everything else chosen from the
/// catalog's lists, so nothing made up reaches the map (CELLAR-R23a).
struct NewNoteManualForm: Equatable {
    var name = ""
    var producer = ""
    var vintage = ""
    /// % vol, as typed: "13,5" or "13.5".
    var alcohol = ""
    /// Red, White, Rosé, Sparkling or Fortified; nil when not chosen.
    var type: String?
    var region: String?
    var appellation: String?
    var designation: String?
    var grapes: [String] = []
    var notes: [String] = []
    var oakAging: OakAging?
    var oakWoods: [String] = []
    var awards: [WineAward] = []
    /// The latest vintage a wine can have.
    var currentYear = Calendar(identifier: .gregorian).component(.year, from: Date())

    /// The oldest vintage, as for a label (`LabelParser.earliestVintage`).
    static let earliestVintage = 1900

    init() {}

    /// Filled with what the label reading found, for the person to check (decision L2).
    init(_ facts: LabelFacts) {
        name = facts.name ?? ""
        producer = facts.producer ?? ""
        vintage = facts.vintage.map(String.init) ?? ""
        alcohol = facts.alcohol.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? ""
        type = facts.type
        region = facts.region
        appellation = facts.appellation
        designation = facts.designation
        grapes = facts.grapes
        notes = facts.notes
        oakAging = facts.oakAging
        oakWoods = facts.oakWoods
        awards = facts.awards
    }

    subscript(field: NewNoteField) -> String {
        get {
            switch field {
            case .name: name
            case .producer: producer
            case .vintage: vintage
            case .alcohol: alcohol
            }
        }
        set {
            switch field {
            case .name: name = newValue
            case .producer: producer = newValue
            case .vintage: vintage = String(newValue.filter(\.isNumber).prefix(4))
            case .alcohol: alcohol = String(newValue.filter { $0.isNumber || $0 == "," || $0 == "." }.prefix(5))
            }
        }
    }

    // MARK: Chips

    func chips(_ field: NewNoteManualChipField) -> [String] {
        switch field {
        case .region: [region].compactMap { $0 }
        case .appellation: [appellation].compactMap { $0 }
        case .designation: [designation].compactMap { $0 }
        case .grapes: grapes
        case .notes: notes
        case .oakWoods: oakWoods
        }
    }

    /// The values chosen from a list: one replaces the other in a single-choice field, many add up.
    mutating func choose(_ values: [String], for field: NewNoteManualChipField) {
        switch field {
        case .region: region = values.last ?? region
        case .appellation: appellation = values.last ?? appellation
        case .designation: designation = values.last ?? designation
        case .grapes: grapes = grapes.adding(values)
        case .notes: notes = notes.adding(values)
        case .oakWoods: oakWoods = oakWoods.adding(values)
        }
    }

    mutating func remove(_ value: String, from field: NewNoteManualChipField) {
        switch field {
        case .region: region = nil
        case .appellation: appellation = nil
        case .designation: designation = nil
        case .grapes: grapes.removeAll { $0 == value }
        case .notes: notes.removeAll { $0 == value }
        case .oakWoods: oakWoods.removeAll { $0 == value }
        }
    }

    /// Tapping the chosen time again clears it; without wood there are no woods.
    mutating func pick(_ aging: OakAging) {
        oakAging = oakAging == aging ? nil : aging
        if oakAging == OakAging.none { oakWoods = [] }
    }

    mutating func add(_ award: WineAward) { awards = awards.adding([award]) }

    mutating func remove(_ award: WineAward) { awards.removeAll { $0 == award } }

    // MARK: What it takes to continue (CELLAR-R23, R23a)

    var vintageValue: Int? { Int(trimmed(vintage)) }

    var alcoholValue: Double? { Double(trimmed(alcohol).replacingOccurrences(of: ",", with: ".")) }

    /// Empty, or a year from 1900 to this one.
    var isVintageValid: Bool {
        trimmed(vintage).isEmpty || vintageValue.map { (Self.earliestVintage...currentYear).contains($0) } == true
    }

    /// Empty, or the strength of a wine (`WineEvidence.wineStrength`).
    var isAlcoholValid: Bool {
        trimmed(alcohol).isEmpty || alcoholValue.map(WineEvidence.wineStrength.contains) == true
    }

    /// The type and at least one thing the catalog knows to draw the map from.
    var hasMapBasis: Bool {
        type != nil && (!grapes.isEmpty || region != nil || appellation != nil || !notes.isEmpty || oakAging != nil)
    }

    /// "Continue" needs a name, a plausible vintage and alcohol, and a base for the map.
    var canContinue: Bool { !trimmed(name).isEmpty && isVintageValid && isAlcoholValid && hasMapBasis }

    var isEmpty: Bool { self == NewNoteManualForm() }

    var facts: LabelFacts {
        LabelFacts(name: nonEmpty(name), producer: nonEmpty(producer), vintage: vintageValue, type: type,
                   appellation: appellation, region: region, grapes: grapes, alcohol: alcoholValue, notes: notes,
                   designation: designation, awards: awards, oakAging: oakAging, oakWoods: oakWoods)
    }

    private func trimmed(_ text: String) -> String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func nonEmpty(_ text: String) -> String? { trimmed(text).isEmpty ? nil : trimmed(text) }
}
