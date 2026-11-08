import Core
import UIKit

/// Without a camera (the simulator), the shutter takes a drawn label of a wine in the catalog, so the whole new
/// note can be tried and the reading still has real text to read. Debug builds only.
enum LabelCameraSample {
    #if DEBUG && targetEnvironment(simulator)
    static let isAvailable = true
    #else
    static let isAvailable = false
    #endif

    static func photo(_ side: LabelSide) -> Data? {
        guard isAvailable else { return nil }
        let lines: [(String, CGFloat)] = switch side {
        case .front: [("ISOLE E OLENA", 74), ("CHIANTI CLASSICO", 58), ("2010", 46),
                      ("Denominazione di Origine Controllata e Garantita", 22)]
        case .back: [("Sangiovese · Canaiolo", 34), ("13,5% vol    750 ml", 30), ("Prodotto in Italia", 28),
                     ("Imbottigliato da Isole e Olena", 26)]
        }
        let size = CGSize(width: 1000, height: 1400)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 0.95, green: 0.92, blue: 0.86, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            var y: CGFloat = 320
            for (text, fontSize) in lines {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "Georgia", size: fontSize) ?? .systemFont(ofSize: fontSize),
                    .foregroundColor: UIColor(red: 0.13, green: 0.15, blue: 0.11, alpha: 1),
                    .paragraphStyle: style
                ]
                let rect = CGRect(x: 60, y: y, width: size.width - 120, height: fontSize * 2.6)
                (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
                y += fontSize * 2.6
            }
        }
        return image.jpegData(compressionQuality: 0.8)
    }
}
