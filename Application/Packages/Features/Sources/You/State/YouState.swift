import Observation

@MainActor @Observable
final class YouState {
    var content = YouContent()
}
