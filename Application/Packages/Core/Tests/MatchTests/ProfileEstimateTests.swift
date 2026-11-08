import Core
import Match
import Testing

struct ProfileEstimateTests {
    private func flat(_ value: Double) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, value) }))
    }

    private func wine(_ id: String, _ value: Double, type: String = "Red", region: String? = nil,
                      grapes: [String] = []) -> Wine {
        Wine(id: id, name: id, type: type, origin: "", region: region, grapes: grapes, profile: flat(value))
    }

    private let catalog: [Wine] = [
        // Two Syrah reds from Alentejo, one from elsewhere, one Syrah rosé.
        Wine(id: "a", name: "a", type: "Red", origin: "", region: "Alentejo", grapes: ["Syrah"], profile: PalateMap([.body: 8, .fruit: 6])),
        Wine(id: "b", name: "b", type: "Red", origin: "", region: "Alentejo", grapes: ["Syrah", "Touriga Nacional"], profile: PalateMap([.body: 6, .fruit: 8])),
        Wine(id: "c", name: "c", type: "Red", origin: "", region: "Rhône", grapes: ["Syrah"], profile: PalateMap([.body: 4])),
        Wine(id: "d", name: "d", type: "Rosé", origin: "", region: "Alentejo", grapes: ["Syrah"], profile: PalateMap([.acidity: 9])),
        Wine(id: "e", name: "e", type: "White", origin: "", region: "Alentejo", grapes: ["Antão Vaz"], profile: PalateMap([.acidity: 7])),
        Wine(id: "f", name: "f", type: "White", origin: "", region: "Alentejo", grapes: ["Arinto"], profile: PalateMap([.acidity: 5])),
        Wine(id: "g", name: "g", type: "White", origin: "", region: "Alentejo", grapes: ["Arinto"], profile: PalateMap([.acidity: 3]))
    ]

    // MARK: CELLAR-R17 · Leitura (vinho fora do catálogo)

    @Test func CELLAR_R17_sameTypeSharingTheMostGrapes() throws {
        let map = try #require(ProfileEstimate.estimate(grapes: ["Syrah", "Touriga Nacional"], type: "Red",
                                                        region: nil, in: catalog))
        #expect(map == catalog[1].profile)
    }

    @Test func CELLAR_R17_sameGrape_averagesItsWinesOfThatType() throws {
        let map = try #require(ProfileEstimate.estimate(grapes: ["Syrah"], type: "Red", region: nil, in: catalog))
        #expect(map[.body] == 6)
        #expect(map[.acidity] == 0)
    }

    @Test func CELLAR_R17_regionNarrows_onlyWithEnoughWines() throws {
        // Two Alentejo Syrah reds: too few to narrow, so the Rhône one counts too.
        let map = try #require(ProfileEstimate.estimate(grapes: ["Syrah"], type: "Red", region: "Alentejo", in: catalog))
        #expect(map[.body] == 6)
        // Three Alentejo whites without a shared grape: the region is enough.
        let white = try #require(ProfileEstimate.estimate(grapes: ["Encruzado"], type: "White", region: "Alentejo", in: catalog))
        #expect(white[.acidity] == 5)
    }

    @Test func CELLAR_R17_onlyTheType_averagesThatType() throws {
        let map = try #require(ProfileEstimate.estimate(grapes: [], type: "Rosé", region: nil, in: catalog))
        #expect(map == catalog[3].profile)
    }

    @Test func CELLAR_R17_nothingKnown_averagesTheCatalog() throws {
        let map = try #require(ProfileEstimate.estimate(grapes: [], type: nil, region: nil, in: [wine("x", 2), wine("y", 4)]))
        #expect(map == flat(3))
        #expect(ProfileEstimate.estimate(grapes: ["Syrah"], type: "Red", region: nil, in: []) == nil)
    }
}
