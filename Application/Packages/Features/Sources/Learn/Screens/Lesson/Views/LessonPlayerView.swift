import DesignSystem
import SwiftUI

/// The lesson player, over the whole app: the cover, then one step at a time (LEARN.md §4).
struct LessonPlayerView<ViewModel: LessonPlayerViewModelProtocol>: View {
    private var resources: LearnResourcesUIModel { viewModel.uiModel.resources }
    @ObservedObject var viewModel: ViewModel
    /// "Lesson complete", over the Summary for a moment after it opens.
    @State private var showsCompleteNote = false

    /// How far the player follows a drag down, and whether the step is scrolled to its top, where that drag can start.
    @State private var dragDown: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var isClosing = false
    @State private var isAtTop = true
    @State private var clink = ToastClink()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How long "Lesson complete" stays.
    private static var completeNoteTime: Duration { .seconds(2.5) }
    /// A drag down past this, or flung past twice this, leaves the lessons.
    private static var closeDistance: CGFloat { 140 }

    var body: some View {
        let ink = viewModel.uiModel.isTip ? LessonPalette.wine : LessonPalette.ink
        ZStack {
            if viewModel.uiModel.isTip {
                LessonPalette.ink.ignoresSafeArea()
            } else {
                LessonBackground()
            }
            VStack(spacing: 0) {
                if !viewModel.uiModel.isCover {
                    LessonTopBar(resources: resources, model: viewModel.uiModel.header, ink: ink, onBack: viewModel.back)
                        .padding(.horizontal, 22)
                        .padding(.top, 6)
                }
                ScrollView {
                    content
                        // The intro starts lower; step and Summary spacing stays independent.
                        .padding(.top, viewModel.uiModel.isCover ? 56 : (viewModel.uiModel.header.current == nil ? 24 : 44))
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
                .id(viewModel.uiModel.stepIndex ?? -1)
                footer
            }
            if showsCompleteNote, case let .summary(model)? = viewModel.uiModel.stepModel {
                LessonCompleteNote(text: model.completion)
                    .padding(.top, 64)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .offset(y: -28).combined(with: .opacity),
                        removal: .offset(y: -16).combined(with: .opacity)))
            }
            if let certificate = viewModel.uiModel.certificate {
                ShareScreen(title: resources.shareWhatYouLearnedText, message: certificate.message) { format in
                    CertificateCard(model: certificate, format: format)
                } onFinish: {
                    viewModel.closeCertificate()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: viewModel.uiModel.stepIndex)
        .task(id: viewModel.uiModel.isSummary) {
            guard viewModel.uiModel.isSummary else { showsCompleteNote = false; return }
            // The Summary is saved first, behind the grapes; this runs once it is really on screen. It settles, the
            // note comes down slowly, and the glasses touch as it lands.
            do {
                try await Task.sleep(for: .milliseconds(200))
                withAnimation(reduceMotion ? .easeOut(duration: 0.3) : .smooth(duration: 0.7)) { showsCompleteNote = true }
                try await Task.sleep(for: .milliseconds(260))
                clink.play()
                try await Task.sleep(for: Self.completeNoteTime)
            } catch { return }
            withAnimation(.easeIn(duration: 0.45)) { showsCompleteNote = false }
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.uiModel.certificate != nil)
        .lessonSensory(viewModel.uiModel.sensory)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewportHeight = $0 }
        .allowsHitTesting(!isClosing)
        .offset(y: dragDown)
        .simultaneousGesture(dragToClose, isEnabled: viewModel.uiModel.certificate == nil)
        .accessibilityAction(.escape, viewModel.close)
        .preferredColorScheme(.dark)
    }

    /// Dragging the player down leaves the lessons, like closing a sheet. It starts only with the step at its top,
    /// so it never takes over a scroll back up.
    private var dragToClose: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onChanged { drag in
                guard !isClosing else { return }
                let down = drag.translation.height
                guard isAtTop || dragDown > 0, down > 0, down > abs(drag.translation.width) else { return }
                dragDown = down
            }
            .onEnded { drag in
                guard !isClosing, dragDown > 0 else { return }
                if dragDown > Self.closeDistance || drag.predictedEndTranslation.height > 2 * Self.closeDistance {
                    isClosing = true
                    withAnimation(.easeOut(duration: 0.22)) {
                        dragDown = max(viewportHeight, dragDown) + 100
                    } completion: {
                        // The custom drag has already moved the lesson offscreen.
                        var transaction = Transaction(animation: nil)
                        transaction.disablesAnimations = true
                        withTransaction(transaction) { viewModel.close() }
                    }
                } else {
                    withAnimation(.spring(duration: 0.3)) { dragDown = 0 }
                }
            }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.uiModel.stepModel {
        case nil:
            LessonCoverView(resources: resources, model: viewModel.uiModel.cover)
        case let .concept(title, body, highlight)?:
            ConceptStepView(title: title, bodyText: body, highlight: highlight)
        case let .tip(body)?:
            TipStepView(bodyText: body)
        case let .choice(model)?:
            ChoiceStepView(resources: resources, model: model, onTap: viewModel.tapOption)
        case let .fillBlank(model)?:
            FillBlankStepView(model: model, onTap: viewModel.tapWord)
        case let .ordering(model)?:
            OrderingStepView(model: model, onTap: viewModel.tapRow)
        case let .matchPairs(model)?:
            MatchPairsStepView(resources: resources, model: model, onTapLeft: viewModel.tapLeft, onTapRight: viewModel.tapRight)
        case let .summary(model)?:
            SummaryStepView(resources: resources, model: model)
        }
    }

    @ViewBuilder private var footer: some View {
        switch viewModel.uiModel.footer {
        case let .feedback(model):
            FeedbackPanel(resources: resources, model: model, onContinue: viewModel.primary)
        case let .button(title, isEnabled):
            LessonButton(title: title, style: viewModel.uiModel.isTip ? .onTip : .filled, isEnabled: isEnabled) {
                if viewModel.uiModel.isCover { viewModel.begin() } else { viewModel.primary() }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
    }
}
