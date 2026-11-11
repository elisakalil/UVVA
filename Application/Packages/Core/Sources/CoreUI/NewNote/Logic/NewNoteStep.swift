import Foundation

/// Where the new note is (CELLAR.md §4).
enum NewNoteStep: Equatable {
    /// Asking the system for the camera, on the first `+` (CELLAR-R15).
    case checkingCamera
    /// "The camera is off" (CELLAR-R22).
    case cameraDenied
    /// "Photograph the front", then "Now the back label" (CELLAR-R16).
    case front
    case back
    /// "Reading your label" (CELLAR-R17).
    case reading
    /// "We couldn't read your label" (CELLAR-R21).
    case readFailed
    /// "Fill in by hand" (CELLAR-R23).
    case manual
    /// The wine on paper, with "Have you had this wine?" (CELLAR-R18).
    case note
}
