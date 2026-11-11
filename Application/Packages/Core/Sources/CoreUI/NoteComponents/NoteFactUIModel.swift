import Foundation

/// One fact under the cover: "Grape", "Syrah & Viognier".
public struct NoteFactUIModel: Identifiable, Equatable {
    public var label: String
    public var value: String
    public var id: String { label }
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }

}
