import Combine
import Core
import Foundation
import Testing
@testable import Onboarding

@MainActor
struct OnboardingModuleTests {
    let apple = AuthIdentity(provider: .apple, userID: "apple-1", givenName: "Elisa")
    let portugal = PhoneCountries.country(region: "PT")!

    private func makeModule(auth: AuthStub? = nil, profiles: ProfileRepositorySpy = ProfileRepositorySpy(),
                               map: PalateMap? = nil, social: SocialSpy = SocialSpy(), cloud: CloudStub = CloudStub(),
                               contacts: ContactsStub = ContactsStub(),
                               onFinish: @escaping (OnboardingResult) -> Void = { _ in }) async -> OnboardingModule {
        let module = OnboardingFactory(auth: auth ?? AuthStub(identity: apple), profiles: profiles,
                                            maps: MapRepositoryStub(map: map), social: social, cloud: cloud,
                                            contacts: contacts, homeCountry: portugal, lookUpTimeout: .zero)
            .makeModule(onFinish: onFinish)
        await module.welcome.checkICloud()
        return module
    }

    private func type(_ digits: String, into module: OnboardingModule) {
        digits.forEach(module.phone.press)
    }

    // MARK: ONB-R29, R14a · Login

    @Test func ONB_R14a_newAccount_opensTheName_filledWithTheProviderName() async {
        let module = await makeModule()
        await module.welcome.signIn()
        #expect(module.coordinator.step == .name)
        #expect(module.name.uiModel.name == "Elisa")
        #expect(module.name.uiModel.isValid)
    }

    @Test func ONB_R14a_providerWithoutName_opensTheNameEmpty() async {
        let module = await makeModule(auth: AuthStub(identity: AuthIdentity(provider: .apple, userID: "x", givenName: nil)))
        await module.welcome.signIn()
        #expect(module.name.uiModel.name.isEmpty)
        #expect(!module.name.uiModel.isValid)
    }

    @Test func ONB_R38_cancelledSheet_staysOnTheWelcomeWithoutMessage() async {
        let module = await makeModule(auth: AuthStub(identity: nil))
        await module.welcome.signIn()
        #expect(module.coordinator.step == .welcome)
        #expect(module.welcome.uiModel.notice == nil)
    }

    @Test func ONB_R38_networkFailure_showsANotice() async {
        let module = await makeModule(auth: AuthStub(identity: nil, fails: true))
        await module.welcome.signIn()
        #expect(module.coordinator.step == .welcome)
        #expect(module.welcome.uiModel.notice != nil)
    }

    @Test func iCloudRequired_withoutICloud_signInDoesNothing() async {
        let module = await makeModule(cloud: CloudStub(available: false))
        await module.welcome.signIn()
        #expect(module.welcome.uiModel.iCloudAvailable == false)
        #expect(module.coordinator.step == .welcome)
    }

    // MARK: ONB-R27 · Conta existente

    @Test func ONB_R27_existingAccountWithMap_endsWithItsMap() async {
        let existing = Profile(id: "u1", authProvider: .apple, authUserID: "apple-1", firstName: "Elisa", phone: nil)
        var result: OnboardingResult?
        let module = await makeModule(profiles: ProfileRepositorySpy(existing: [existing]),
                                            map: PalateMap([.acidity: 5])) { result = $0 }
        await module.welcome.signIn()
        #expect(result == .existingAccount(existing, hasMap: true))
    }

    // MARK: ONB-R20 · Voltar ao Welcome pede o login de novo

    @Test func ONB_R20_backFromTheName_forgetsTheSignIn() async {
        let module = await makeModule()
        await module.welcome.signIn()
        module.coordinator.back()
        #expect(module.coordinator.step == .welcome)
        #expect(module.draft.identity == nil)
    }

    // MARK: ONB-R16 · Nome guardado sem espaços

    @Test func ONB_R16_continue_trimsTheName() async {
        let module = await makeModule()
        await module.welcome.signIn()
        module.name.updateName("  Elisa ")
        module.name.continueFromName()
        #expect(module.name.uiModel.name == "Elisa")
        #expect(module.coordinator.step == .phone)
    }

    // MARK: ONB-R35, R05 · Telefone

    @Test func ONB_R35_emptyPhone_showsSkip_andTypingShowsContinue() async {
        let module = await makeModule()
        #expect(module.phone.uiModel.isEmpty)
        type("9", into: module)
        #expect(!module.phone.uiModel.isEmpty)
        #expect(!module.phone.uiModel.canContinue)
    }

    @Test func ONB_R04_phone_stopsAtTheLongestNumber() async {
        let module = await makeModule()
        type("9123456789", into: module)
        #expect(module.phone.uiModel.number == "912 345 678")
        #expect(module.phone.uiModel.canContinue)
    }

