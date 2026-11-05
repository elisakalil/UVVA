import Observation

@MainActor @Observable
final class LearnState {
    var content = LearnContent()
}
