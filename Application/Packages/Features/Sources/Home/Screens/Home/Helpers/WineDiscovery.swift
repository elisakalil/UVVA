import Core
import Foundation
import Match

enum WineDiscovery {
    enum Direction: CaseIterable {
        case familiar, surprise
    }

    static let anyType = "Any type"
    static let types = [anyType, "Red", "White", "Rosé", "Sparkling", "Sweet", "Fortified"]
    static let countries = ["Anywhere", "Portugal", "France", "Italy", "Spain", "United States", "Argentina",
                            "Chile", "Germany", "Austria", "Australia", "New Zealand", "South Africa"]

    enum Note: String, CaseIterable {
        case citrus = "Citrus"
        case orchard = "Orchard fruit"
        case tropical = "Tropical"
        case redFruit = "Red fruit"
        case darkFruit = "Dark fruit"
        case floral = "Floral"
        case herbal = "Herbal"
        case spiced = "Spiced"
        case mineral = "Mineral"
        case earthy = "Earthy"
        case toasty = "Toasty"

        var keywords: [String] {
            switch self {
            case .citrus: ["citrus", "lemon", "lime", "grapefruit", "orange peel"]
            case .orchard: ["orchard fruit", "apple", "pear", "peach", "apricot", "quince"]
            case .tropical: ["tropical", "pineapple", "mango", "passion fruit", "guava"]
            case .redFruit: ["red fruit", "red berry", "red berries", "strawberry", "raspberry", "red cherry", "cranberry"]
            case .darkFruit: ["dark fruit", "black fruit", "blackberry", "black cherry", "cassis", "blackcurrant", "blueberry", "plum"]
            case .floral: ["floral", "flower", "blossom", "violet", "rose petal", "iris", "jasmine"]
            case .herbal: ["herbal", "herb", "mint", "thyme", "sage", "rosemary"]
            case .spiced: ["spice", "spicy", "pepper", "clove", "cinnamon", "nutmeg"]
            case .mineral: ["mineral", "flint", "chalk", "slate", "saline", "wet stone"]
            case .earthy: ["earth", "soil", "mushroom", "forest floor", "truffle"]
            case .toasty: ["toast", "brioche", "smoke", "roasted"]
            }
        }
    }

    enum Pairing: String, CaseIterable {
        case redMeat = "Red meat"
        case fish = "Fish"
        case seafood = "Seafood"
        case poultry = "Poultry"
        case pasta = "Pasta"
        case vegetables = "Vegetables"
        case cheese = "Cheese"
        case dessert = "Dessert"

        var tags: Set<String> {
            switch self {
            case .redMeat: ["Beef", "Lamb", "Veal", "Game"]
            case .fish: ["Fish", "Lean Fish", "Rich Fish", "Salt Cod", "Sushi", "Sashimi"]
            case .seafood: ["Seafood", "Shellfish"]
            case .poultry: ["Poultry", "Chicken"]
            case .pasta: ["Pasta", "Lasagna", "Tagliatelle"]
            case .vegetables: ["Vegetarian", "Mushrooms", "Salad", "Eggplant Parmigiana", "Baked Potato"]
            case .cheese: ["Cheese", "Aged Cheese", "Hard Cheese", "Goat Cheese", "Soft Cheese", "Blue Cheese", "Mild Cheese"]
            case .dessert: ["Dessert", "Sweet Dessert", "Fruit Dessert", "Chocolate", "Cake"]
            }
        }
    }

    static func suggestions(in catalog: [Wine], for palate: PalateMap, direction: Direction,
                            type: String, country: String, notes: [Note], pairing: Pairing? = nil) -> [Wine] {
        let pairingTags = pairing?.tags
        let ranked = catalog.compactMap { wine -> (wine: Wine, similarity: Double)? in
            let matchesType = type == "Sweet"
                ? PalateWineSuggestion.Level(wine.profile[.sweetness]) == .high
                : wine.type.caseInsensitiveCompare(type) == .orderedSame
            guard type == anyType || matchesType,
                  pairingTags.map({ !$0.isDisjoint(with: wine.pairings) }) ?? true,
                  country == "Anywhere" || wine.country?.caseInsensitiveCompare(country) == .orderedSame
                      || wine.origin.split(separator: ",").last?.trimmingCharacters(in: .whitespaces)
                          .caseInsensitiveCompare(country) == .orderedSame,
                  notes.allSatisfy({ note in
                      note.keywords.contains { wine.note?.localizedCaseInsensitiveContains($0) == true }
                  }) else { return nil }

            if direction == .surprise {
                let familiarAxes = PalateAxis.allCases.count { abs(palate[$0] - wine.profile[$0]) < WineFit.close }
                guard familiarAxes >= PalateAxis.allCases.count / 2, familiarAxes < PalateAxis.allCases.count else { return nil }
            }
            return (wine, Similarity.between(wine.profile, palate))
        }

        return ranked.sorted { lhs, rhs in
            if lhs.similarity == rhs.similarity { return lhs.wine.id < rhs.wine.id }
            return direction == .familiar ? lhs.similarity > rhs.similarity : lhs.similarity < rhs.similarity
        }.map(\.wine)
    }
}
