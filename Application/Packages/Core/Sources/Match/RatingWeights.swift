import Core

/// How far one rating moves the map towards the wine (QUIZ-R22). Kept in one place so they can be tuned.
public enum RatingWeights {
    public static func weight(for verdict: Verdict) -> Double {
        switch verdict {
        case .yes: 0.10
        case .maybe: 0.03
        case .no: -0.10
        }
    }
}
