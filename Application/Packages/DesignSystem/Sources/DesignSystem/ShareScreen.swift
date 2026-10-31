import SwiftUI
import UIKit

/// The share sheet of the app (SHARED-R20): the card in Story or WhatsApp shape, "Share to Instagram" or
/// "Send on WhatsApp" through the system sheet, "Save image" to Photos, and "Not now". Every action ends with
/// `onFinish`.
public struct ShareScreen<Card: View>: View {
    var title: String
    /// Sent with the picture on WhatsApp.
    var message: String
    var card: (ShareFormat) -> Card
    var onFinish: () -> Void

    @State private var format: ShareFormat = .story
    @State private var sharedImage: SharedImage?

    public init(title: String, message: String, @ViewBuilder card: @escaping (ShareFormat) -> Card,
                onFinish: @escaping () -> Void) {
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
            VStack(spacing: 0) {
                Text(title.uppercased())
                    .font(UVVAFont.sans(9))
                    .tracking(2.7)
                    .opacity(0.6)
                    .frame(height: 30)

                Spacer(minLength: 12)
                card(format)
                    .shadow(color: .black.opacity(0.55), radius: 30, y: 26)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(UVVAColor.creamFill.opacity(0.28), lineWidth: 0.5))
                    .animation(.smooth, value: format)
                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    ForEach(ShareFormat.allCases) { item in
                        FormatChip(title: item.chip, isSelected: item == format) { format = item }
                    }
                }
                .padding(.bottom, 22)
                ActionButton(format.action) { share() }
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
                onFinish()
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func render(_ format: ShareFormat) -> UIImage? {
        let renderer = ImageRenderer(content: card(format).environment(\.colorScheme, .dark))
        renderer.scale = ShareFormat.renderScale
        return renderer.uiImage
    }

    /// Story and WhatsApp go through the system share sheet, where Instagram and WhatsApp appear.
    private func share() {
        guard let image = render(format) else { return }
        sharedImage = SharedImage(image: image)
    }

    private func save() {
        if let image = render(.story) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        onFinish()
    }
}
