import SwiftUI
import UIKit

/// The system share sheet for an image and a message (SHARED-R20: Story, WhatsApp), or for an invite link.
/// `onFinish` runs when the sheet closes, whether something was shared or not.
public struct ActivityShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var onFinish: () -> Void

    public init(image: UIImage, message: String? = nil, onFinish: @escaping () -> Void) {
        self.items = [image] + (message.map { [$0] } ?? [])
        self.onFinish = onFinish
    }

    /// A message and a link, as in an invite (HOME-R11).
    public init(message: String, link: URL, onFinish: @escaping () -> Void) {
        self.items = [message, link]
        self.onFinish = onFinish
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in onFinish() }
        return controller
    }

    public func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
