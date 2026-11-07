import Core
import Foundation

enum GrapeNames {
    static func matches(_ grape: Course, in region: Course) -> Bool {
        let names = Set(region.grapes.map(key))
        return ([grape.title] + grape.aliases).contains { names.contains(key($0)) }
    }

    private static func key(_ name: String) -> String {
        name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
