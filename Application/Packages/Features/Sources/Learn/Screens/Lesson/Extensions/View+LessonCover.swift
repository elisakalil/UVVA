import DesignSystem
import SwiftUI
import UIKit

extension View {
    @ViewBuilder
    public func lessonCover<ViewModel: LearnViewModelProtocol>(
        _ learn: ViewModel?, onPresented: @escaping () -> Void = {}
    ) -> some View {
        if let learn { modifier(LearnLessonCover(viewModel: learn, onPresented: onPresented)) }
        else { self }
    }
}

private struct LearnLessonCover<ViewModel: LearnViewModelProtocol>: ViewModifier {
    @State private var holdsLoadingPresentation = false
    @State private var loadingCycle = 0
    @State private var wasLoading = false
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: ViewModel
    var onPresented: () -> Void

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: Binding(
            get: { viewModel.uiModel.isPresentingPlayer || holdsLoadingPresentation }, set: { _ in }
        )) {
            LessonModalContent(viewModel: viewModel, loadingCycle: loadingCycle, holdsPresentation: $holdsLoadingPresentation)
            .background(LessonPresentationObserver(onPresented: onPresented))
            .presentationBackground(.clear)
            .preferredColorScheme(.dark)
        }
        .onReceive(viewModel.lessonLoadingPublisher) { loading in
            if loading && !wasLoading {
                holdsLoadingPresentation = true
                loadingCycle += 1
            }
            wasLoading = loading
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                Task { @MainActor in
                    let application = UIApplication.shared
                    let task = application.beginBackgroundTask(withName: "Save lesson progress")
                    await viewModel.saveLessonOnBackground()
                    if task != .invalid { application.endBackgroundTask(task) }
                }
            }
        }
    }
}

/// The visual loading gate is independent of I/O: it never delays or blocks persistence.
/// It holds the existing presentation until both the read/save and one grape cycle finish.
private struct LessonModalContent<ViewModel: LearnViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    let loadingCycle: Int
    @Binding var holdsPresentation: Bool
    @State private var showsLoading = true
    @State private var completedCycle: Int?

    var body: some View {
        ZStack {
            LessonBackground()
            if showsLoading || viewModel.uiModel.isLoadingLesson {
                GrapeLoop(startsAtFirstFrame: true)
                    .id(loadingCycle)
                    .frame(width: 60, height: 84)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .bottom) {
                        Text(String(localized: "saving your progress", bundle: .module))
                            .font(UVVAFont.sans(12))
                            .foregroundStyle(UVVAColor.cream84)
                            .padding(.bottom, 32)
                    }
            } else if let error = viewModel.uiModel.lessonError {
                VStack(spacing: 20) {
                    Text(error).multilineTextAlignment(.center)
                    Button(String(localized: "Try again", bundle: .module)) {
                        Task { await viewModel.retryLesson() }
                    }
                    Button(String(localized: "Back", bundle: .module)) { viewModel.cancelLessonLoading() }
                }.padding(32)
            } else if let player = viewModel.player {
                LessonPlayerView(viewModel: player).id(player.id)
            }
        }
        .task(id: loadingCycle) {
            showsLoading = true
            completedCycle = nil
            holdsPresentation = true
            do { try await Task.sleep(for: .seconds(GrapeLoop.cycleDuration)) }
            catch { return }
            guard !Task.isCancelled else { return }
            completedCycle = loadingCycle
            if !viewModel.uiModel.isLoadingLesson {
                showsLoading = false
                holdsPresentation = false
            }
        }
        .onChange(of: viewModel.uiModel.isLoadingLesson) { _, loading in
            if !loading && completedCycle == loadingCycle {
                showsLoading = false
                holdsPresentation = false
            }
        }
    }
}

/// SwiftUI's onAppear precedes the presentation animation. UIKit signals when it has finished.
private struct LessonPresentationObserver: UIViewControllerRepresentable {
    var onPresented: () -> Void

    func makeUIViewController(context: Context) -> Observer {
        Observer(onPresented: onPresented)
    }

    func updateUIViewController(_ controller: Observer, context: Context) {
        controller.onPresented = onPresented
    }

    final class Observer: UIViewController {
        var onPresented: () -> Void

        init(onPresented: @escaping () -> Void) {
            self.onPresented = onPresented
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func loadView() {
            view = UIView()
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onPresented()
        }
    }
}
