import CoreGraphics
import Foundation

/// The share formats of the app (SHARED-R20). Save image uses the Story picture.
enum ShareFormat: CaseIterable, Identifiable {
    case story, whatsApp

    var id: Self { self }

    var chip: String {
        switch self {
        case .story: String(localized: "Story", bundle: .module)
        case .whatsApp: String(localized: "WhatsApp", bundle: .module)
        }
    }

    var action: String {
        switch self {
        case .story: String(localized: "Share to Instagram", bundle: .module)
        case .whatsApp: String(localized: "Send on WhatsApp", bundle: .module)
        }
    }

    /// The card on screen; the image is four times larger (1080 px wide).
    var cardSize: CGSize {
        switch self {
        case .story: CGSize(width: 270, height: 480)  // 9:16
        case .whatsApp: CGSize(width: 270, height: 338) // 4:5
        }
    }

    static let renderScale: CGFloat = 4
}
