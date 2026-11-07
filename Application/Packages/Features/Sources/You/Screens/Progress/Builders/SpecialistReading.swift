import Core
import Foundation

struct SpecialistReading {
    func text(completed: [Course], regionCatalog: [Course]) -> String {
        let ordered = completed.sorted { $0.id < $1.id }
        let grapes = ordered.filter { $0.kind == .grape }
        let regions = ordered.filter { $0.kind == .region }
        let path = ordered.filter { $0.kind == .path }
        let level = Level.allCases.last { level in path.contains { $0.level == level.rawValue } }

        if let story = geography(grapes: grapes, regions: regions, regionCatalog: regionCatalog) {
            return [story, level?.geographyLine].compactMap { $0 }.joined(separator: " ")
        }
        if let level {
            return level.pathStory
        }
        if let module = path.last {
            return String(localized: "Your journey through wine has a first landmark in \(module.title).", bundle: .module)
        }
        return String(localized: "Every wine story begins somewhere. Finish your first course and see where yours takes you.", bundle: .module)
    }

    private func geography(grapes: [Course], regions: [Course], regionCatalog: [Course]) -> String? {
        let studied = matches(regions: regions, grapes: grapes)
        // A grape studied on both sides of a border connects two places the learner already knows.
        for grape in grapes {
            let linked = studied.filter { $0.grapes.contains(grape) }.map(\.region)
            if Set(linked.flatMap(\.countries)).count > 1 {
                let places = names(linked)
                return String(localized: "You know \(places) well enough to follow \(grape.title) across borders. The same grape gives you a way to read each place.", bundle: .module)
            }
        }
        if let link = uniqueLeader(studied) {
            let place = link.region.title
            let varieties = names(link.grapes)
            if alternate(for: link.region.id) {
                return String(localized: "You know \(place) from the ground up. Follow \(varieties) and the landscape begins to make sense in the glass.", bundle: .module)
            }
            return String(localized: "You know \(place) from its vineyards down to the grape. With \(varieties) as your guide, you can follow a thread from the landscape into the glass.", bundle: .module)
        }
        if regions.count > 1 {
            let places = names(regions)
            if Set(regions.flatMap(\.countries)).count > 1 {
                return String(localized: "From \(places), you’re getting to know wine through the places that make it. Your map already crosses borders.", bundle: .module)
            }
            return String(localized: "You know \(places), different corners of the same wine country. Your studies give you a way to read the differences from one vineyard to the next.", bundle: .module)
        }
        if let region = regions.first {
            if let grape = grapes.first {
                return String(localized: "You’re getting to know \(region.title) through its vineyards. Your studies also follow \(grape.title), another thread to pull as your map grows.", bundle: .module)
            }
            return String(localized: "You’re getting to know \(region.title), where the story in the glass begins in the vineyard.", bundle: .module)
        }
        if let link = uniqueLeader(matches(regions: regionCatalog, grapes: grapes)), link.grapes.count >= 2 {
            let varieties = names(link.grapes)
            if alternate(for: link.region.id) {
                return String(localized: "You’re getting to know \(link.region.title) through its grapes. \(varieties) are voices in a blend you’re learning to hear.", bundle: .module)
            }
            return String(localized: "The grapes you’ve studied lead to \(link.region.title). With \(varieties) as your guide, that corner of the wine map is coming into focus.", bundle: .module)
        }
        if grapes.count > 1 {
            let varieties = names(grapes)
            let sharedCountries = grapes.dropFirst().reduce(Set(grapes[0].countries)) { $0.intersection($1.countries) }
            if sharedCountries.count == 1, let country = sharedCountries.first {
                return String(localized: "You’re getting to know \(country) by following its grapes. \(varieties) give you different ways into the same wine country.", bundle: .module)
            }
            if alternate(for: grapes[0].id) {
                return String(localized: "Your studies follow \(varieties) through the wine world. Each grape gives you a different way to read the glass.", bundle: .module)
            }
            return String(localized: "From \(varieties), you’re learning to hear the different voices a grape can bring to wine. Variety is the thread running through your studies.", bundle: .module)
        }
        if let grape = grapes.first {
            return String(localized: "You’ve found a first thread in \(grape.title). Follow it and a whole corner of the wine world begins to open up.", bundle: .module)
        }
        return nil
    }

    private struct RegionMatch {
        let region: Course
        let grapes: [Course]
    }

    private func matches(regions: [Course], grapes: [Course]) -> [RegionMatch] {
        regions.compactMap { region in
            let linked = grapes.filter { GrapeNames.matches($0, in: region) }
            return linked.isEmpty ? nil : RegionMatch(region: region, grapes: linked)
        }
    }

    private func uniqueLeader(_ matches: [RegionMatch]) -> RegionMatch? {
        let ranked = matches.sorted { $0.grapes.count > $1.grapes.count }
        guard let first = ranked.first, ranked.dropFirst().first?.grapes.count != first.grapes.count else { return nil }
        return first
    }

    private func names(_ courses: [Course]) -> String {
        ListFormatter.localizedString(byJoining: courses.prefix(3).map(\.title))
    }

    private func alternate(for key: String) -> Bool {
        // Swift’s hash changes between launches. Course IDs give a stable editorial choice.
        key.utf8.reduce(0) { $0 + Int($1) }.isMultiple(of: 2)
    }

    private enum Level: String, CaseIterable {
        case beginner = "Essentials"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"

        var geographyLine: String {
            switch self {
            case .beginner:
                String(localized: "On the beginner stretch of The Path, these discoveries are giving the basics a place to take root.", bundle: .module)
            case .intermediate:
                String(localized: "At the intermediate stage of The Path, these studies are giving you more ways to connect what you learn to what’s in the glass.", bundle: .module)
            case .advanced:
                String(localized: "At the advanced stage of The Path, connections like these are becoming part of how you read a wine.", bundle: .module)
            case .expert:
                String(localized: "At the expert stage of The Path, the details of place and grape are becoming part of your own reading of wine.", bundle: .module)
            }
        }

        var pathStory: String {
            switch self {
            case .beginner:
                String(localized: "You’re on the beginner stretch of The Path. The next glass already has a little more to tell you.", bundle: .module)
            case .intermediate:
                String(localized: "You’re at the intermediate stage of The Path. The pieces are starting to fit together, from what happens in the vineyard to what finally shows up in the glass.", bundle: .module)
            case .advanced:
                String(localized: "You’re at the advanced stage of The Path. A glass is becoming a set of clues you can trace back through the cellar and the vineyard.", bundle: .module)
            case .expert:
                String(localized: "You’re at the expert stage of The Path. The smallest details in the glass can open up the longest stories.", bundle: .module)
            }
        }
    }
}
