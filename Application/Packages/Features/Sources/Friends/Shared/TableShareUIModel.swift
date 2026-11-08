import Foundation

/// Sharing a table (FRI-R21, R22): the invite on WhatsApp, "Tonight's table" as a Story, and the shopping guide
/// that Save image keeps.
struct TableShareUIModel: Equatable {
    var title: String
    /// "Marina & Elisa", "Marina, Bia & Elisa".
    var namesText: String
    /// The WhatsApp message: the invite, the names, the menu, the line and the link.
    var message: String
    var link: URL
    var courses: [TableShareCourseUIModel]
    var invitedText: String
    var tonightText: String
    var guideText: String
    var footerText: String
}
