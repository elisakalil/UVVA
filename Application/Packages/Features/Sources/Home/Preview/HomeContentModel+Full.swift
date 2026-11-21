import Core
import Foundation

extension HomeContentModel {
    static let full = HomeContentModel(
        firstName: "Elisa",
        palateMap: MockData.elisaMap,
        friends: [],
        courses: [MockData.foundations],
        lastRating: MockData.lastRating,
        ratedVerdicts: ["pontoforte": .yes],
        catalog: MockData.catalog,
        glossary: MockData.glossary,
        notifications: [AppNotification(id: "n1", kind: .newFriend(friendID: "marina", name: "Marina", compatibility: 82), date: .now, isRead: false)]
    )
}
