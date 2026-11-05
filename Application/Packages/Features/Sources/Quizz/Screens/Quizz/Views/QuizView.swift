import DesignSystem
import SwiftUI

public struct QuizView<ViewModel: QuizViewModelProtocol>: View {
    private var resources: QuizResourcesUIModel { viewModel.uiModel.resources }
    @ObservedObject private var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            switch viewModel.uiModel.screen {
            case .loading:
                UVVAColor.moss.ignoresSafeArea()
            case let .intro(model):
                QuizIntroView(model: model, isReady: viewModel.uiModel.isReady,
                              onStart: { withAnimation(.smooth) { viewModel.start() } },
                              onLeave: viewModel.leave)
                    .transition(.opacity)
            case let .reading(model):
                QuizReadingView(resources: resources, model: model,
                                onSelect: { position in withAnimation(.smooth(duration: 0.28)) { viewModel.select(position) } },
                                onChangeQuestion: { withAnimation(.smooth) { viewModel.changeQuestion() } },
                                onNext: { withAnimation(.smooth) { viewModel.next() } },
                                onBack: { withAnimation(.smooth) { viewModel.back() } })
                    .transition(.opacity)
            case let .result(model):
                QuizResultView(resources: resources, model: model,
                               onKeep: { Task { await viewModel.keep() } },
                               onReadAgain: { withAnimation(.smooth) { viewModel.readAgain() } },
                               onBack: { withAnimation(.smooth) { viewModel.back() } })
                    .transition(.opacity)
            case let .share(model):
                QuizShareView(resources: resources, model: model, onFinish: viewModel.finish)
                    .transition(.opacity)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
    }
}

#Preview {
    QuizView(viewModel: MockQuizViewModel())
}
