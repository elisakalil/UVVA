import DesignSystem
import SwiftUI

/// "How UVVA works" (QUIZ-R06).
struct QuizIntroView: View {
    var model: QuizIntroUIModel
    var isReady: Bool
    var onStart: () -> Void
    var onLeave: () -> Void

    var body: some View {
        ZStack {
            // The photo almost whole, as in the Onboarding, under a lighter shade than the Quiz result's.
            QuizBackground(photoOpacity: 0.95, shade: [0.2, 0.5])
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if model.canLeave {
                        FlowTopBar(caption: "", onBack: onLeave).padding(.bottom, 14)
                    }
                    Text(model.greeting.uppercased())
                        .font(UVVAFont.sans(9))
                        .tracking(2.7)
                        .opacity(0.7)
                    Text(model.title)
                        .font(UVVAFont.sans(32, .ultraLight))
                        .tracking(-0.5)
                        .lineSpacing(2)
                        .frame(maxWidth: 300, alignment: .leading)
                        .padding(.top, 34)
                    Text(model.body)
                        .font(UVVAFont.sans(12))
                        .lineSpacing(6)
                        .opacity(0.86)
                        .frame(maxWidth: 300, alignment: .leading)
                        .padding(.top, 28)
                    AnimatedPalateMap()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(model.steps) { step in
                            QuizIntroStepRow(step: step)
                        }
                    }
                    .padding(.top, 40)
                    Text(model.length.uppercased())
                        .font(UVVAFont.sans(9))
                        .tracking(1.8)
                        .opacity(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 44)
                }
                .padding(.horizontal, 26)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeFade()
            // Fixed at the foot of the screen; the text scrolls up clear of it.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ActionButton(model.button, isEnabled: isReady, action: onStart)
                    .shadow(color: Color(hex: 0x12180E).opacity(0.45), radius: 15, y: 10)
                    .padding(.horizontal, 26)
                    .padding(.bottom, 12)
            }
        }
    }
}
