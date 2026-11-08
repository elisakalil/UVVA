import Core
import Foundation

/// FRI-R21, R22: the words and the link of a shared table, from who sits at it and its bottles.
struct TableShareBuilder {
    var friendNames: [String]
    var userName: String
    var bottles: [TableBottle]
    var resources: TableResourcesUIModel

    func build() -> TableShareUIModel {
        let courses = bottles.map { bottle in
            TableShareCourseUIModel(courseText: resources.course(bottle.course),
                                    wineText: Self.wine(bottle.wine),
                                    askForText: resources.askFor(Self.askFor(bottle.wine)),
                                    dishText: bottle.recipe.title)
        }
        let names = namesText
        let menu = courses.map { resources.menuLine($0.courseText, $0.wineText, $0.dishText) }.joined(separator: "\n")
        let line = friendNames.count == 1 ? resources.bothLine : resources.allLine
        let message = [resources.invitedText, names, "", menu, "", line, link.absoluteString].joined(separator: "\n")
        return TableShareUIModel(title: resources.shareTitleText, namesText: names, message: message, link: link,
                                 courses: courses, invitedText: resources.invitedText, tonightText: resources.tonightText,
                                 guideText: resources.guideText, footerText: resources.shareFooterText)
    }

    /// "Marina & Elisa"; "Marina, Bia & Elisa": the friends, then the user.
    var namesText: String {
        let names = friendNames + [userName]
        return names.dropLast().joined(separator: ", ") + " & " + names[names.count - 1]
    }

    /// `uvva.app/t/marina-elisa`.
    var link: URL {
        URL(string: "https://uvva.app/t/\(Self.slug(friendNames + [userName]))")!
    }

    /// Lower case, no accents, every run of other characters a single `-`.
    static func slug(_ names: [String]) -> String {
        let folded = names.joined(separator: " ").folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .init(identifier: "en"))
        return folded.lowercased()
            .split { !($0.isASCII && ($0.isLetter || $0.isNumber)) }
            .joined(separator: "-")
    }

    /// "Alvarinho, Soalheiro".
    static func wine(_ wine: Wine) -> String {
        wine.producer.isEmpty ? wine.name : "\(wine.name), \(wine.producer)"
    }

    /// "Soalheiro Alvarinho 2022": what is written on the label, for the shop.
    static func askFor(_ wine: Wine) -> String {
        [wine.producer, wine.name, wine.vintage.map(String.init)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
