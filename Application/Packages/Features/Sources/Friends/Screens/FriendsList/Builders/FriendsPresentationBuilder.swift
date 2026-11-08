import Core
import Foundation
import Match

/// The Friends tab from its content. Pure: the compatibility and the signature come from Match (FRI §3).
struct FriendsPresentationBuilder {
    var content: FriendsContentModel
    var resources: FriendsResourcesUIModel

    /// FRI-R04: by name, with the signature and the compatibility with the user.
    var friends: [FriendRowUIModel] {
        content.snapshot.friends
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { friend in
                let compatibility = content.user.map { TableMatch.compatibility($0.map, friend.map) } ?? 0
                return FriendRowUIModel(id: friend.id, name: friend.name, signature: MapReading(map: friend.map).signature,
                                        compatibilityText: resources.compatibility(compatibility))
            }
    }

    var countText: String { resources.count(content.snapshot.friends.count) }

    /// FRI-R08a: newest first.
    var requests: [FriendRequestRowUIModel] {
        content.snapshot.incoming
            .sorted { $0.sentAt > $1.sentAt }
            .map { FriendRequestRowUIModel(id: $0.id, name: $0.name, signature: MapReading(map: $0.map).signature) }
    }

    /// FRI-R07, R07a, R08.
    var quickAdd: QuickAddState {
        switch content.contactsAccess {
        case .notDetermined: return .askAccess
        case .denied: return .openSettings
        case .granted:
            let friendIDs = Set(content.snapshot.friends.map(\.id))
            let rows = content.suggestions
                .filter { !friendIDs.contains($0.id) }
                .map { suggestion in
                    QuickAddRowUIModel(id: suggestion.id, name: suggestion.contactName,
                                       signature: MapReading(map: suggestion.map).signature,
                                       isRequested: content.snapshot.requested.contains(suggestion.id))
                }
            return rows.isEmpty ? .noSuggestions : .suggestions(rows)
        }
    }

    /// FRI-R06: nothing to list, so the invite shows.
    var isEmpty: Bool { content.snapshot.friends.isEmpty && content.snapshot.incoming.isEmpty }

    var toastText: String? { content.newFriendName.map(resources.newFriend) }

    /// FRI-R18: inactive below two.
    func selectButtonText(selected: Int) -> String {
        selected < 2 ? resources.pickAtLeastTwoText : resources.findBottle(selected)
    }

    /// D6: once the table is full, and there are friends left out.
    func tableFullText(selected: Int, limit: Int) -> String? {
        selected >= limit && content.snapshot.friends.count > limit ? resources.tableFull(limit) : nil
    }

    var invite: FriendsInviteUIModel? {
        guard let user = content.user else { return nil }
        let reading = MapReading(map: user.map)
        return FriendsInviteUIModel(title: resources.inviteTitleText, message: resources.inviteMessage(user.inviteLink),
                                    heading: resources.inviteHeadingText, name: user.firstName,
                                    phrase: reading.dominantPhrase, chartValues: user.map.chartValues,
                                    strongAxes: Set(reading.highlighted.compactMap { PalateAxis.allCases.firstIndex(of: $0) }))
    }
}
