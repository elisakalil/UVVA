import Foundation

/// One fact under the cover: "Grape", "Syrah & Viognier".
struct NoteFactUIModel: Identifiable, Equatable {
    var label: String
    var value: String
    var id: String { label }
}
