import Testing
@testable import Onboarding

struct OnboardingFlowTests {
    private func flow(at step: OnboardingStep) -> OnboardingFlow {
        var flow = OnboardingFlow()
        if step == .welcome { return flow }
        flow.signedIn()
        flow.accountLookedUp(exists: false)
        if step == .name { return flow }
        flow.next()
        if step == .phone { return flow }
        flow.next()
        if step == .findFriends { return flow }
        flow.contactsAnswered(granted: true)
        return flow
    }

    // MARK: ONB-R29, R27 · Depois do login

    @Test func ONB_R29_newAccount_goesToTheName() {
        #expect(flow(at: .name).step == .name)
    }

    @Test func ONB_R27_existingAccount_leavesTheOnboarding() {
        var flow = OnboardingFlow()
        flow.signedIn()
        #expect(flow.step == .lookingUpAccount)
        flow.accountLookedUp(exists: true)
        #expect(flow.step == .done)
    }

    // MARK: ONB-R08 · Legal

    @Test func ONB_R08_legal_opensFromTheWelcome_andGoesBack() {
        var flow = OnboardingFlow()
        flow.openLegal(.privacy)
        #expect(flow.step == .legal(.privacy))
        flow.back()
        #expect(flow.step == .welcome)
    }

    // MARK: ONB-R36a, R21 · Contatos

    @Test func ONB_R36a_contactsGranted_opensContacts() {
        #expect(flow(at: .contacts).step == .contacts)
    }

    @Test func ONB_R36a_contactsDenied_endsTheOnboarding() {
        var flow = flow(at: .findFriends)
        flow.contactsAnswered(granted: false)
        #expect(flow.step == .done)
    }

    @Test func ONB_R21_nextOnContacts_endsTheOnboarding() {
        var flow = flow(at: .contacts)
        flow.next()
        #expect(flow.step == .done)
    }

    // MARK: ONB-R20 · Voltar

    @Test func ONB_R20_back() {
        var name = flow(at: .name)
        name.back()
        #expect(name.step == .welcome)

        var phone = flow(at: .phone)
        phone.back()
        #expect(phone.step == .name)

        var friends = flow(at: .findFriends)
        #expect(!friends.canGoBack)
        friends.back()
        #expect(friends.step == .findFriends)

        var contacts = flow(at: .contacts)
        contacts.back()
        #expect(contacts.step == .findFriends)
    }
}
