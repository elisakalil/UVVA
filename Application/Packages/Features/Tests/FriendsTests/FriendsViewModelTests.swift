import Core
import Foundation
import Testing
@testable import Friends

@MainActor
struct FriendsViewModelTests {
    let social = SocialFake()
    let repository = FriendsRepositoryFake()
    var contacts = ContactsFake()
    let marinaMap = PalateMap([.acidity: 8, .fruit: 7, .body: 6])

    func makeViewModel(contacts: ContactsFake? = nil, onFriendsChange: @escaping () -> Void = {},
                       onAddFriends: @escaping () -> Void = {}) -> FriendsViewModel {
        FriendsFactory(profiles: ProfilesStub(), maps: MapStub(), friends: repository, catalog: CatalogStub(),
                       social: social,
                       contacts: contacts ?? self.contacts,
                       homeCountry: PhoneCountries.country(region: "PT")!)
            .makeViewModel(onFriendsChange: onFriendsChange, onAddFriends: onAddFriends)
    }

    func friends(of me: String, _ name: String, map: PalateMap? = nil) {
        social.profile(name.lowercased(), name, map: map ?? marinaMap)
        social.request(me, name.lowercased())
        social.request(name.lowercased(), me)
    }

    // MARK: FRI-R04 · Lista

    @Test func FRI_R04_byName_withCount() async {
        for name in ["Marina", "Bia", "Rui"] { friends(of: "elisa", name) }
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(viewModel.uiModel.friends.map(\.name) == ["Bia", "Marina", "Rui"])
        #expect(viewModel.uiModel.countText == "3 friends")
        #expect(viewModel.uiModel.isEmpty == false)
    }

    @Test func search_keepsTheFriendsWhoseNameHoldsIt_ignoringCaseAndAccents() async {
        for name in ["Marina", "Mário", "Rui"] { friends(of: "elisa", name) }
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.updateQuery("mar")
        #expect(viewModel.uiModel.friends.map(\.name) == ["Marina", "Mário"])
        #expect(viewModel.uiModel.isSearching)
        viewModel.updateQuery("MARIO")
        #expect(viewModel.uiModel.friends.map(\.name) == ["Mário"])
        viewModel.updateQuery(" ")
        #expect(viewModel.uiModel.friends.count == 3)
        #expect(!viewModel.uiModel.isSearching)
    }

    @Test func search_endsWhenChoosingWhoComes() async {
        for name in ["Marina", "Bia"] { friends(of: "elisa", name) }
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.updateQuery("bia")
        viewModel.startSelecting()
        #expect(viewModel.uiModel.query.isEmpty)
        #expect(viewModel.uiModel.friends.count == 2)
    }

    @Test func FRI_R04_row_showsSignatureAndCompatibility() async {
        friends(of: "elisa", "Marina", map: PalateMap([.acidity: 7, .fruit: 6]))
        let viewModel = makeViewModel()
        await viewModel.load()
        let row = viewModel.uiModel.friends.first
        #expect(row?.signature == row?.signature.uppercased())
        #expect(row?.compatibilityText == "100%")
    }

    @Test func FRI_R01_friendWithoutAMap_isLeftOut() async {
        friends(of: "elisa", "Marina")
        social.profile("rui", "Rui", map: nil)
        social.request("elisa", "rui")
        social.request("rui", "elisa")
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(viewModel.uiModel.friends.map(\.name) == ["Marina"])
    }

    @Test func friends_areKeptOnTheDevice() async throws {
        friends(of: "elisa", "Marina")
        await makeViewModel().load()
        #expect(try await repository.friends().map(\.id) == ["marina"])
    }

    // MARK: FRI-R06 · Vazio

