import Foundation

/// The mock legal text of the canvas, without what no longer applies (payments, codes, reminders; ONB-R08a).
/// It will be rewritten; the final text must explain the phone and the contact key (ARCHITECTURE §4.4).
enum LegalText {
    static func sections(_ tab: LegalTab) -> [LegalSection] {
        switch tab {
        case .terms:
            [
                // TODO: say what is free and what is not once the app has limits.
                LegalSection(title: String(localized: "The service", bundle: .module),
                             body: String(localized: "UVVA gives you wine lessons, a map of your palate and a place to keep tasting notes.", bundle: .module)),
                LegalSection(title: String(localized: "Your account", bundle: .module),
                             body: String(localized: "One account per person, signed in with Apple or Google. Anything done from your account is your responsibility.", bundle: .module)),
                LegalSection(title: String(localized: "Content", bundle: .module),
                             body: String(localized: "Lessons, illustrations and texts belong to UVVA. Your tasting notes belong to you. Do not redistribute the lessons.", bundle: .module)),
                LegalSection(title: String(localized: "Changes", bundle: .module),
                             body: String(localized: "We may update these terms. If a change is material, we tell you in the app before it takes effect.", bundle: .module))
            ]
        case .privacy:
            [
                LegalSection(title: String(localized: "What we collect", bundle: .module),
                             body: String(localized: "Your first name, your phone number if you add it, your palate map, the lessons you open and the tasting notes you write. Nothing else.", bundle: .module)),
                // TODO: say where the data lives once storage for Google accounts is decided (and recheck "no servers of our own").
                LegalSection(title: String(localized: "Where it lives", bundle: .module),
                             body: String(localized: "Stored with your account. Your name and, if you choose, your map are public to the people you add as friends.", bundle: .module)),
                LegalSection(title: String(localized: "Your phone", bundle: .module),
                             body: String(localized: "If you add your number, we publish a code made from it, never the number itself, so friends who have you in their contacts can find you. Anyone who knows your number can tell that it is on UVVA.", bundle: .module)),
                LegalSection(title: String(localized: "Sharing", bundle: .module),
                             body: String(localized: "We do not sell your data and we have no servers of our own.", bundle: .module))
            ]
        }
    }
}
