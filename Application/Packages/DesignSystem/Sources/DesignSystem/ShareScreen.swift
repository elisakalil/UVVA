import SwiftUI
import UIKit

/// The share sheet of the app (SHARED-R20): the card in Story or WhatsApp shape, "Share to Instagram" or
/// Stories open in Instagram when configured; WhatsApp uses the system sheet.
/// Also offers "Save image" to Photos (the Story picture, or `savedCard`) and "Not now".
/// Invite previews stay open after sharing or saving when `dismissAfterAction` is false.
public struct ShareScreen<Card: View>: View {
    var title: String
    /// Sent with the picture on WhatsApp.
    var message: String
    var card: (ShareFormat) -> Card
    /// What "Save image" keeps, when it is not the Story picture (the shopping guide of a table, FRI-R21).
    var savedCard: (() -> AnyView)?
    var dismissAfterAction: Bool
    var showsMessage: Bool
    var isCertificate: Bool
    var onFinish: () -> Void

    @State private var format: ShareFormat = .story
    @State private var sharedImage: SharedImage?
    @State private var isSharing = false

    public init(title: String, message: String, showsMessage: Bool = false, isCertificate: Bool = false, dismissAfterAction: Bool = true,
                savedCard: (() -> AnyView)? = nil, @ViewBuilder card: @escaping (ShareFormat) -> Card,
                onFinish: @escaping () -> Void) {
        self.savedCard = savedCard
        self.isCertificate = isCertificate
        self.dismissAfterAction = dismissAfterAction
        self.showsMessage = showsMessage
        self.title = title
        self.message = message
        self.card = card
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            PageBackground(photoOpacity: 0.5, blur: 7)
            LinearGradient(colors: [Color(hex: 0x181E12).opacity(0.55), Color(hex: 0x181E12).opacity(0.82)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if isCertificate { CertificateBackground(dimmed: true).ignoresSafeArea() }
            VStack(spacing: 0) {
                Text(title.uppercased())
                    .overlay(alignment: .leading) {
                        if isCertificate {
                            Button(action: onFinish) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .light))
                                    .frame(width: 32, height: 30)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("Back", bundle: .module))
                            .offset(x: -48)
                        }
                    }
                    .font(UVVAFont.sans(9))
                    .tracking(2.7)
                    .opacity(0.6)
                    .frame(height: 30)

                Spacer(minLength: 12)
                card(format)
                    .scaleEffect(showsMessage ? 0.82 : 1)
                    .frame(width: format.cardSize.width * (showsMessage ? 0.82 : 1),
                           height: format.cardSize.height * (showsMessage ? 0.82 : 1))
                    .shadow(color: .black.opacity(0.55), radius: 30, y: 26)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(UVVAColor.creamFill.opacity(0.28), lineWidth: 0.5))
                    .animation(.smooth, value: format)
                if showsMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Message", bundle: .module).uppercased())
                            .font(UVVAFont.sans(8)).tracking(2).opacity(0.6)
                        Text(message)
                            .font(UVVAFont.sans(12)).lineSpacing(4)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(UVVAColor.creamFill.opacity(0.25), lineWidth: 0.5))
                    }
                    .padding(.top, 18)
                }
                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    ForEach(ShareFormat.allCases) { item in
                        FormatChip(title: item.chip, isSelected: item == format) { format = item }
                    }
                }
                .padding(.bottom, 22)
                ActionButton(format.action) { Task { await share() } }
                    .disabled(isSharing)
                HStack(spacing: 26) {
                    TextAction(String(localized: "Save image", bundle: .module), opacity: 0.45) { save() }
                    TextAction(String(localized: "Not now", bundle: .module), opacity: 0.72, action: onFinish)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 26)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .sheet(item: $sharedImage) { shared in
            ActivityShareSheet(image: shared.image, message: format == .whatsApp ? message : nil) {
                sharedImage = nil
                if dismissAfterAction { onFinish() }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func render(_ format: ShareFormat) -> UIImage? {
        let renderer = ImageRenderer(content: card(format).environment(\.colorScheme, .dark))
        renderer.scale = ShareFormat.renderScale
        return renderer.uiImage
    }

    private func share() async {
        guard !isSharing, let image = render(format) else { return }
        isSharing = true
        defer { isSharing = false }
        if format == .story, await InstagramStorySharing.open(image) {
            return
        }
        // WhatsApp, or fallback when Instagram is unavailable or lacks a Meta App ID.
        sharedImage = SharedImage(image: image)
    }

    private func save() {
        if let savedCard {
            let renderer = ImageRenderer(content: savedCard().environment(\.colorScheme, .dark))
            renderer.scale = ShareFormat.renderScale
            if let image = renderer.uiImage { UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil) }
        } else if let image = render(.story) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        if dismissAfterAction { onFinish() }
    }
}
