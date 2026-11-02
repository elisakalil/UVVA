import Foundation

struct PackedGlossaryTerm: Decodable {
    var id: String
    var term: String
    var lesson: Int?
    var definition: String
    var pronunciation: String?
    var aka: String?
}
