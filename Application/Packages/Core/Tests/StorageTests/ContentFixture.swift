import Foundation

/// A small set of packed content files written to a temporary folder, in the format of pack_content.py.
struct ContentFixture {
    var version = "v1"
    var wines: [[String: Any]] = [Self.wine("a-wine-2020", name: "A Wine", vintage: 2020),
                                  Self.wine("b-wine", name: "B Wine", vintage: nil)]
    var recipes: [[String: Any]] = [Self.recipe("salad"), Self.recipe("stew")]
    var modules: [[String: Any]] = [Self.module("path-01", lessons: 2)]
    var terms: [[String: Any]] = [["id": "acidity", "term": "Acidity", "lesson": 6, "definition": "Freshness.",
                                   "pronunciation": NSNull(), "aka": NSNull()]]
    var questions: [[String: Any]] = Self.questions()
    /// Leaves wines.json out, to break the import half way.
    var skipWines = false

    static let axes = ["floral", "body", "tannin", "spice", "oak", "sweetness", "acidity", "fruit"]

    static func map(_ value: Double = 5) -> [String: Double] {
        Dictionary(uniqueKeysWithValues: axes.map { ($0, value) })
    }

    static func wine(_ key: String, name: String, vintage: Int?, acidity: Double = 5) -> [String: Any] {
        var map = map()
        map["acidity"] = acidity
        return ["id": key, "name": name, "producer": "Producer", "vintage": vintage ?? NSNull(),
                "origin": "Douro, Portugal", "region": "Douro", "country": "Portugal", "grapes": ["Touriga Nacional"],
                "type": "Red", "alcohol": NSNull(), "servingTemperature": ["min": 14, "max": 16],
                "pairings": ["Beef"], "classification": "DOC", "findIt": "Producer \(name)",
                "note": "Dark fruit.", "map": map]
    }

    static func recipe(_ id: String) -> [String: Any] {
        ["id": id, "title": id.capitalized, "why": "Because.", "course": "main", "mainIngredient": "beef",
         "cuisine": "Portuguese", "season": ["winter"], "diet": [], "allergens": ["dairy"], "wineTypes": ["Red"],
         "map": map(4), "twist": ["ingredient": "pepper", "axis": "spice", "shift": 2.5],
         "flavor": ["salt": 4, "fat": 4, "acid": 4, "sweet": 2, "umami": 0, "heat": 1, "bitter": 0, "weight": 0.5],
         "servings": 4, "prepMinutes": 15, "cookMinutes": 0, "difficulty": "easy",
         "ingredients": [["name": "beef", "quantity": 600, "unit": "g", "note": NSNull(), "role": "base"]],
         "steps": ["Cook it."]]
    }

    static func module(_ id: String, lessons: Int) -> [String: Any] {
        ["id": id, "kind": "path", "order": 1, "level": "Essentials", "complexity": "D", "title": "What Wine Is",
         "description": "What wine is.", "lessonCount": lessons, "xp": 75, "estimatedMinutes": 15,
         "lessons": (1...lessons).map { n in
             ["id": "\(id)-l0\(n)", "moduleId": id, "order": n, "title": "Lesson \(n)", "subtitle": "Sub",
              "xp": 15, "estimatedMinutes": 3, "isReview": false, "objectives": ["Learn"],
              "steps": [["type": "concept", "title": "Grapes", "body": "Fermented juice.", "highlight": "Grapes"],
                        ["type": "multipleChoice", "prompt": "Which?", "options": ["A", "B"], "answer": 1,
                         "explanation": "B."]]] as [String: Any]
         }]
    }

    static func questions() -> [[String: Any]] {
        axes.flatMap { axis in
            (1...3).map { version in
                ["axis": axis, "version": version, "prompt": "\(axis) \(version)?",
                 "answers": (0...9).map { "\(axis) \(version) \($0)" }] as [String: Any]
            }
        }
    }

    /// Writes the files to a new temporary folder and returns it.
    func write() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "content-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        func save(_ object: Any, _ name: String) throws {
            try JSONSerialization.data(withJSONObject: object).write(to: folder.appending(path: name))
        }
        try save(["version": version, "counts": [String: Int](), "files": [String: String]()], "manifest.json")
        if !skipWines { try save(["wines": wines], "wines.json") }
        try save(["recipes": recipes], "recipes.json")
        try save(["modules": modules], "learn.json")
        try save(["terms": terms], "glossary.json")
        try save(["questions": questions], "quiz.json")
        return folder
    }
}
