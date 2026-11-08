import Foundation

/// "01 Front" and "02 Back label" at the foot of the camera (CELLAR-R16).
struct NewNoteCaptureStepUIModel: Identifiable, Equatable {
    var number: String
    var label: String
    var isCurrent: Bool
    var isDone: Bool
    var id: String { number }
}
