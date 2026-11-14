import Core
import Foundation

@MainActor
protocol LoadYouUseCaseProtocol {
    func execute(previous: YouContentModel) async -> YouContentModel
    /// Only the map and its history: a quick read, so the Map follows a redone Quiz before the rest of You is read.
    func loadMap() async -> (map: PalateMap?, history: [MapChange])?
}
