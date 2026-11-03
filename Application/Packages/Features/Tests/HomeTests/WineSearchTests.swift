import Core
import Testing
@testable import Home

struct WineSearchTests {
    private func wine(name: String, producer: String, vintage: Int?) -> Wine {
        Wine(id: "w", name: name, producer: producer, vintage: vintage, origin: "", profile: PalateMap([:]))
    }

    @Test func query_isProducerNameAndVintage() {
        #expect(WineSearch.query(for: wine(name: "Chianti Classico", producer: "Isole e Olena", vintage: 2010))
                == "Isole e Olena Chianti Classico 2010")
    }

    @Test func query_withoutVintage_leavesItOut() {
        #expect(WineSearch.query(for: wine(name: "Cuvée Prestige Sparkling", producer: "René Muré", vintage: nil))
                == "René Muré Cuvée Prestige Sparkling")
    }

    @Test func query_doesNotRepeatAProducerAlreadyInTheName() {
        #expect(WineSearch.query(for: wine(name: "Isole e Olena Chianti Classico", producer: "Isole e Olena", vintage: nil))
                == "Isole e Olena Chianti Classico")
    }

    @Test func url_isAnEncodedWebSearch() {
        let url = WineSearch.url(for: wine(name: "Cuvée Prestige", producer: "René Muré", vintage: 2019))
        #expect(url?.absoluteString == "https://www.google.com/search?q=Ren%C3%A9%20Mur%C3%A9%20Cuv%C3%A9e%20Prestige%202019")
    }
}
