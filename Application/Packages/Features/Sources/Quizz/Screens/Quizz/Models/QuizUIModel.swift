public struct QuizUIModel {
    var screen: QuizScreen = .loading
    var isReady = false
    var isSaving = false
    var failedToSave = false
    var isSharing = false
    var resources = QuizResourcesUIModel()
}
