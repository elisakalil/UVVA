import MessageUI
import SwiftUI

/// An invite waiting in Messages: who it goes to, the text with the link, and the picture.
struct InviteMessage: Identifiable {
    let id = UUID()
    var rowID: String
    var phone: String
    var text: String
    var image: Data?
}

/// iOS's own message sheet, filled in (ONB-R37a). The user still taps Send: an app cannot send an SMS by itself.
/// Without Messages on the device (`canSend` is false, as in the Simulator) the invite goes through the share sheet.
struct MessageComposer: UIViewControllerRepresentable {
    var message: InviteMessage
    /// True once it is sent.
    var onFinish: (Bool) -> Void

    static var canSend: Bool { MFMessageComposeViewController.canSendText() }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = [message.phone]
        controller.body = message.text
        if let image = message.image, MFMessageComposeViewController.canSendAttachments() {
            controller.addAttachmentData(image, typeIdentifier: "public.jpeg", filename: "UVVA.jpg")
        }
        return controller
    }

    func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: (Bool) -> Void

        init(onFinish: @escaping (Bool) -> Void) { self.onFinish = onFinish }

        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            onFinish(result == .sent)
        }
    }
}
