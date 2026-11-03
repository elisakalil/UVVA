import Foundation

/// The top of the player: "Lesson 3 | TITLE", one dot per step and "03 / 06" (LEARN-R13).
struct StepHeaderUIModel: Equatable {
    var brand: String
    var title: String
    /// The step on screen, from 0; nil hides the dots (cover and Summary).
    var current: Int?
    var total: Int
    var counter: String
    /// On the first screen of the first lesson the back chevron leaves; elsewhere it goes to the screen before.
    var backLeaves: Bool
}
