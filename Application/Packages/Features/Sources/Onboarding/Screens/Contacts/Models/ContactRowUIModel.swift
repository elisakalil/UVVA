import Foundation

struct ContactRowUIModel: Equatable, Identifiable {
    var id: String
    var name: String
    var initials: String
    /// The palate in a line, for contacts on UVVA ("ACIDITY · FRUIT · BODY").
    var note: String?
    var letter: String
    var state: ContactRowState
    /// The number the invite goes to by SMS: the contact's first.
    var phone: String? = nil
}
