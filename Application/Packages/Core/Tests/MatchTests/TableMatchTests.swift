import Core
import Testing
@testable import Match

struct TableMatchTests {
    private func map(_ values: [PalateAxis: Double], rest: Double = 3) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, values[$0] ?? rest) }))
    }

    private func wine(_ id: String, type: String = "Red", _ values: [PalateAxis: Double]) -> Wine {
        Wine(id: id, name: id, type: type, origin: "", profile: map(values))
    }

    private func recipe(_ id: String, _ course: TableCourse, types: [String] = ["Red"],
                        _ values: [PalateAxis: Double] = [:]) -> Recipe {
        Recipe(id: id, title: id, why: "", course: course.rawValue, wineTypes: types, profile: map(values))
    }

    // MARK: Compatibilidade

    @Test func compatibility_isTheWineDistance_andSymmetric() {
        let a = map([.acidity: 8]), b = map([.acidity: 4])
        #expect(TableMatch.compatibility(a, b) == Similarity.percent(a, b))
        #expect(TableMatch.compatibility(a, b) == TableMatch.compatibility(b, a))
        #expect(TableMatch.compatibility(a, a) == 100)
    }

    @Test func FRI_R19_tableOfTwo_isThePair() {
        let a = map([.acidity: 8]), b = map([.fruit: 7])
        #expect(TableMatch.tableCompatibility([a, b]) == TableMatch.compatibility(a, b))
    }

    @Test func FRI_R19_tableCompatibility_isTheAverageOfThePairs() {
        let a = map([:]), b = map([:]), c = map([.acidity: 9, .fruit: 9])
        let pairs = [Similarity.between(a, b), Similarity.between(a, c), Similarity.between(b, c)]
        #expect(TableMatch.tableCompatibility([a, b, c]) == Int((pairs.reduce(0, +) / 3 * 100).rounded()))
    }

    // MARK: Eixos em comum

    @Test func FRI_R12_sharedAxes_highForEveryone_andClose_byAverage() {
        let maps = [map([.acidity: 7, .fruit: 8, .spice: 9]), map([.acidity: 7.5, .fruit: 7, .spice: 4])]
        #expect(TableMatch.sharedAxes(maps) == [.fruit, .acidity])
    }

    @Test func FRI_R12_sharedAxes_atMostThree() {
        let high: [PalateAxis: Double] = [.acidity: 8, .fruit: 7.5, .body: 7, .floral: 6.5]
        #expect(TableMatch.sharedAxes([map(high), map(high)]) == [.acidity, .fruit, .body])
    }

    @Test func FRI_R12_noAxisHighForEveryone_noSharedAxes() {
        #expect(TableMatch.sharedAxes([map([.acidity: 8]), map([.tannin: 8])]).isEmpty)
    }

    // MARK: FRI-R19 · Reading by reading

    @Test func FRI_R19_range_fromLowestToHighest() {
        let maps = [6.0, 7, 7, 8].map { map([.acidity: $0]) }
        #expect(TableMatch.range(maps, .acidity) == 6...8)
    }

    @Test func FRI_R19_axisSpread_labels() {
        func spread(_ values: [Double]) -> AxisSpread { TableMatch.axisSpread(values.map { map([.acidity: $0]) }, .acidity) }
        #expect(spread([6, 6.5]) == .same)
        #expect(spread([6, 7.5]) == .closest)
        #expect(spread([5, 8]) == .someGive)
        #expect(spread([2, 8]) == .widest)
    }

    @Test func FRI_R19_crossedAndBoldest() {
        let maps = [map([.acidity: 6]), map([.acidity: 8])]
        #expect(TableMatch.crossed(maps)[.acidity] == 7)
        #expect(TableMatch.boldest(maps)[.acidity] == 8)
    }

    // MARK: FRI-R14, R15 · Garrafas

    @Test func FRI_R15_threeBottles_inCourseOrder_eachWithItsDish() {
        let maps = [map([.acidity: 7]), map([.acidity: 7])]
        let wines = [wine("red", [.acidity: 7]), wine("white", type: "White", [.acidity: 7]),
                     wine("port", type: "Fortified", [.sweetness: 8])]
        let recipes = [recipe("cake", .dessert, types: ["Fortified"]), recipe("salad", .starter, types: ["White"]),
                       recipe("stew", .main), recipe("cheese", .main, types: [])]
        let bottles = TableMatch.tableBottles(maps, wines: wines, recipes: recipes)
        #expect(bottles.map(\.course) == [.starter, .main, .dessert])
        #expect(bottles.map(\.wine.id) == ["white", "red", "port"])
        #expect(bottles.map(\.recipe.id) == ["salad", "stew", "cake"])
    }

    @Test func FRI_R14_aWineIsUsedOnce() {
        let wines = [wine("a", [.acidity: 7]), wine("b", [.acidity: 6])]
        let recipes = TableCourse.allCases.map { recipe($0.rawValue, $0) }
        let bottles = TableMatch.tableBottles([map([.acidity: 7])], wines: wines, recipes: recipes)
        // Two wines for three courses: each is used once, and the last course is left out.
        #expect(bottles.count == 2)
        #expect(Set(bottles.map(\.wine.id)) == ["a", "b"])
    }

    @Test func FRI_R14_bottleAxis_isTheSharedAxisTheWineIsHighestOn() {
        let maps = [map([.acidity: 7, .fruit: 7]), map([.acidity: 7, .fruit: 7])]
        let bottles = TableMatch.tableBottles(maps, wines: [wine("w", [.acidity: 6, .fruit: 8])],
                                              recipes: [recipe("stew", .main)])
        #expect(bottles.first?.axis == .fruit)
    }
}
