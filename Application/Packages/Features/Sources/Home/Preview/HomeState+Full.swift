import Core
import Foundation

extension HomeState {
    static let full = HomeState(
        firstName: "Elisa",
        palateMap: MockData.elisaMap,
        // No friends yet, so Home shows the invite card (HOME-R11).
        friends: [],
        courses: [MockData.foundations],
        lastRating: MockData.lastRating,
        ratedWineIDs: ["pontoforte"],
        catalog: MockData.catalog,
        glossary: MockData.glossary,
        notifications: [AppNotification(id: "n1", text: "Marina Alves mapped a palate. You are an 82% match.", isRead: false)]
    )
}
