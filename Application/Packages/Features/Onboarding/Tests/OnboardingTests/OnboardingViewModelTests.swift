import Core
import Foundation
import Testing
@testable import Onboarding

@MainActor
struct OnboardingViewModelTests {
    let apple = AuthIdentity(provider: .apple, userID: "apple-1", givenName: "Elisa")
    let portugal = PhoneCountries.country(region: "PT")!

    private func makeViewModel(auth: AuthStub? = nil, profiles: ProfileRepositorySpy = ProfileRepositorySpy(),
                               map: PalateMap? = nil, social: SocialSpy = SocialSpy(), cloud: CloudStub = CloudStub(),
                               contacts: ContactsStub = ContactsStub(),
                               onFinish: @escaping (OnboardingResult) -> Void = { _ in }) async -> OnboardingViewModel {
        let viewModel = OnboardingViewModel(auth: auth ?? AuthStub(identity: apple), profiles: profiles,
                                            maps: MapRepositoryStub(map: map), social: social, cloud: cloud,
                                            contacts: contacts, homeCountry: portugal, lookUpTimeout: .zero,
                                            onFinish: onFinish)
        await viewModel.checkICloud()
        return viewModel
    }

    private func type(_ digits: String, into viewModel: OnboardingViewModel) {
        digits.forEach(viewModel.press)
    }

    // MARK: ONB-R29, R14a · Login

    @Test func ONB_R14a_newAccount_opensTheName_filledWithTheProviderName() async {
        let viewModel = await makeViewModel()
        await viewModel.signIn()
        #expect(viewModel.step == .name)
        #expect(viewModel.name == "Elisa")
        #expect(viewModel.nameIsValid)
    }

    @Test func ONB_R14a_providerWithoutName_opensTheNameEmpty() async {
        let viewModel = await makeViewModel(auth: AuthStub(identity: AuthIdentity(provider: .apple, userID: "x", givenName: nil)))
        await viewModel.signIn()
        #expect(viewModel.name.isEmpty)
        #expect(!viewModel.nameIsValid)
    }

    @Test func ONB_R38_cancelledSheet_staysOnTheWelcomeWithoutMessage() async {
        let viewModel = await makeViewModel(auth: AuthStub(identity: nil))
        await viewModel.signIn()
        #expect(viewModel.step == .welcome)
        #expect(viewModel.notice == nil)
    }

    @Test func ONB_R38_networkFailure_showsANotice() async {
        let viewModel = await makeViewModel(auth: AuthStub(identity: nil, fails: true))
        await viewModel.signIn()
        #expect(viewModel.step == .welcome)
        #expect(viewModel.notice != nil)
    }

    @Test func iCloudRequired_withoutICloud_signInDoesNothing() async {
        let viewModel = await makeViewModel(cloud: CloudStub(available: false))
        await viewModel.signIn()
        #expect(viewModel.iCloudAvailable == false)
        #expect(viewModel.step == .welcome)
    }

    // MARK: ONB-R27 · Conta existente

    @Test func ONB_R27_existingAccountWithMap_endsWithItsMap() async {
        let existing = Profile(id: "u1", authProvider: .apple, authUserID: "apple-1", firstName: "Elisa", phone: nil)
        var result: OnboardingResult?
        let viewModel = await makeViewModel(profiles: ProfileRepositorySpy(existing: [existing]),
                                            map: PalateMap([.acidity: 5])) { result = $0 }
        await viewModel.signIn()
        #expect(result == .existingAccount(existing, hasMap: true))
    }

    // MARK: ONB-R20 · Voltar ao Welcome pede o login de novo

    @Test func ONB_R20_backFromTheName_forgetsTheSignIn() async {
        let viewModel = await makeViewModel()
        await viewModel.signIn()
        viewModel.back()
        #expect(viewModel.step == .welcome)
        #expect(viewModel.identity == nil)
    }

    // MARK: ONB-R16 · Nome guardado sem espaços

    @Test func ONB_R16_continue_trimsTheName() async {
        let viewModel = await makeViewModel()
        await viewModel.signIn()
        viewModel.name = "  Elisa "
        viewModel.continueFromName()
        #expect(viewModel.name == "Elisa")
        #expect(viewModel.step == .phone)
    }

