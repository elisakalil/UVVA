import DesignSystem
import SwiftUI

/// The lesson player, over the whole app: the cover, then one step at a time (LEARN.md §4).
struct LessonPlayerView: View {
    var viewModel: LessonPlayerViewModel
    /// "Lesson complete", over the Summary for a moment after it opens.
    @State private var showsCompleteNote = false

    /// How far the player follows a drag down, and whether the step is scrolled to its top, where that drag can start.
    @State private var dragDown: CGFloat = 0
    @State private var isAtTop = true

    /// How long "Lesson complete" stays.
    private static let completeNoteTime: Duration = .seconds(2.5)
    /// A drag down past this, or flung past twice this, leaves the lessons.
    private static let closeDistance: CGFloat = 140

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
                        // More room under the step dots than under the bare top bar of the cover and the Summary.
                        .padding(.top, viewModel.header.current == nil ? 24 : 44)
                        .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                // A step that fits does not stretch under the drag that closes the player.
                .scrollBounceBehavior(.basedOnSize)
                .scrollEdgeFade(16)
                .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top <= 1 } action: { _, top in
                    isAtTop = top
                }
                // Each step opens at its top.
                .id(viewModel.stepIndex ?? -1)
                footer
            }
            if showsCompleteNote, case let .summary(model)? = viewModel.stepModel {
                LessonCompleteNote(text: model.completion)
                    .padding(.top, 64)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
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
        .animation(.easeOut(duration: 0.3), value: showsCompleteNote)
        .task(id: viewModel.isSummary) {
            guard viewModel.isSummary else { showsCompleteNote = false; return }
            showsCompleteNote = true
            try? await Task.sleep(for: Self.completeNoteTime)
            showsCompleteNote = false
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.certificate != nil)
        .offset(y: dragDown)
        .simultaneousGesture(dragToClose, isEnabled: viewModel.certificate == nil)
        .accessibilityAction(.escape, viewModel.close)
        .preferredColorScheme(.dark)
    }

    /// Dragging the player down leaves the lessons, like closing a sheet. It starts only with the step at its top,
    /// so it never takes over a scroll back up.
    private var dragToClose: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onChanged { drag in
                let down = drag.translation.height
                guard isAtTop || dragDown > 0, down > 0, down > abs(drag.translation.width) else { return }
                dragDown = down
            }
            .onEnded { drag in
                guard dragDown > 0 else { return }
                if dragDown > Self.closeDistance || drag.predictedEndTranslation.height > 2 * Self.closeDistance {
                    viewModel.close()
                } else {
                    withAnimation(.spring(duration: 0.3)) { dragDown = 0 }
                }
            }
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

    @ViewBuilder private var footer: some View {
        switch viewModel.footer {
        case let .feedback(model):
            FeedbackPanel(model: model, onContinue: viewModel.primary)
        case let .button(title, isEnabled):
            VStack(spacing: 10) {
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
