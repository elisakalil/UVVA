import Core
import Foundation
import Observation

/// Runs the Onboarding: sign-in, name, phone, friends (ONBOARDING.md). The app decides what comes after.
@MainActor @Observable
public final class OnboardingViewModel {
    private(set) var flow = OnboardingFlow()

    // Welcome
    private(set) var iCloudAvailable: Bool?
    private(set) var isSigningIn = false
    /// A short message on the Welcome when the sign-in could not reach the network (ONB-R38, D21).
    private(set) var notice: String?

    // Draft (nothing is kept before the Phone step, ONB-R02a)
    private(set) var identity: AuthIdentity?
    var name = ""
    private(set) var country: PhoneCountry
    private(set) var phoneDigits = ""
    private(set) var isSaving = false
    private(set) var profile: Profile?

    // Contacts
    private(set) var isLoadingContacts = false
    private(set) var contactsOnUVVA: [(contact: DeviceContact, account: PublicProfile)] = []
    private(set) var contactsToInvite: [DeviceContact] = []
    private(set) var requested: Set<String> = []
    private(set) var invited: Set<String> = []
    /// What the Contacts search bar holds; both lists are narrowed to names that contain it.
    var contactsQuery = ""

    private let auth: any Authenticating
    private let profiles: any ProfileRepository
    private let maps: any PalateMapRepository
    private let social: any SocialService
    private let cloud: any CloudAccountStatus
    private let contacts: any ContactsProviding
    private let homeCountry: PhoneCountry
    private let lookUpTimeout: Duration
    private let onFinish: (OnboardingResult) -> Void

    public init(auth: any Authenticating, profiles: any ProfileRepository, maps: any PalateMapRepository,
                social: any SocialService, cloud: any CloudAccountStatus, contacts: any ContactsProviding,
                homeCountry: PhoneCountry = PhoneCountries.defaultCountry(), lookUpTimeout: Duration = .seconds(4),
                onFinish: @escaping (OnboardingResult) -> Void) {
        self.auth = auth
        self.profiles = profiles
        self.maps = maps
        self.social = social
        self.cloud = cloud
        self.contacts = contacts
        self.homeCountry = homeCountry
        self.country = homeCountry
        self.lookUpTimeout = lookUpTimeout
        self.onFinish = onFinish
    }

    var step: OnboardingStep { flow.step }

    func back() {
        if flow.step == .name { identity = nil }
        flow.back()
    }

    // MARK: Welcome

    /// UVVA needs iCloud for the account and for friends (ARCHITECTURE §7).
    func checkICloud() async {
        iCloudAvailable = await cloud.isAvailable()
    }

    func openLegal(_ tab: LegalTab) { flow.openLegal(tab) }

    /// "Continue with Apple" (ONB-R29, R31, R38).
    func signIn() async {
        guard iCloudAvailable == true, !isSigningIn else { return }
        isSigningIn = true
        notice = nil
        defer { isSigningIn = false }
        let identity: AuthIdentity
        do {
            guard let signedIn = try await auth.signIn() else { return }
            identity = signedIn
        } catch {
            notice = String(localized: "Could not reach Apple. Check your connection and try again.", bundle: .module)
            return
        }
        self.identity = identity
        flow.signedIn()
        if let existing = try? await profiles.profile(authUserID: identity.userID, waitingUpTo: lookUpTimeout) {
            let hasMap = ((try? await maps.currentMap()) ?? nil) != nil
            flow.accountLookedUp(exists: true)
            onFinish(.existingAccount(existing, hasMap: hasMap))
        } else {
            name = identity.givenName ?? ""
            flow.accountLookedUp(exists: false)
        }
    }

    // MARK: Name

    var nameIsValid: Bool { NameValidator.isValid(name) }

    func continueFromName() {
        guard nameIsValid else { return }
        name = NameValidator.normalized(name)
        flow.next()
    }

    // MARK: Phone

    /// Room for a trunk prefix on top of the longest national number.
    private var maxDigits: Int { country.nationalLength.upperBound + (country.trunkPrefix?.count ?? 0) }

    var phoneE164: String? { PhoneNumber.e164(national: phoneDigits, country: country) }

    func press(_ digit: Character) {
        guard digit.isNumber, phoneDigits.count < maxDigits else { return }
        phoneDigits.append(digit)
    }

    func deleteDigit() {
        guard !phoneDigits.isEmpty else { return }
        phoneDigits.removeLast()
    }

    func select(_ country: PhoneCountry) {
        self.country = country
        if phoneDigits.count > maxDigits { phoneDigits = String(phoneDigits.prefix(maxDigits)) }
    }

    /// "Continue" (ONB-R07).
    func continueWithPhone() async {
        guard let phone = phoneE164 else { return }
        await startSession(phone: phone)
    }

    /// "Skip for now" (ONB-R35).
    func skipPhone() async {
        await startSession(phone: nil)
    }

    /// ONB-R02a: the account exists from here on. The contact key and the public profile are published when
    /// the network allows; a failure does not stop the sign-up.
    private func startSession(phone: String?) async {
        guard let identity, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        let profile = Profile(id: UUID().uuidString.lowercased(), authProvider: identity.provider,
                              authUserID: identity.userID, firstName: name, phone: phone)
        do {
            try await profiles.save(profile)
        } catch {
            notice = String(localized: "Your account could not be saved. Try again.", bundle: .module)
            return
        }
        self.profile = profile
        flow.next()
        let social = social
        Task.detached {
            if let phone { _ = try? await social.publishContactKey(phone: phone, userID: profile.id) }
            try? await social.publish(PublicProfile(id: profile.id, firstName: profile.firstName, map: nil, hasMap: false))
        }
    }

