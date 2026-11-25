import Testing
@testable import Core

struct WineListParserTests {
    /// A line of the page at row `row`, from `x` to `x + width`.
    private func line(_ text: String, row: Int, x: Double = 0.08, width: Double = 0.6, height: Double = 0.02) -> WineListLine {
        WineListLine(text, minX: x, minY: 0.05 + Double(row) * 0.03, width: width, height: height)
    }

    // MARK: WINELIST-R04 · Preços

    @Test func WINELIST_R04_price_isTheLastNumber_notTheYear() {
        #expect(WineListPrice.split("Soalheiro Alvarinho 2023 ..... 42 €").price == 42)
        #expect(WineListPrice.split("Soalheiro Alvarinho 2023 ..... 42 €").text == "Soalheiro Alvarinho 2023")
        #expect(WineListPrice.split("Quinta do Crasto 2021").price == nil)
        #expect(WineListPrice.split("Barca Velha 2011 R$ 1.250,00").price == 1250)
        #expect(WineListPrice.split("€38 Encruzado").price == nil)
        #expect(WineListPrice.split("Encruzado €38").price == 38)
    }

    @Test func WINELIST_R04_glassAndBottle_ordersByTheBottle() {
        let split = WineListPrice.split("Arinto da Romeira 7 / 28")
        #expect(split.price == 28)
        #expect(split.text == "Arinto da Romeira")
    }

    @Test func WINELIST_R04_currency_isTheMostWritten() {
        #expect(WineListPrice.currency(in: ["Tinto 42 €", "Branco 30 €", "Rosé 28"]) == "€")
        #expect(WineListPrice.currency(in: ["Malbec R$ 180", "Tannat R$ 210"]) == "R$")
        #expect(WineListPrice.currency(in: ["Malbec 180"]) == nil)
    }

    // MARK: WINELIST-R04 · Secções e linhas

    @Test func WINELIST_R04_headings_sayTheType() {
        #expect(WineListSection.type(of: "Vinhos Tintos") == "Red")
        #expect(WineListSection.type(of: "WHITES") == "White")
        #expect(WineListSection.type(of: "Espumantes") == "Sparkling")
        #expect(WineListSection.type(of: "Tinto Reserva da Casa") == nil)
        #expect(WineListSection.isFiller("Copo · Garrafa"))
    }

    @Test func WINELIST_R04_nameAndPriceReadApart_makeOneWine_withTheLineUnder() {
        let entries = WineListParser.entries(in: [
            line("Carta de vinhos", row: 0),
            line("Brancos", row: 1),
            line("Alvarinho, Monção e Melgaço", row: 2),
            line("42 €", row: 2, x: 0.82, width: 0.1),
            line("Soalheiro Alvarinho 2023", row: 3, height: 0.015),
            line("Arinto, Bucelas", row: 4),
            line("28 €", row: 4, x: 0.82, width: 0.1),
            line("Quinta da Romeira Arinto 2023", row: 5, height: 0.015),
            line("Tintos", row: 6),
            line("Baga, Bairrada", row: 7),
            line("36 €", row: 7, x: 0.82, width: 0.1),
            line("Luís Pato Baga 2020", row: 8, height: 0.015)
        ])
        #expect(entries.map(\.name) == ["Alvarinho, Monção e Melgaço", "Arinto, Bucelas", "Baga, Bairrada"])
        #expect(entries.map(\.price) == [42, 28, 36])
        #expect(entries.map(\.details) == [["Soalheiro Alvarinho 2023"], ["Quinta da Romeira Arinto 2023"],
                                          ["Luís Pato Baga 2020"]])
        #expect(entries.map(\.sectionType) == ["White", "White", "Red"])
        #expect(entries.map(\.position) == [1, 2, 1])
    }

    @Test func WINELIST_R04_nameFirst_thenDetailsWithThePrice() {
        let entries = WineListParser.entries(in: [
            line("RED WINES", row: 0),
            line("Quinta do Crasto", row: 1),
            line("Douro · Touriga Nacional 2021   45", row: 2),
            line("Luís Pato", row: 3),
            line("Bairrada · Baga 2020   36", row: 4)
        ])
        #expect(entries.map(\.name) == ["Quinta do Crasto", "Luís Pato"])
        #expect(entries.map(\.details) == [["Douro · Touriga Nacional 2021"], ["Bairrada · Baga 2020"]])
        #expect(entries.map(\.price) == [45, 36])
    }

    @Test func WINELIST_R04_twoColumns_areReadOneAfterTheOther() {
        let entries = WineListParser.entries(in: [
            line("Brancos", row: 0, width: 0.3),
            line("Tintos", row: 0, x: 0.55, width: 0.3),
            line("Soalheiro Alvarinho 42", row: 1, width: 0.36),
            line("Luís Pato Baga 36", row: 1, x: 0.55, width: 0.36),
            line("Romeira Arinto 28", row: 2, width: 0.36),
            line("Crasto Touriga 45", row: 2, x: 0.55, width: 0.36)
        ])
        #expect(entries.map(\.name) == ["Soalheiro Alvarinho", "Romeira Arinto", "Luís Pato Baga", "Crasto Touriga"])
        #expect(entries.map(\.sectionType) == ["White", "White", "Red", "Red"])
    }

    @Test func WINELIST_R04_withoutPrices_theLargerTypeIsTheWine() {
        let entries = WineListParser.entries(in: [
            line("Tintos", row: 0),
            line("Quinta do Crasto 2021", row: 1, height: 0.022),
            line("Touriga Nacional, Douro", row: 2, height: 0.014),
            line("Luís Pato Baga 2020", row: 3, height: 0.022)
        ])
        #expect(entries.map(\.name) == ["Quinta do Crasto 2021", "Luís Pato Baga 2020"])
        #expect(entries.first?.details == ["Touriga Nacional, Douro"])
        #expect(entries.allSatisfy { $0.price == nil })
    }
}