    // MARK: ONB-R07, R02a · A sessão começa no Telefone

    @Test func ONB_R07_continue_savesTheE164Phone_andPublishesTheKey() async throws {
        let profiles = ProfileRepositorySpy()
        let social = SocialSpy()
        let module = await makeModule(profiles: profiles, social: social)
        await module.welcome.signIn()
        module.name.continueFromName()
        type("912345678", into: module)
        await module.phone.continueWithPhone()
        #expect(module.coordinator.step == .findFriends)
        let saved = try #require(profiles.saved.first)
        #expect(saved.phone == "+351912345678")
        #expect(saved.firstName == "Elisa")
        #expect(UUID(uuidString: saved.id) != nil)
        try await Task.sleep(for: .milliseconds(50))
        #expect(social.publishedPhones == ["+351912345678"])
    }

    @Test func ONB_R35_skip_startsTheSessionWithoutPhoneOrKey() async throws {
        let profiles = ProfileRepositorySpy()
        let social = SocialSpy()
        let module = await makeModule(profiles: profiles, social: social)
        await module.welcome.signIn()
        module.name.continueFromName()
        await module.phone.skipPhone()
        #expect(module.coordinator.step == .findFriends)
        #expect(profiles.saved.first?.phone == nil)
        try await Task.sleep(for: .milliseconds(50))
        #expect(social.publishedPhones.isEmpty)
    }

    // MARK: ONB-R36a, R37 · Amigos

    @Test func ONB_R36a_contactsDenied_endsWithTheNewAccount() async {
        var result: OnboardingResult?
        let module = await makeModule(contacts: ContactsStub(granted: false)) { result = $0 }
        await module.welcome.signIn()
        module.name.continueFromName()
        await module.phone.skipPhone()
        await module.findFriends.findFriends()
        if module.coordinator.step == .contacts { await module.contacts.loadContacts() }
        guard case let .newAccount(profile) = result else { Issue.record("not finished"); return }
        #expect(profile.firstName == "Elisa")
    }

    @Test func ONB_R37_contacts_splitIntoOnUVVAAndToInvite_skippingAccountsWithoutMap() async {
        let contacts = [
            DeviceContact(id: "1", givenName: "Marina", familyName: "Alves", phones: ["912 000 001"]),
            DeviceContact(id: "2", givenName: "Rui", familyName: "Neves", phones: ["+351 912 000 002"]),
            DeviceContact(id: "3", givenName: "Ana", familyName: "Sequeira", phones: ["912 000 003"])
        ]
        let social = SocialSpy(accounts: [
            "+351912000001": PublicProfile(id: "m", firstName: "Marina", map: PalateMap([.acidity: 9]), hasMap: true),
            "+351912000002": PublicProfile(id: "r", firstName: "Rui", map: nil, hasMap: false)
        ])
        let module = await makeModule(social: social, contacts: ContactsStub(contacts: contacts))
        await module.welcome.signIn()
        module.name.continueFromName()
        await module.phone.skipPhone()
        await module.findFriends.findFriends()
        if module.coordinator.step == .contacts { await module.contacts.loadContacts() }
        let model = module.contacts.uiModel
        #expect(model.onUVVA.map(\.name) == ["Marina Alves"])
        #expect(model.onUVVATitle == "1 of your contacts is on UVVA")
        #expect(model.title == "Contacts")
        #expect(model.toInvite.map(\.name) == ["Ana Sequeira"])
        #expect(model.onUVVA.first?.note?.hasPrefix("ACIDITY") == true)
    }

    @Test func ONB_R37_noContactOnUVVA_noTitle() async {
        let contacts = ContactsStub(contacts: [DeviceContact(id: "1", givenName: "Ana", familyName: "", phones: ["912000003"])])
        let module = await makeModule(contacts: contacts)
        await module.welcome.signIn()
        module.name.continueFromName()
        await module.phone.skipPhone()
        await module.findFriends.findFriends()
        if module.coordinator.step == .contacts { await module.contacts.loadContacts() }
        let model = module.contacts.uiModel
        #expect(model.onUVVA.isEmpty)
        #expect(model.title == nil)
        #expect(model.toInvite.map(\.name) == ["Ana"])
    }

