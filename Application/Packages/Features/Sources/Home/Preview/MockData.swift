import Core
import Foundation

/// Mocked data for the Home while there is no backend. Names come from the UVVA App canvas.
enum MockData {
    static let elisaMap = PalateMap([
        .sweetness: 2, .acidity: 7, .tannin: 5, .body: 5, .fruit: 7, .floral: 4, .oak: 4, .spice: 5
    ])

    static func profile(_ s: Double, _ a: Double, _ t: Double, _ b: Double,
                        _ f: Double, _ fl: Double, _ o: Double, _ sp: Double) -> PalateMap {
        PalateMap([.sweetness: s, .acidity: a, .tannin: t, .body: b, .fruit: f, .floral: fl, .oak: o, .spice: sp])
    }

    static let catalog: [Wine] = [
        Wine(id: "alvarinho", name: "Alvarinho, Monção e Melgaço", vintage: 2023, type: "White",
             origin: "Monção e Melgaço, Portugal", grapes: ["Alvarinho"], alcohol: 12.5,
             classification: "Vinho Verde DOC · 12.5% abv",
             profile: profile(1, 8, 0, 4, 7, 5, 1, 2),
             dish: Dish(title: "Roasted peppers with fennel and dill oil",
                        why: "The acidity cuts the oil and the herbs pick up its saline snap.",
                        ingredients: ["3 red peppers", "1 fennel bulb", "A bunch of dill", "Olive oil", "Lemon", "Flaked sea salt"],
                        steps: ["Roast the whole peppers at 220 °C for 30 minutes, then peel and tear into wide strips.",
                                "Blitz the dill with olive oil and a pinch of salt.",
                                "Shave the fennel thin and dress it in lemon juice alone.",
                                "Lay the peppers down, the fennel over them, the dill oil around the edge."],
                        serves: "Serves 2 · 45 min"),
             note: "Lemon, white peach, saline.", serving: 8...10,
             originInsight: "Portugal's cool, rainy Atlantic north, known for fresh, aromatic whites.",
             appellationInsight: "Portugal's protected origin label (DOC): it guarantees the region and its rules, but is not a mark of higher rank.",
             howToServe: "Cold keeps its bright acidity crisp and its citrus precise; too warm, it loses its freshness."),
        Wine(id: "baga", name: "Baga, Bairrada", origin: "Bairrada, Portugal",
             profile: profile(0, 7, 7, 5, 6, 3, 3, 5),
             dish: Dish(title: "Charred mushrooms with bay and sour cherry butter", why: "Firm tannin meets the char; the cherry follows its red fruit."),
             note: "Fresh red with sour cherry and plum, firm grip and some oak behind it."),
        Wine(id: "touriga", name: "Touriga Nacional, Dão", origin: "Dão, Portugal",
             profile: profile(1, 6, 6, 6, 7, 6, 4, 5),
             dish: Dish(title: "Roast beetroot with black olive and toasted walnut", why: "Violet and dark fruit sit on the earthy sweetness of the beet."),
             note: "Round red with violet and blackberry, a light touch of wood."),
        Wine(id: "mencia", name: "Mencía, Bierzo", origin: "Bierzo, Spain",
             profile: profile(1, 6, 5, 5, 7, 4, 3, 6),
             dish: Dish(title: "Lamb chops with rosemary and pepper", why: "Pepper in the wine, pepper on the plate."),
             note: "Juicy red with raspberry and black pepper."),
        Wine(id: "loureiro", name: "Loureiro, Vinho Verde", origin: "Vinho Verde, Portugal",
             profile: profile(2, 8, 0, 3, 6, 7, 0, 1),
             dish: Dish(title: "Sea bass ceviche, lime and coriander", why: "Citrus meets citrus; the coriander lifts its floral side."),
             note: "Light white with lime and orange blossom."),
        Wine(id: "etna", name: "Etna Rosso, young", origin: "Sicily, Italy",
             profile: profile(0, 7, 5, 4, 6, 4, 2, 5), dish: nil,
             note: "Red with red cherry and volcanic smoke."),
        Wine(id: "morgon", name: "Morgon, Beaujolais Cru", origin: "Beaujolais, France",
             profile: profile(1, 6, 4, 4, 8, 4, 1, 3), dish: nil,
             note: "Round red with raspberry and plum, soft and bright."),
        Wine(id: "pontoforte", name: "Ponto Forte", origin: "Alentejo, Portugal",
             profile: profile(1, 5, 5, 8, 6, 3, 5, 6), dish: nil,
             note: "Full red with ripe plum and plenty of oak behind it."),
        Wine(id: "riesling", name: "Mosel Riesling Kabinett", origin: "Mosel, Germany",
             profile: profile(6, 8, 0, 2, 6, 5, 0, 1), dish: nil,
             note: "Off-dry white with green apple and lime."),
        Wine(id: "barolo", name: "Barolo, Piedmont", origin: "Piedmont, Italy",
             profile: profile(0, 7, 9, 7, 5, 5, 5, 4), dish: nil,
             note: "Firm red with rose, tar and cherry.")
    ]

    static let glossary: [GlossaryTerm] = [
        GlossaryTerm(term: "Acidity", pronunciation: "a-SID-i-tee",
                     definition: "The freshness that makes your mouth water. Your palate map reads it as your highest axis."),
        GlossaryTerm(term: "Tannin", pronunciation: "TAN-in",
                     definition: "The drying grip from grape skins and oak that holds a red upright."),
        GlossaryTerm(term: "Terroir", pronunciation: "ter-WAHR",
                     definition: "Soil, climate and place: everything about where a wine grows.")
    ]

    static let foundations = CourseProgress(
        id: "module-01", title: "Foundations", totalLessons: 6, completedLessons: 2, hasStarted: true,
        lastOpenedAt: Date().addingTimeInterval(-3_600),
        current: LessonRef(number: 3, title: "Red, white and rosé", step: 4))

    static let lastRating = Rating(wineKey: "pontoforte", verdict: .yes, date: Date().addingTimeInterval(-86_400),
                                   deltas: [.tannin: 0.3, .body: 0.2, .acidity: -0.1])

    static let marina = Friend(id: "marina", name: "Marina Alves",
                               map: PalateMap([.acidity: 7, .fruit: 6.5, .body: 5, .floral: 4]), addedAt: .now)
    static let friends: [Friend] = [
        marina,
        Friend(id: "bia", name: "Bia Damas", map: PalateMap([.tannin: 7, .oak: 6, .body: 6]), addedAt: .now),
        Friend(id: "rui", name: "Rui das Neves", map: PalateMap([.spice: 7, .fruit: 6, .sweetness: 3]), addedAt: .now)
    ]
}