    @Test func FRI_R06_noFriendsNoRequests_isEmpty_withInvite() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(viewModel.uiModel.isEmpty)
        #expect(viewModel.uiModel.invite?.message.contains("https://uvva.app/invite/elisa") == true)
        viewModel.openInvite()
        #expect(viewModel.uiModel.isInviting)
        viewModel.closeInvite()
        #expect(viewModel.uiModel.isInviting == false)
    }

    // MARK: FRI-R08a · Pedidos recebidos

    @Test func FRI_R08a_request_showsWithSignature() async {
        social.profile("marina", "Marina", map: marinaMap)
        social.request("marina", "elisa")
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(viewModel.uiModel.requests.map(\.name) == ["Marina"])
        #expect(viewModel.uiModel.friends.isEmpty)
        #expect(viewModel.uiModel.isEmpty == false)
    }

    @Test func FRI_R08a_accept_makesAFriend_andSaysSo() async {
        social.profile("marina", "Marina Alves", map: marinaMap)
        social.request("marina", "elisa")
        var changes = 0
        let viewModel = makeViewModel(onFriendsChange: { changes += 1 })
        await viewModel.load()
        await viewModel.accept("marina")
        #expect(viewModel.uiModel.friends.map(\.name) == ["Marina Alves"])
        #expect(viewModel.uiModel.requests.isEmpty)
        #expect(viewModel.uiModel.toastText == "Marina Alves is now your friend.")
        #expect(social.requests.contains { $0.from == "elisa" && $0.to == "marina" })
        #expect(changes == 1)
    }

    @Test func FRI_R08a_accept_failing_putsTheRequestBack() async {
        social.profile("marina", "Marina", map: marinaMap)
        social.request("marina", "elisa")
        let viewModel = makeViewModel()
        await viewModel.load()
        social.failWrites()
        await viewModel.accept("marina")
        #expect(viewModel.uiModel.requests.map(\.id) == ["marina"])
        #expect(viewModel.uiModel.friends.isEmpty)
        #expect(viewModel.uiModel.toastText == nil)
    }

    @Test func FRI_R08a_decline_goes_withoutTellingTheSender() async throws {
        social.profile("marina", "Marina", map: marinaMap)
        social.request("marina", "elisa")
        let viewModel = makeViewModel()
        await viewModel.load()
        await viewModel.decline("marina")
        #expect(viewModel.uiModel.requests.isEmpty)
        #expect(social.requests.count == 1)
        #expect(try await repository.declinedRequests() == ["marina"])
        await viewModel.reload()
        #expect(viewModel.uiModel.requests.isEmpty)
    }

    // MARK: FRI-R04b · Adicionados e convidados

    @Test func FRI_R04b_added_isFadedAtTheEnd_byTheirContactName() async {
        friends(of: "elisa", "Marina")
        let viewModel = makeViewModel(contacts: sofiaContact())
        await viewModel.load()
        #expect(viewModel.uiModel.pending.isEmpty)
        await viewModel.add("sofia")
        #expect(viewModel.uiModel.friends.map(\.name) == ["Marina"])
        #expect(viewModel.uiModel.pending.map(\.name) == ["Sofia Reis"])
        #expect(viewModel.uiModel.pending.first?.statusText == "ADDED")
        await viewModel.cancelRequest("sofia")
        #expect(viewModel.uiModel.pending.isEmpty)
    }

    @Test func FRI_R04b_added_withoutQuickAdd_goesByTheirFirstName() async {
        social.profile("rui", "Rui")
        social.request("elisa", "rui")
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(viewModel.uiModel.pending.map(\.name) == ["Rui"])
        #expect(viewModel.uiModel.friends.isEmpty)
    }

    @Test func FRI_R04b_invited_followTheAdded_untilTheyJoin() async {
        social.profile("rui", "Rui")
        social.request("elisa", "rui")
        try? await repository.saveInvite(InvitedContact(id: "c2", name: "Carla Souza", phones: ["913 000 000"], invitedAt: .now))
        try? await repository.saveInvite(InvitedContact(id: "c3", name: "Bruno", phones: ["914 000 000"], invitedAt: .now))
        social.profile("bruno", "Bruno", phone: "+351914000000")
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(viewModel.uiModel.pending.map(\.name) == ["Rui", "Carla Souza"])
        #expect(viewModel.uiModel.pending.map(\.statusText) == ["ADDED", "INVITED"])
        // Bruno joined: his invite is forgotten.
        let left = try? await repository.invitedContacts()
        #expect(left?.map(\.id) == ["c2"])
    }

    // MARK: FRI-R07, R08, R09 · Quick add

    private func sofiaContact() -> ContactsFake {
        social.profile("sofia", "Sofia", map: marinaMap, phone: "+351912345678")
        return ContactsFake(contacts: [DeviceContact(id: "c1", givenName: "Sofia", familyName: "Reis", phones: ["912 345 678"])])
    }

    @Test func FRI_R07_contactOnUVVA_isSuggested_byTheirContactName() async {
        let viewModel = makeViewModel(contacts: sofiaContact())
        await viewModel.load()
        guard case let .suggestions(rows) = viewModel.uiModel.quickAdd else { Issue.record("no suggestions"); return }
        #expect(rows.map(\.name) == ["Sofia Reis"])
        #expect(rows.first?.isRequested == false)
    }

    @Test func FRI_R01_contactWithoutAMap_isNotSuggested() async {
        social.profile("sofia", "Sofia", map: nil, phone: "+351912345678")
        let contacts = ContactsFake(contacts: [DeviceContact(id: "c1", givenName: "Sofia", familyName: "", phones: ["912345678"])])
        let viewModel = makeViewModel(contacts: contacts)
        await viewModel.load()
        #expect(viewModel.uiModel.quickAdd == .noSuggestions)
    }

    @Test func FRI_R07_friendsAndPeopleWhoAsked_areNotSuggested() async {
        let contacts = sofiaContact()
        social.request("sofia", "elisa")
        let viewModel = makeViewModel(contacts: contacts)
        await viewModel.load()
        #expect(viewModel.uiModel.quickAdd == .noSuggestions)
        #expect(viewModel.uiModel.requests.map(\.id) == ["sofia"])
    }

    @Test func FRI_R08_add_isRequested_andNotAFriend() async {
        let viewModel = makeViewModel(contacts: sofiaContact())
        await viewModel.load()
        await viewModel.add("sofia")
        guard case let .suggestions(rows) = viewModel.uiModel.quickAdd else { Issue.record("no suggestions"); return }
        #expect(rows.first?.isRequested == true)
        #expect(viewModel.uiModel.friends.isEmpty)
        #expect(social.requests.contains { $0.from == "elisa" && $0.to == "sofia" })
    }

    @Test func FRI_R08_requested_staysAfterARefresh() async {
        let contacts = sofiaContact()
        social.request("elisa", "sofia")
        let viewModel = makeViewModel(contacts: contacts)
        await viewModel.load()
        guard case let .suggestions(rows) = viewModel.uiModel.quickAdd else { Issue.record("no suggestions"); return }
        #expect(rows.first?.isRequested == true)
    }

    @Test func FRI_R08_add_failing_goesBackToAdd() async {
        let viewModel = makeViewModel(contacts: sofiaContact())
        await viewModel.load()
        social.failWrites()
        await viewModel.add("sofia")
        guard case let .suggestions(rows) = viewModel.uiModel.quickAdd else { Issue.record("no suggestions"); return }
        #expect(rows.first?.isRequested == false)
    }

    @Test func D11_tappingRequested_takesTheRequestBack() async {
        let viewModel = makeViewModel(contacts: sofiaContact())
        await viewModel.load()
        await viewModel.add("sofia")
        await viewModel.cancelRequest("sofia")
        guard case let .suggestions(rows) = viewModel.uiModel.quickAdd else { Issue.record("no suggestions"); return }
        #expect(rows.first?.isRequested == false)
        #expect(social.requests.isEmpty)
    }

    @Test func FRI_R09_dismiss_removes_andIsNotSuggestedAgain() async {
        let viewModel = makeViewModel(contacts: sofiaContact())
        await viewModel.load()
        await viewModel.dismissSuggestion("sofia")
        #expect(viewModel.uiModel.quickAdd == .noSuggestions)
        #expect(social.requests.isEmpty)
        await viewModel.reload()
        #expect(viewModel.uiModel.quickAdd == .noSuggestions)
    }

    // MARK: FRI-R07a · Acesso aos contatos

    @Test func FRI_R07a_neverAsked_offersToAsk_thenSuggests() async {
        social.profile("sofia", "Sofia", map: marinaMap, phone: "+351912345678")
        let contacts = ContactsFake(access: .notDetermined,
                                    contacts: [DeviceContact(id: "c1", givenName: "Sofia", familyName: "", phones: ["912345678"])])
        let viewModel = makeViewModel(contacts: contacts)
        await viewModel.load()
        #expect(viewModel.uiModel.quickAdd == .askAccess)
        await viewModel.askForContacts()
        guard case .suggestions = viewModel.uiModel.quickAdd else { Issue.record("no suggestions"); return }
    }

    // MARK: FRI-R06 · Add friends to compare maps

    @Test func FRI_R06_addFriends_withAccess_opensTheContacts() async {
        var opened = 0
        let viewModel = makeViewModel(contacts: ContactsFake(access: .granted), onAddFriends: { opened += 1 })
        await viewModel.load()
        await viewModel.addFriends()
        #expect(opened == 1)
    }

    @Test func FRI_R07b_friends_butNobodyToAdd_invite_opensTheContacts() async {
        friends(of: "elisa", "Marina")
        var opened = 0
        let viewModel = makeViewModel(contacts: ContactsFake(access: .granted), onAddFriends: { opened += 1 })
        await viewModel.load()
        #expect(!viewModel.uiModel.isEmpty)
        #expect(viewModel.uiModel.quickAdd == .noSuggestions)
        await viewModel.addFriends()
        #expect(opened == 1)
    }

    @Test func FRI_R06_addFriends_neverAsked_asksFirst_thenOpens() async {
        var opened = 0
        let contacts = ContactsFake(access: .notDetermined)
        let viewModel = makeViewModel(contacts: contacts, onAddFriends: { opened += 1 })
        await viewModel.load()
        await viewModel.addFriends()
        #expect(contacts.access() == .granted)
        #expect(opened == 1)
    }

    @Test func FRI_R06_addFriends_refused_opensNothing() async {
        var opened = 0
        let viewModel = makeViewModel(contacts: ContactsFake(access: .notDetermined, grantOnRequest: false),
                                      onAddFriends: { opened += 1 })
        await viewModel.load()
        await viewModel.addFriends()
        #expect(opened == 0)
        #expect(viewModel.uiModel.quickAdd == .openSettings)
    }

    @Test func FRI_R07a_refused_offersTheSettings() async {
        let viewModel = makeViewModel(contacts: ContactsFake(access: .denied))
        await viewModel.load()
        #expect(viewModel.uiModel.quickAdd == .openSettings)
    }

    // MARK: D4 · Remoção pelo outro lado

    @Test func D4_friendWhoRemovedTheUser_goes_andTheUsersRequestIsDeleted() async {
        friends(of: "elisa", "Marina")
        let viewModel = makeViewModel()
        await viewModel.load()
        try? await social.deleteFriendRequest(from: "marina", to: "elisa")
        await viewModel.reload()
        #expect(viewModel.uiModel.friends.isEmpty)
        #expect(social.requests.isEmpty)
    }

    // MARK: Refresh

    @Test func load_readsThePublicDatabaseAtMostEveryInterval_reloadAlways() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        friends(of: "elisa", "Marina")
        await viewModel.load()
        #expect(viewModel.uiModel.friends.isEmpty)
        await viewModel.reload()
        #expect(viewModel.uiModel.friends.map(\.id) == ["marina"])
    }
}
