import Combine

@MainActor
final class YouState: ObservableObject {
    @Published var content = YouContent()
}