    // MARK: Find friends and Contacts

    /// "Continue" asks for the contacts (ONB-R36a).
    func findFriends() async {
        let granted = await contacts.requestAccess()
        flow.contactsAnswered(granted: granted)
        if flow.step == .done { finishNewAccount() } else { await loadContacts() }
    }

    /// FRI-R01: only accounts with a map are listed as on UVVA; the person never lists themself.
    func loadContacts() async {
        isLoadingContacts = true
        defer { isLoadingContacts = false }
        let all = ((try? await contacts.fetch()) ?? []).filter { !$0.displayName.isEmpty }
        var phonesOf: [String: [String]] = [:]
        for contact in all {
            phonesOf[contact.id] = contact.phones.compactMap { PhoneNumber.e164(contact: $0, home: homeCountry) }
        }
        let accounts = (try? await social.accounts(forPhones: Array(Set(phonesOf.values.joined())))) ?? [:]
        var onUVVA: [(DeviceContact, PublicProfile)] = []
        var toInvite: [DeviceContact] = []
        for contact in all {
            let account = phonesOf[contact.id]?.lazy.compactMap { accounts[$0] }.first
            if let account {
                if account.hasMap, account.id != profile?.id { onUVVA.append((contact, account)) }
            } else {
                toInvite.append(contact)
            }
        }
        let byName: (DeviceContact, DeviceContact) -> Bool = {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
        contactsOnUVVA = onUVVA.sorted { byName($0.0, $1.0) }.map { (contact: $0.0, account: $0.1) }
        contactsToInvite = toInvite.sorted(by: byName)
    }

    /// "Add" sends a friend request (FRI-R08).
    func add(_ contactID: String) async {
        guard let profile, let row = contactsOnUVVA.first(where: { $0.contact.id == contactID }),
              !requested.contains(contactID) else { return }
        requested.insert(contactID)
        do {
            try await social.sendFriendRequest(from: profile.id, to: row.account.id)
        } catch {
            requested.remove(contactID)
        }
    }

    /// "Invite" turns to "Invited" once the share sheet opens (ONB-R37).
    func markInvited(_ contactID: String) { invited.insert(contactID) }

    var inviteMessage: String {
        String(localized: "Map your taste in wine with me on UVVA.", bundle: .module)
    }

    var inviteLink: URL? { profile?.inviteLink }

    /// "Next" (ONB-R21).
    func finishContacts() {
        flow.next()
        finishNewAccount()
    }

    private func finishNewAccount() {
        guard let profile else { return }
        onFinish(.newAccount(profile))
    }

    // MARK: Screen models

    var phoneModel: PhoneUIModel {
        PhoneUIModel(country: country, dialCode: "+" + country.callingCode,
                     number: phoneDigits.isEmpty ? Self.example(for: country) : PhoneNumber.grouped(phoneDigits),
                     isEmpty: phoneDigits.isEmpty, canContinue: phoneE164 != nil, isSaving: isSaving)
    }

    /// ONB-R03: "912 345 678" for Portugal; zeros of the right length elsewhere.
    static func example(for country: PhoneCountry) -> String {
        country.region == "PT" ? "912 345 678"
            : PhoneNumber.grouped(String(repeating: "0", count: country.nationalLength.upperBound))
    }

    /// Whether a contact's name contains the search, ignoring case and accents ("jose" finds "José").
    private func matchesQuery(_ contact: DeviceContact) -> Bool {
        let query = contactsQuery.trimmingCharacters(in: .whitespaces)
        return query.isEmpty || contact.displayName.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    var contactsModel: ContactsUIModel {
        let onUVVA = contactsOnUVVA.filter { matchesQuery($0.contact) }.map { row in
            ContactRowUIModel(id: row.contact.id, name: row.contact.displayName, initials: row.contact.initials,
                              note: row.account.map?.signature, letter: row.contact.indexLetter,
                              state: requested.contains(row.contact.id) ? .requested : .add)
        }
        let toInvite = contactsToInvite.filter(matchesQuery).map { contact in
            ContactRowUIModel(id: contact.id, name: contact.displayName, initials: contact.initials, note: nil,
                              letter: contact.indexLetter,
                              state: invited.contains(contact.id) ? .invited : .invite)
        }
        // Counted before the search, so the titles keep telling the whole picture.
        let count = contactsOnUVVA.count
        let onUVVATitle = count == 1 ? String(localized: "1 of your contacts is on UVVA", bundle: .module)
                                     : String(localized: "\(count) of your contacts are on UVVA", bundle: .module)
        // With nobody on UVVA that section is left out, and so is the screen's title.
        let title = count == 0 && !isLoadingContacts ? nil : String(localized: "Contacts", bundle: .module)
        var letters: [String] = []
        for row in toInvite where letters.last != row.letter { letters.append(row.letter) }
        let isSearching = !contactsQuery.trimmingCharacters(in: .whitespaces).isEmpty
        return ContactsUIModel(isLoading: isLoadingContacts, title: title, onUVVATitle: onUVVATitle, onUVVA: onUVVA,
                               toInvite: toInvite, letters: letters,
                               noResults: isSearching && onUVVA.isEmpty && toInvite.isEmpty)
    }
}
