import Foundation

/// The four moments offered for the reminder (YOU-R17). Any other time can be picked as well (D8).
public enum ReminderMoment: CaseIterable, Sendable {
    case coffee, lunch, dinner, late

    public var hour: Int {
        switch self {
        case .coffee: 8
        case .lunch: 13
        case .dinner: 19
        case .late: 22
        }
    }

    /// The moment at exactly this time, if any.
    public static func matching(hour: Int, minute: Int) -> ReminderMoment? {
        minute == 0 ? allCases.first { $0.hour == hour } : nil
    }
}
