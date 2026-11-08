import Core
import Foundation

/// "Fill in by hand" (CELLAR-R23): what can be read on the label, as typed. Only the name is needed.
struct NewNoteManualForm: Equatable {
    var name = ""
    var producer = ""
    var vintage = ""
    var region = ""
    /// One or more grapes, separated by commas.
    var grape = ""
    /// Red, White, Rosé, Sparkling or Fortified; nil when not chosen.
    var type: String?

    init() {}

    /// Filled with what the label reading found, for the person to check (decision L2).
    init(_ facts: LabelFacts) {
        name = facts.name ?? ""
        producer = facts.producer ?? ""
        vintage = facts.vintage.map(String.init) ?? ""
        region = facts.region ?? facts.appellation ?? ""
        grape = facts.grapes.joined(separator: ", ")
        type = facts.type
    }

    subscript(field: NewNoteField) -> String {
        get {
            switch field {
            case .name: name
            case .producer: producer
            case .region: region
            case .vintage: vintage
            case .grape: grape
            }
        }
        set {
            switch field {
            case .name: name = newValue
            case .producer: producer = newValue
            case .region: region = newValue
            case .vintage: vintage = String(newValue.filter(\.isNumber).prefix(4))
            case .grape: grape = newValue
            }
        }
    }

    /// "Continue" is on as soon as there is a name.
    var canContinue: Bool { !trimmed(name).isEmpty }

    var isEmpty: Bool { self == NewNoteManualForm() }

    var facts: LabelFacts {
        LabelFacts(name: nonEmpty(name), producer: nonEmpty(producer), vintage: Int(trimmed(vintage)),
                   type: type, region: nonEmpty(region),
                   grapes: grape.split(separator: ",").map { trimmed(String($0)) }.filter { !$0.isEmpty })
    }

    private func trimmed(_ text: String) -> String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func nonEmpty(_ text: String) -> String? { trimmed(text).isEmpty ? nil : trimmed(text) }
}
