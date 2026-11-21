import Core
import Foundation
import Match

/// The Friends tab from its content. Pure: the compatibility and the signature come from Match (FRI §3).
struct FriendsPresentationBuilder {
    var content: FriendsContentModel
    var resources: FriendsResourcesUIModel

    /// FRI-R04: by name, with the signature and the compatibility with the user.
    /// "Search by name" keeps only the friends whose name holds the query, ignoring case and accents.
    func friends(matching query: String) -> [FriendRowUIModel] {
        let query = query.trimmingCharacters(in: .whitespaces)
        return content.snapshot.friends
            .filter { query.isEmpty || $0.name.localizedStandardContains(query) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { friend in
                let compatibility = content.user.map { TableMatch.compatibility($0.map, friend.map) } ?? 0
                return FriendRowUIModel(id: friend.id, name: friend.name, signature: MapReading(map: friend.map).signature,
                                        compatibilityText: resources.compatibility(compatibility))
            }
    }

    var countText: String { resources.count(content.snapshot.friends.count) }

    /// FRI-R04b: who the user added (a request not answered yet), then who they invited (not on UVVA yet), each by
    /// name. An added contact goes by the name in the address book when Quick add knows it.
    var pending: [PendingFriendRowUIModel] {
        let friendIDs = Set(content.snapshot.friends.map(\.id))
        let contactNames = Dictionary(content.suggestions.map { ($0.id, $0.contactName) }) { first, _ in first }
        let added = content.snapshot.requested
            .subtracting(friendIDs)
            .compactMap { id -> PendingFriendRowUIModel? in
                guard let name = contactNames[id] ?? content.snapshot.requestedNames[id] else { return nil }
                return PendingFriendRowUIModel(id: "added-\(id)", name: name, statusText: resources.addedText.uppercased())
            }
        let invited = content.invites.map {
            PendingFriendRowUIModel(id: "invited-\($0.id)", name: $0.name, statusText: resources.invitedText.uppercased())
        }
        return byName(added) + byName(invited)
    }

    private func byName(_ rows: [PendingFriendRowUIModel]) -> [PendingFriendRowUIModel] {
        rows.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// FRI-R08a: newest first.
    var requests: [FriendRequestRowUIModel] {
        content.snapshot.incoming
            .sorted { $0.sentAt > $1.sentAt }
            .map { FriendRequestRowUIModel(id: $0.id, name: $0.name, signature: MapReading(map: $0.map).signature) }
    }

    /// FRI-R11c: "Sent to you", newest first.
    var received: [ReceivedWineRowUIModel] {
        content.received.map {
            ReceivedWineRowUIModel(id: $0.id, title: resources.sentYouAWine($0.fromName), wineName: $0.wine.name)
        }
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
