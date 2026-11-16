import Core

extension PalateMap {
    /// A map given by its positions on the ruler, as Friends shows it (QUIZ-R04a, R05).
    static func positions(_ positions: [PalateAxis: Double]) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map {
            ($0, WineRuler.value(atPosition: positions[$0] ?? 0, on: $0))
        }))
    }
}
