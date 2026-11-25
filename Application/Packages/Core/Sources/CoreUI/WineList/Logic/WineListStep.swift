import Foundation

/// Where the wine list is (WINELIST.md): the camera, the three questions, the wines to order and the line to say.
enum WineListStep: Equatable {
    /// Asking the system for the camera, the first time.
    case checkingCamera
    /// The camera is off: the list cannot be read.
    case cameraDenied
    /// "Scan · Wine list": the pages, read one by one (WINELIST-R03).
    case capture
    /// "What's on the table?" (WINELIST-R06).
    case questions
    /// "Order this" (WINELIST-R07).
    case results
    /// "Say it or show it" (WINELIST-R08).
    case ask
}
