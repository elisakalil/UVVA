import Foundation

/// The words a label uses, in the languages UVVA reads (pt, en, fr, it, es, de), already folded by `WineText`.
enum LabelKeywords {
    /// Checked in this order: a fortified or sparkling word wins over a colour (a "Porto Tinto" is Fortified,
    /// a "Rosé Brut" is Sparkling).
    static let types: [(type: String, words: [String])] = [
        ("Fortified", ["porto", "port", "oporto", "sherry", "jerez", "xeres", "madeira", "marsala", "vin doux naturel",
                       "moscatel de setubal", "vinho generoso", "tawny", "ruby port", "fino", "oloroso", "amontillado"]),
        ("Sparkling", ["espumante", "sparkling", "champagne", "cava", "prosecco", "cremant", "sekt", "spumante",
                       "franciacorta", "methode traditionnelle", "metodo classico", "metodo tradicional", "brut",
                       "extra brut", "brut nature", "pet nat", "frizzante", "mousseux"]),
        ("Rosé", ["rose", "rosado", "rosato", "rosewein"]),
        ("White", ["branco", "white", "blanc", "bianco", "blanco", "weiss", "weisswein", "weissburgunder"]),
        ("Red", ["tinto", "red", "rouge", "rosso", "rotwein", "vino tinto", "vinho tinto"])
    ]

    /// Words that start or mark the producer's line.
    static let producerMarks: Set<String> = [
        "quinta", "chateau", "domaine", "bodega", "bodegas", "herdade", "tenuta", "weingut", "casa", "cantina",
        "cantine", "maison", "estate", "winery", "vineyards", "vineyard", "adega", "caves", "clos", "fattoria",
        "castello", "schloss", "azienda", "monte", "famille", "family", "cellars", "wines", "vinhos", "vinos"
    ]

    /// "Bottled by …" and its translations, folded: the producer follows.
    static let bottledBy: [String] = [
        "bottled by", "produced by", "produced and bottled by", "grown and bottled by", "made by",
        "engarrafado por", "produzido por", "produzido e engarrafado por", "engarrafado na origem por",
        "elaborado por", "embotellado por", "elaborado y embotellado por",
        "mis en bouteille par", "mis en bouteille au chateau par", "mis en bouteille a la propriete par",
        "imbottigliato da", "prodotto e imbottigliato da", "abgefullt von", "erzeugerabfullung"
    ]

    /// Words before a year that make it a founding date, not the vintage.
    static let foundedWords: Set<String> = [
        "since", "desde", "depuis", "dal", "seit", "est", "estd", "established", "founded", "fondee", "fonde",
        "fundada", "fundado", "fondata", "fondato", "gegrundet", "anno"
    ]

    /// Words that say nothing about which wine it is: a line made only of these is not the name.
    static let generic: Set<String> = [
        "vinho", "vino", "vin", "wine", "wein", "regional", "doc", "docg", "doca", "aoc", "aop", "igp", "igt",
        "dop", "ava", "qba", "pradikatswein", "denominacao", "denominazione", "denominacion", "origem", "origine",
        "origen", "origin", "controlada", "controllata", "controlee", "appellation", "protegida",
        "garantita", "product", "produce", "of", "produto", "produit", "prodotto", "producto", "contains",
        "sulfites", "sulphites", "contem", "sulfitos", "contient", "contiene", "solfiti", "ml", "cl", "l", "e", "de",
        "da", "do", "di", "del", "du", "des", "la", "le", "the", "and", "et", "y", "und", "vol", "alc", "estate",
        "bottled", "reserva", "reserve", "riserva", "gran", "grande", "classico", "superiore", "vintage", "year",
        "ano", "annee", "annata", "cosecha", "colheita", "harvest", "dry", "seco", "sec", "secco", "trocken"
    ]

    /// The country as a label from that country writes it, folded, with the name the catalog uses.
    static let countryNames: [String: String] = [
        "italia": "Italy", "espana": "Spain", "deutschland": "Germany", "osterreich": "Austria", "suisse": "Switzerland",
        "schweiz": "Switzerland", "sudafrica": "South Africa", "afrique du sud": "South Africa", "grece": "Greece",
        "hellas": "Greece", "magyarorszag": "Hungary", "brasil": "Brazil", "mexico": "Mexico", "uruguay": "Uruguay",
        "estados unidos": "United States", "usa": "United States", "united states of america": "United States"
    ]
}
