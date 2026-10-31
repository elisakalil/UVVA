import Core

/// The top-level screens of the app (ONB-R02).
enum AppRoute: Equatable {
    /// The Splash, while the stores open and the session is checked.
    case launching
    case onboarding
    case quiz(QuizEntry)
    /// The tabs; `showTour` after the first map (HOME-R29).
    case tabs(showTour: Bool)
}
