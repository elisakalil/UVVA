import Foundation

struct PackedQuizQuestion: Decodable {
    var axis: String
    var version: Int
    var prompt: String
    var answers: [String]
}
