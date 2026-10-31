import Foundation

extension HomeCard {
    var isHalfWidth: Bool {
        switch self {
        case .continueLesson, .changedMapCard: true
        default: false
        }
    }
}
