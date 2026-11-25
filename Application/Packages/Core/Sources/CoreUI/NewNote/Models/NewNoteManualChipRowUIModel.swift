import Core
import Foundation

/// One list field of "Fill in by hand" (CELLAR-R23): its label and what was chosen, each as it reads.
struct NewNoteManualChipRowUIModel: Identifiable, Equatable {
    var field: NewNoteManualChipField
    var label: String
    var chips: [NewNoteManualChipUIModel]
    var addLabel: String

    var id: NewNoteManualChipField { field }
}

/// A value chosen in a list field: as stored, and as shown.
struct NewNoteManualChipUIModel: Identifiable, Equatable {
    var value: String
    var label: String

    var id: String { value }
}

/// One time in wood to choose (CELLAR-R23).
struct NewNoteOakUIModel: Identifiable, Equatable {
    var aging: OakAging
    var label: String
    var isSelected: Bool

    var id: OakAging { aging }
}

/// One award chosen, as it reads: "Ouro · Decanter World Wine Awards · 2023".
struct NewNoteAwardUIModel: Identifiable, Equatable {
    var award: WineAward
    var label: String

    var id: String { award.text }
}