    @Test func ONB_R37_search_narrowsBothLists_ignoringCaseAndAccents() async {
        let contacts = [
            DeviceContact(id: "1", givenName: "Marina", familyName: "Alves", phones: ["912 000 001"]),
            DeviceContact(id: "2", givenName: "José", familyName: "Neves", phones: ["912 000 002"]),
            DeviceContact(id: "3", givenName: "Ana", familyName: "Sequeira", phones: ["912 000 003"])
        ]
        let social = SocialSpy(accounts: [
            "+351912000001": PublicProfile(id: "m", firstName: "Marina", map: PalateMap([.acidity: 9]), hasMap: true)
        ])
        let module = await makeModule(social: social, contacts: ContactsStub(contacts: contacts))
        await module.welcome.signIn()
        module.name.continueFromName()
        await module.phone.skipPhone()
        await module.findFriends.findFriends()
        if module.coordinator.step == .contacts { await module.contacts.loadContacts() }

        module.contacts.updateQuery("jose")
        #expect(module.contacts.uiModel.onUVVA.isEmpty)
        #expect(module.contacts.uiModel.toInvite.map(\.name) == ["José Neves"])
        #expect(module.contacts.uiModel.title == "Contacts")

        module.contacts.updateQuery("zz")
        #expect(module.contacts.uiModel.noResults)

        module.contacts.updateQuery("")
        #expect(module.contacts.uiModel.onUVVA.count == 1)
        #expect(module.contacts.uiModel.toInvite.count == 2)
        #expect(!module.contacts.uiModel.noResults)
    }

    @Test func ONB_R37_add_sendsAFriendRequest_andSaysRequested() async {
        let social = SocialSpy(accounts: [
            "+351912000001": PublicProfile(id: "m", firstName: "Marina", map: PalateMap([:]), hasMap: true)
        ])
        let contacts = ContactsStub(contacts: [DeviceContact(id: "1", givenName: "Marina", familyName: "", phones: ["912000001"])])
        let module = await makeModule(social: social, contacts: contacts)
        await module.welcome.signIn()
        module.name.continueFromName()
        await module.phone.skipPhone()
        await module.findFriends.findFriends()
        if module.coordinator.step == .contacts { await module.contacts.loadContacts() }
        await module.contacts.add("1")
        #expect(module.contacts.uiModel.onUVVA.first?.state == .requested)
        #expect(social.requests.count == 1)
        #expect(social.requests.first?.hasSuffix("->m") == true)
    }

    @Test func ONB_R37_invite_saysInvited() async {
        let contacts = ContactsStub(contacts: [DeviceContact(id: "3", givenName: "Ana", familyName: "", phones: ["912000003"])])
        let module = await makeModule(contacts: contacts)
        await module.welcome.signIn()
        module.name.continueFromName()
        await module.phone.skipPhone()
        await module.findFriends.findFriends()
        if module.coordinator.step == .contacts { await module.contacts.loadContacts() }
        module.contacts.markInvited("3")
        #expect(module.contacts.uiModel.toInvite.first?.state == .invited)
        #expect(module.contacts.uiModel.inviteLink?.absoluteString.hasPrefix("https://uvva.app/invite/") == true)
    }

    @Test func accountSaveFailure_keepsPhoneAndDraftWithoutPublishing() async {
        let profiles = ProfileRepositorySpy(failsToSave: true)
        let social = SocialSpy()
        let module = await makeModule(profiles: profiles, social: social)
        await module.welcome.signIn()
        module.name.continueFromName()
        await module.phone.skipPhone()

        #expect(module.coordinator.step == .phone)
        #expect(module.phone.uiModel.notice != nil)
        #expect(!module.phone.uiModel.isSaving)
        #expect(module.draft.profile == nil)
        #expect(module.draft.name == "Elisa")
        #expect(profiles.saved.isEmpty)
        #expect(social.publishedPhones.isEmpty)
    }

    @Test func backFromPhone_preservesNameAndNumber() async {
        let module = await makeModule()
        await module.welcome.signIn()
        module.name.continueFromName()
        type("912345678", into: module)
        module.phone.back()
        #expect(module.coordinator.step == .name)
        #expect(module.name.uiModel.name == "Elisa")
        module.name.continueFromName()
        #expect(module.phone.phoneE164 == "+351912345678")
    }

    @Test func finishingContacts_deliversTheResultOnce() async {
        var results: [OnboardingResult] = []
        let module = await makeModule { results.append($0) }
        await module.welcome.signIn()
        module.name.continueFromName()
        await module.phone.skipPhone()
        await module.findFriends.findFriends()
        module.contacts.finishContacts()
        module.contacts.finishContacts()
        #expect(module.coordinator.step == .done)
        #expect(results.count == 1)
    }


    @Test func nameUIModel_publishesProviderNameAndUserEdits() async {
        let module = await makeModule()
        var names: [String] = []
        let subscription = module.name.$uiModel.sink { names.append($0.name) }
        defer { subscription.cancel() }
        await module.welcome.signIn()
        #expect(names.last == "Elisa")
        module.name.updateName(" Lisa ")
        #expect(module.draft.name == " Lisa ")
        #expect(names.last == " Lisa ")
        module.name.continueFromName()
        #expect(names.last == "Lisa")
        #expect(module.draft.name == "Lisa")
    }

}
