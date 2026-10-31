import Foundation

/// One module of learn.json, with its lessons.
struct PackedModule: Decodable {
    var id: String
    var kind: String
    var order: Int
    var title: String
    var description: String
    var complexity: String
    var lessonCount: Int
    var xp: Int
    var estimatedMinutes: Int
    var level: String?
    var color: String?
    var origin: String?
    var aliases: [String]?
    var countries: [String]?
    var country: String?
    var countryCode: String?
    var grapes: [String]?
    var points: String?
    var lessons: [PackedLesson]
}
