import Core
import Foundation

/// "Set the perfect dinner" (FRI-R13a): the choices, as chips, and the button that sets the table.
struct DinnerUIModel: Equatable {
    struct Option<Value: Equatable>: Identifiable, Equatable {
        var value: Value
        var title: String
        var isOn: Bool
        var id: String { title }
    }

    var courses: [Option<TableCourse>] = []
    var food: [Option<DinnerPreferences.Food>] = []
    /// "In season · Autumn".
    var season = Option(value: false, title: "", isOn: false)
    var time: [Option<DinnerPreferences.Time>] = []
    /// "Set the perfect dinner", or "Set it again" once the choices changed after the table was set.
    var buttonTitle = ""
}