    // MARK: ONB-R35, R05 · Telefone

    @Test func ONB_R35_emptyPhone_showsSkip_andTypingShowsContinue() async {
        let viewModel = await makeViewModel()
        #expect(viewModel.phoneModel.isEmpty)
        type("9", into: viewModel)
        #expect(!viewModel.phoneModel.isEmpty)
        #expect(!viewModel.phoneModel.canContinue)
    }

    @Test func ONB_R04_phone_stopsAtTheLongestNumber() async {
        let viewModel = await makeViewModel()
        type("9123456789", into: viewModel)
        #expect(viewModel.phoneModel.number == "912 345 678")
        #expect(viewModel.phoneModel.canContinue)
    }

    // MARK: ONB-R07, R02a · A sessão começa no Telefone

    @Test func ONB_R07_continue_savesTheE164Phone_andPublishesTheKey() async throws {
        let profiles = ProfileRepositorySpy()
        let social = SocialSpy()
        let viewModel = await makeViewModel(profiles: profiles, social: social)
        await viewModel.signIn()
        viewModel.continueFromName()
        type("912345678", into: viewModel)
        await viewModel.continueWithPhone()
        #expect(viewModel.step == .findFriends)
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
        let viewModel = await makeViewModel(profiles: profiles, social: social)
        await viewModel.signIn()
        viewModel.continueFromName()
        await viewModel.skipPhone()
        #expect(viewModel.step == .findFriends)
        #expect(profiles.saved.first?.phone == nil)
        try await Task.sleep(for: .milliseconds(50))
        #expect(social.publishedPhones.isEmpty)
    }

    // MARK: ONB-R36a, R37 · Amigos

    @Test func ONB_R36a_contactsDenied_endsWithTheNewAccount() async {
        var result: OnboardingResult?
        let viewModel = await makeViewModel(contacts: ContactsStub(granted: false)) { result = $0 }
        await viewModel.signIn()
        viewModel.continueFromName()
        await viewModel.skipPhone()
        await viewModel.findFriends()
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
        let viewModel = await makeViewModel(social: social, contacts: ContactsStub(contacts: contacts))
        await viewModel.signIn()
        viewModel.continueFromName()
        await viewModel.skipPhone()
        await viewModel.findFriends()
        let model = viewModel.contactsModel
        #expect(model.onUVVA.map(\.name) == ["Marina Alves"])
        #expect(model.onUVVATitle == "1 of your contacts is on UVVA")
        #expect(model.toInvite.map(\.name) == ["Ana Sequeira"])
        #expect(model.onUVVA.first?.note?.hasPrefix("ACIDITY") == true)
    }

    @Test func ONB_R37_add_sendsAFriendRequest_andSaysRequested() async {
        let social = SocialSpy(accounts: [
            "+351912000001": PublicProfile(id: "m", firstName: "Marina", map: PalateMap([:]), hasMap: true)
        ])
        let contacts = ContactsStub(contacts: [DeviceContact(id: "1", givenName: "Marina", familyName: "", phones: ["912000001"])])
        let viewModel = await makeViewModel(social: social, contacts: contacts)
        await viewModel.signIn()
        viewModel.continueFromName()
        await viewModel.skipPhone()
        await viewModel.findFriends()
        await viewModel.add("1")
        #expect(viewModel.contactsModel.onUVVA.first?.state == .requested)
        #expect(social.requests.count == 1)
        #expect(social.requests.first?.hasSuffix("->m") == true)
    }

    @Test func ONB_R37_invite_saysInvited() async {
        let contacts = ContactsStub(contacts: [DeviceContact(id: "3", givenName: "Ana", familyName: "", phones: ["912000003"])])
        let viewModel = await makeViewModel(contacts: contacts)
        await viewModel.signIn()
        viewModel.continueFromName()
        await viewModel.skipPhone()
        await viewModel.findFriends()
        viewModel.markInvited("3")
        #expect(viewModel.contactsModel.toInvite.first?.state == .invited)
        #expect(viewModel.inviteLink?.absoluteString.hasPrefix("https://uvva.app/invite/") == true)
    }
}
