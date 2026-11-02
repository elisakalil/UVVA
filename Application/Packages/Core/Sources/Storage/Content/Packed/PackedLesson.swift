import Foundation

/// One lesson inside a module of learn.json.
struct PackedLesson: Decodable {
    var id: String
    var moduleId: String
    var order: Int
    var title: String
    var subtitle: String
    var xp: Int
    var estimatedMinutes: Int
    var isReview: Bool
    var objectives: [String]
    var steps: [JSONValue]
}
