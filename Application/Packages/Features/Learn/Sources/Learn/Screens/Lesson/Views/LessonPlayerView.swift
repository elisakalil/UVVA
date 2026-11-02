import DesignSystem
import SwiftUI

/// The lesson player, over the whole app: the cover, then one step at a time (LEARN.md §4).
struct LessonPlayerView: View {
    var viewModel: LessonPlayerViewModel

    var body: some View {
        let ink = viewModel.isTip ? LessonPalette.wine : LessonPalette.ink
        ZStack {
            if viewModel.isTip {
                LessonPalette.ink.ignoresSafeArea()
            } else {
                LessonBackground()
            }
            VStack(spacing: 0) {
                LessonTopBar(model: viewModel.header, ink: ink, onBack: viewModel.back)
                    .padding(.horizontal, 22)
                    .padding(.top, 6)
                ScrollView {
                    content
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollEdgeFade(16)
                // Each step opens at its top.
                .id(viewModel.stepIndex ?? -1)
                footer
            }
            if let certificate = viewModel.certificate {
                ShareScreen(title: String(localized: "Share what you learned", bundle: .module), message: certificate.message) { format in
                    CertificateCard(model: certificate, format: format)
                } onFinish: {
                    viewModel.closeCertificate()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: viewModel.stepIndex)
        .animation(.easeOut(duration: 0.25), value: viewModel.showsClose)
        .animation(.easeOut(duration: 0.3), value: viewModel.certificate != nil)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private var content: some View {
        switch viewModel.stepModel {
        case nil:
            LessonCoverView(model: viewModel.cover)
        case let .concept(title, body, highlight)?:
            ConceptStepView(title: title, bodyText: body, highlight: highlight)
        case let .tip(body)?:
            TipStepView(bodyText: body)
        case let .choice(model)?:
            ChoiceStepView(model: model, onTap: viewModel.tapOption)
        case let .fillBlank(model)?:
            FillBlankStepView(model: model, onTap: viewModel.tapWord)
        case let .ordering(model)?:
            OrderingStepView(model: model, onTap: viewModel.tapRow)
        case let .matchPairs(model)?:
            MatchPairsStepView(model: model, onTapLeft: viewModel.tapLeft, onTapRight: viewModel.tapRight)
        case let .summary(model)?:
            SummaryStepView(model: model)
        }
    }

    /// "Close", after two backs in a row.
    private var closeAction: (() -> Void)? {
        guard viewModel.showsClose else { return nil }
        return viewModel.close
    }

    @ViewBuilder private var footer: some View {
        switch viewModel.footer {
        case let .feedback(model):
            FeedbackPanel(model: model, onClose: closeAction, onContinue: viewModel.primary)
        case let .button(title, isEnabled):
            VStack(spacing: 10) {
                if viewModel.showsClose {
                    LessonButton(title: String(localized: "Close", bundle: .module), style: viewModel.isTip ? .clearOnTip : .clear,
                                 showsArrow: false, action: viewModel.close)
                }
                if viewModel.phase == .cover, viewModel.cover.showsReviewPrevious {
                    LessonButton(title: String(localized: "Review previous lesson", bundle: .module), style: .outline,
                                 showsArrow: false, action: viewModel.reviewPrevious)
                }
                LessonButton(title: title, style: viewModel.isTip ? .onTip : .filled, isEnabled: isEnabled) {
                    if viewModel.phase == .cover { viewModel.begin() } else { viewModel.primary() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
    }
}
