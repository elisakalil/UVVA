import Combine

@MainActor
final class LearnState: ObservableObject {
    @Published var content = LearnContent()
}
