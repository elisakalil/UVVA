#if os(iOS)
import UIKit

/// Without a camera (the simulator), the shutter takes a drawn page of a wine list, with wines of the catalog and
/// some it does not have, so the whole flow can be tried and Vision still has real text to read. Debug builds only.
enum WineListSample {
    #if DEBUG && targetEnvironment(simulator)
    static let isAvailable = true
    #else
    static let isAvailable = false
    #endif

    private typealias Row = (name: String, detail: String?, price: String)

    private static let first: [(String, [Row])] = [
        ("BRANCOS", [("Soalheiro Alvarinho 2023", "Alvarinho · Monção e Melgaço", "42 €"),
                     ("Quinta da Romeira Prova Régia Arinto", "Arinto · Bucelas", "28 €"),
                     ("Muga Barrel Fermented White", "Viura · Rioja", "38 €")]),
        ("ROSÉS", [("Roquesán Rosado", "Tempranillo · Castilla", "24 €")]),
        ("TINTOS", [("Luis Pato Baga 2020", "Baga · Bairrada", "36 €"),
                    ("Quinta do Crasto Reserva Vinhas Velhas", "Touriga Nacional · Douro", "45 €"),
                    ("Casa Ferreirinha Papa Figos Douro", "Tinta Roriz · Douro", "26 €"),
                    ("Esporão Reserva Red 2011", "Aragonez · Alentejo", "34 €"),
                    ("Catena High Mountain Vines Malbec", "Malbec · Mendoza", "40 €")])
    ]

    private static let second: [(String, [Row])] = [
        ("ESPUMANTES", [("Murganheira Bruto", "Malvasia Fina · Távora-Varosa", "30 €"),
                        ("Champagne Brut Réserve", "Chardonnay · Pinot Noir · Champagne", "85 €")]),
        ("PORTO E MADEIRA", [("Taylor's 10 Year Old Tawny", "Douro", "48 €"),
                             ("Blandy's 5 Year Old Malmsey", "Malvasia · Madeira", "39 €")])
    ]

    static func photo(page: Int) -> Data? {
        guard isAvailable else { return nil }
        let sections = page == 0 ? first : second
        let size = CGSize(width: 1200, height: 1700)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let ink = UIColor(red: 0.13, green: 0.15, blue: 0.11, alpha: 1)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 0.94, green: 0.91, blue: 0.85, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            var y: CGFloat = 110
            draw("Carta de vinhos", at: CGPoint(x: size.width / 2, y: y), size: 54, color: ink, align: .center,
                 font: "Georgia")
            y += 130
            for (heading, rows) in sections {
                draw(heading, at: CGPoint(x: 90, y: y), size: 30, color: ink.withAlphaComponent(0.7), align: .left)
                y += 70
                for row in rows {
                    draw(row.name, at: CGPoint(x: 90, y: y), size: 34, color: ink, align: .left)
                    draw(row.price, at: CGPoint(x: size.width - 90, y: y), size: 34, color: ink, align: .right)
                    y += 50
                    if let detail = row.detail {
                        draw(detail, at: CGPoint(x: 90, y: y), size: 24, color: ink.withAlphaComponent(0.65), align: .left)
                        y += 52
                    }
                }
                y += 40
            }
        }
        return image.jpegData(compressionQuality: 0.85)
    }

    private static func draw(_ text: String, at point: CGPoint, size: CGFloat, color: UIColor,
                             align: NSTextAlignment, font: String = "Helvetica Neue") {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: font, size: size) ?? .systemFont(ofSize: size), .foregroundColor: color
        ]
        let width = (text as NSString).size(withAttributes: attributes).width
        let x = switch align {
        case .center: point.x - width / 2
        case .right: point.x - width
        default: point.x
        }
        (text as NSString).draw(at: CGPoint(x: x, y: point.y), withAttributes: attributes)
    }
}
#endif
