import Core
import Foundation

struct HomeContentUIModel: Equatable {
    var cards: [HomeCardModel]
    var glossary: [GlossaryTerm] = []
    var firstName: String = ""
    var palateMap: PalateMap
}
