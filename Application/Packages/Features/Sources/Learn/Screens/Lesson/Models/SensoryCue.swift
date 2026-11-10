import Foundation

/// A moment of the lesson the hand should feel. A small vocabulary, each cue always tied to the same moment, so the
/// feedback reads as intended rather than as noise.
enum SensoryCue: Equatable {
    /// An option, a word, a row or a term picked.
    case select
    /// Two ordering rows swapped.
    case swap
    /// A matchPairs pair linked.
    case pair
    /// A matchPairs try that is not a pair.
    case miss
    /// "Check", answered right; also the last matchPairs pair.
    case correct
    /// "Check", answered wrong. Softer than the right answer, never a buzz.
    case wrong
    /// The Summary reached: the clink of the toast, felt when "Lesson complete" lands, after the save.
    case toast
}

/// A cue and a count that changes on every emission, so the same cue twice in a row still fires.
struct SensoryEvent: Equatable {
    var cue: SensoryCue
    var id: Int
}
