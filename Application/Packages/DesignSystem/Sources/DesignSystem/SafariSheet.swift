import SafariServices
import SwiftUI

/// A web page inside the app, in Safari's own view, so the person never leaves UVVA.
public struct SafariSheet: UIViewControllerRepresentable {
    var url: URL

    public init(url: URL) { self.url = url }

    public func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(red: 0x2B / 255, green: 0x31 / 255, blue: 0x26 / 255, alpha: 1)
        return controller
    }

    public func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
