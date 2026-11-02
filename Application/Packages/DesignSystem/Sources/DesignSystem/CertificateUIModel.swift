import Foundation

/// What a course certificate shows (LEARN-R23), ready to draw in Learn and in You › Certificates.
public struct CertificateUIModel: Equatable, Sendable {
    /// "24 Sep 2026"
    public var date: String
    /// "Grape", "Region" or "Module".
    public var kind: String
    /// "Elisa now knows"
    public var lead: String
    public var title: String
    public var about: String
    /// "What I can do now": three lines.
    public var skills: [String]
    /// "+75 XP"
    public var xp: String
    /// Sent with the picture on WhatsApp.
    public var message: String

    public init(date: String, kind: String, lead: String, title: String, about: String, skills: [String], xp: String,
                message: String) {
        self.date = date
        self.kind = kind
        self.lead = lead
        self.title = title
        self.about = about
        self.skills = skills
        self.xp = xp
        self.message = message
    }
}
