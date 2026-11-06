import UIKit

/// Hands the rendered Story to Instagram. Returns false when native sharing should be used instead.
@MainActor
enum InstagramStorySharing {
    // TODO: Set the UVVA numeric Meta App ID in UVVA_META_APP_ID for Debug and Release.
    // Until configured, Instagram sharing falls back to the iOS share sheet.
    // See Documentation/App/Features/Home/INSTAGRAM-SHARING.md.
    static func open(_ image: UIImage) async -> Bool {
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String,
              !appID.isEmpty, appID.allSatisfy({ $0.isASCII && $0.isNumber }),
              let url = URL(string: "instagram-stories://share?source_application=\(appID)"),
              UIApplication.shared.canOpenURL(url),
              let data = image.pngData()
        else { return false }

        UIPasteboard.general.setItems(
            [["com.instagram.sharedSticker.backgroundImage": data]],
            options: [.expirationDate: Date().addingTimeInterval(300), .localOnly: true]
        )
        // Opening the editor does not confirm that a Story was published.
        return await UIApplication.shared.open(url, options: [:])
    }
}
