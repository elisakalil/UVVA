import DesignSystem
import SwiftUI

/// The Quiz, from the Intro to the share sheet. The app decides where to go on `onExit`.
public struct QuizView: View {
    @State private var viewModel: QuizViewModel

    public init(viewModel: QuizViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            switch viewModel.screen {
            case .loading:
                UVVAColor.moss.ignoresSafeArea()
            case let .intro(model):
                QuizIntroView(model: model, isReady: viewModel.bank != nil,
                              onStart: { withAnimation(.smooth) { viewModel.start() } },
                              onLeave: viewModel.leave)
                    .transition(.opacity)
            case let .reading(model):
                QuizReadingView(model: model,
                                onSelect: { position in withAnimation(.smooth(duration: 0.28)) { viewModel.select(position) } },
                                onChangeQuestion: { withAnimation(.smooth) { viewModel.changeQuestion() } },
                                onNext: { withAnimation(.smooth) { viewModel.next() } },
                                onBack: { withAnimation(.smooth) { viewModel.back() } })
                    .transition(.opacity)
            case let .result(model):
                QuizResultView(model: model,
                               onKeep: { Task { await viewModel.keep() } },
                               onReadAgain: { withAnimation(.smooth) { viewModel.readAgain() } },
                               onBack: { withAnimation(.smooth) { viewModel.back() } })
                    .transition(.opacity)
            case let .share(model):
                QuizShareView(model: model, onFinish: viewModel.finish)
                    .transition(.opacity)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .task { await viewModel.load() }
    }
}
