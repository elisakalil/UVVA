import Foundation

public extension Wine {
    /// The aromas and flavours of the note one by one: "Violet, rose, iris." → Violet, rose, iris.
    var noteItems: [String] {
        note?.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        }.filter { !$0.isEmpty } ?? []
    }

    /// The wine's facts as a label gives them, to place a wine on the map as one read (CELLAR-R23a).
    var readFacts: LabelFacts {
        LabelFacts(name: name, producer: producer, vintage: vintage, type: type.isEmpty ? nil : type,
                   appellation: appellation, region: region, country: country, grapes: grapes, alcohol: alcohol,
                   notes: noteItems, pairings: pairings, serving: serving, designation: designation, awards: awards,
                   oakAging: oakAging, oakWoods: oakWoods)
    }

    /// This wine with what a label adds to it (CELLAR-R17, R30): the grapes, notes, pairings and awards it did not
    /// have yet go after its own, so every reading leaves the wine richer and none takes away what was there. What
    /// cannot be added up (the serving temperature, the alcohol, the appellation, the legal term, the time in wood) is read only when
    /// the wine has none.
    func adding(_ facts: LabelFacts) -> Wine {
        var wine = self
        wine.grapes = grapes.adding(facts.grapes)
        wine.pairings = pairings.adding(facts.pairings)
        wine = wine.addingNotes(facts.notes)
        wine.serving = serving ?? facts.serving
        wine.alcohol = alcohol ?? facts.alcohol
        wine.designation = designation ?? facts.designation
        wine.awards = awards.adding(facts.awards)
        wine.oakAging = oakAging ?? facts.oakAging
        wine.oakWoods = oakWoods.adding(facts.oakWoods)
        if let kept = CertificationKeywords.appellation(appellation, adding: facts.appellation), kept != appellation {
            wine = wine.settingAppellation(kept)
        }
        return wine
    }

    /// The classification with this appellation first: "Lisboa · 14% abv" → "Vinho Regional Lisboa · 14% abv".
    func settingAppellation(_ appellation: String) -> Wine {
        var parts = classification.components(separatedBy: " · ").filter { !$0.isEmpty }
        if self.appellation != nil, !parts.isEmpty {
            parts[0] = appellation
        } else {
            parts.insert(appellation, at: 0)
        }
        var wine = self
        wine.classification = parts.joined(separator: " · ")
        return wine
    }

    /// The note with the aromas it does not have yet; written as it was when there is nothing new.
    func addingNotes(_ notes: [String]) -> Wine {
        let items = noteItems
        let all = items.adding(notes)
        guard all.count > items.count else { return self }
        var wine = self
        wine.note = all.joined(separator: ", ")
        return wine
    }
}

public extension Array where Element == String {
    /// These values, then those of `others` they do not have yet, whatever the case ("Plum" is "plum"). Blank
    /// values are left out.
    func adding(_ others: [String]) -> [String] {
        var seen = Set<String>()
        return (self + others).compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted else { return nil }
            return trimmed
        }
    }
}
