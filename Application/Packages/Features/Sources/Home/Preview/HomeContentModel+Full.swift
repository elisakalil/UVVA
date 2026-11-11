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
        notifications: [AppNotification(id: "n1", text: "Marina Alves mapped a palate. You are an 82% match.", isRead: false)]
    )
}
