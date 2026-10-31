import DesignSystem
import SwiftUI
import UIKit

/// "Share your map" (QUIZ-R19, R20). Every action, "Not now" included, ends the Quiz (QUIZ-R25).
struct QuizShareView: View {
    var model: QuizShareUIModel
    var onFinish: () -> Void

    @State private var format: ShareFormat = .story
    @State private var sharedImage: SharedImage?

    var body: some View {
        ZStack {
            QuizBackground(photoOpacity: 0.5, shade: [0.55, 0.82])
            VStack(spacing: 0) {
                Text(String(localized: "Share your map", bundle: .module).uppercased())
                    .font(UVVAFont.sans(9))
                    .tracking(2.7)
                    .opacity(0.6)
                    .frame(height: 30)

                Spacer(minLength: 12)
                MapShareCard(model: model, format: format)
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
        .sheet(item: $sharedImage) { shared in
            ActivityShareSheet(image: shared.image, message: format == .whatsApp ? model.message : nil) {
                sharedImage = nil
                onFinish()
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func render(_ format: ShareFormat) -> UIImage? {
        let renderer = ImageRenderer(content: MapShareCard(model: model, format: format)
            .environment(\.colorScheme, .dark))
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
