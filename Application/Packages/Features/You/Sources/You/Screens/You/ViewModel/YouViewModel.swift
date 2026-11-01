import Core
import Foundation
import Match
import Observation

/// The You tab (YOU.md): the profile, its map over time and the account.
/// Lessons, the Cellar, tables and certificates come with their features; until then they count zero.
@MainActor @Observable
public final class YouViewModel {
    public var tab: YouTab = .progress
    private(set) var profile: Profile?
    private(set) var map: PalateMap?
    private(set) var history: [MapChange] = []
    private(set) var reminder: Reminder?
    private(set) var firstModule: CourseSummary?
    var selectedSnapshot: Int?
    private(set) var notice: String?
    private(set) var isWorking = false

    private let profiles: any ProfileRepository
    private let maps: any PalateMapRepository
    private let catalog: any CatalogRepository
    private let social: any SocialService
    private let reminders: any ReminderRepository
    private let scheduler: any ReminderScheduling
    private let now: () -> Date
    private let calendar: Calendar
    private let onRedoMap: () -> Void
    private let onOpenLearn: () -> Void
    private let onSignOut: () -> Void
    private let onAccountDeleted: () -> Void

    public init(profiles: any ProfileRepository, maps: any PalateMapRepository, catalog: any CatalogRepository,
                social: any SocialService, reminders: any ReminderRepository, scheduler: any ReminderScheduling,
                now: @escaping () -> Date = Date.init, calendar: Calendar = .current,
                onRedoMap: @escaping () -> Void, onOpenLearn: @escaping () -> Void,
                onSignOut: @escaping () -> Void, onAccountDeleted: @escaping () -> Void) {
        self.profiles = profiles
        self.maps = maps
        self.catalog = catalog
        self.social = social
        self.reminders = reminders
        self.scheduler = scheduler
        self.now = now
        self.calendar = calendar
        self.onRedoMap = onRedoMap
        self.onOpenLearn = onOpenLearn
        self.onSignOut = onSignOut
        self.onAccountDeleted = onAccountDeleted
    }

    public func load() async {
        profile = try? await profiles.currentProfile()
        map = (try? await maps.currentMap()) ?? nil
        history = (try? await maps.history()) ?? []
        reminder = (try? await reminders.reminder()) ?? nil
        firstModule = (try? await catalog.firstPathModule()) ?? nil
        selectedSnapshot = nil
    }

    // MARK: Header (YOU-R01)

    var header: YouHeaderUIModel {
        YouHeaderUIModel(name: profile?.firstName ?? "", signature: map?.signature ?? "", photo: profile?.photo)
    }

    // MARK: Progress (YOU-R04 to R07)

    var progress: ProgressUIModel {
        let zero = "0"
        let stats = [
            ProgressStat(value: zero, label: String(localized: "Grapes", bundle: .module)),
            ProgressStat(value: zero, label: String(localized: "Regions", bundle: .module)),
            ProgressStat(value: zero, label: String(localized: "Lessons", bundle: .module)),
            ProgressStat(value: zero, label: String(localized: "XP", bundle: .module)),
            ProgressStat(value: zero, label: String(localized: "Bottles", bundle: .module)),
            ProgressStat(value: zero, label: String(localized: "Certificates", bundle: .module))
        ]
        let module = firstModule
        return ProgressUIModel(
            stats: stats,
            specialist: String(localized: "Nothing to map yet. Finish your first course and this space starts filling in: the grapes you know, the regions you can place, and where you are strongest.", bundle: .module),
            suggestionEyebrow: String(localized: "A course for you", bundle: .module),
            suggestionTitle: module?.title ?? "",
            suggestionNote: module.map { String(localized: "\($0.lessonCount) lessons · \($0.minutes) min", bundle: .module) } ?? "",
            cta: String(localized: "Start the course", bundle: .module)
        )
    }

    func startCourse() { onOpenLearn() }

    // MARK: Map (YOU-R09 to R13)

    var snapshots: [MapSnapshot] { MapEvolution.snapshots(history: history, now: now(), calendar: calendar) }

    var mapModel: MapUIModel? {
        guard let map else { return nil }
        let reading = MapReading(map: map)
        let snapshots = snapshots
        let selected = min(selectedSnapshot ?? max(snapshots.count - 1, 0), max(snapshots.count - 1, 0))
        let chosen = snapshots.indices.contains(selected) ? snapshots[selected] : nil
        let comparison = chosen.flatMap { $0.kind == .today || snapshots.count == 1 ? nil : $0.map }
        let deltas = comparison.map { MapEvolution.deltas(from: $0, to: map) } ?? [:]
        return MapUIModel(
            readOn: history.last.map { String(localized: "Read \(Self.day($0.date))", bundle: .module) } ?? "",
            map: map,
            top3: reading.top3,
            caption: reading.caption,
            readings: PalateAxis.allCases.map { axis in
                let level = MapReading.level(map[axis])
                return MapReadingRow(name: axis.label, level: level, word: MapReading.levelWord(level),
                                     isStrong: reading.top3.contains(axis))
            },
            showsOverTime: history.contains { if case .rating = $0.cause { true } else { false } },
            snapshots: snapshots.enumerated().map { index, snapshot in
                SnapshotUIModel(id: index, label: Self.label(snapshot, calendar: calendar),
                                detail: Self.detail(snapshot), isNew: snapshot.kind == .today)
            },
            selected: selected,
            comparison: comparison,
            deltas: PalateAxis.allCases.map { axis in
                MapDeltaRow(name: axis.label, delta: Self.delta(deltas[axis] ?? 0))
            },
            lastChange: lastChange,
            narrative: reading.narrative
        )
    }

    func selectSnapshot(_ index: Int) { selectedSnapshot = index }

    func redoMap() { onRedoMap() }

    /// HOME-R16, shown on Over time after a rating.
    private var lastChange: String? {
        guard history.count >= 2, case .rating = history[history.count - 1].cause else { return nil }
        let before = PalateMap(history[history.count - 2].values)
        let after = PalateMap(history[history.count - 1].values)
        // Ties keep the canonical order (QUIZ-R02).
        let moved = PalateAxis.allCases.max { abs(after[$0] - before[$0]) < abs(after[$1] - before[$1]) }
        guard let axis = moved, abs(after[axis] - before[axis]) >= AxisChange.threshold else { return nil }
        return after[axis] > before[axis]
            ? String(localized: "Your last wine raised your \(axis.label.lowercased()).", bundle: .module)
            : String(localized: "Your last wine lowered your \(axis.label.lowercased()).", bundle: .module)
    }

    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    static func label(_ snapshot: MapSnapshot, calendar: Calendar) -> String {
        switch snapshot.kind {
        case .first: String(localized: "First", bundle: .module)
        case .endOfMonth: snapshot.date.formatted(.dateTime.month(.abbreviated))
        case .today: String(localized: "Today", bundle: .module)
        }
    }

    static func detail(_ snapshot: MapSnapshot) -> String {
        switch snapshot.kind {
        case .first: String(localized: "First map · 0 wines rated", bundle: .module)
        case .endOfMonth: String(localized: "\(snapshot.winesRated) wines rated", bundle: .module)
        case .today: String(localized: "Today · \(snapshot.winesRated) wines rated", bundle: .module)
        }
    }

    static func delta(_ value: Double) -> String {
        guard abs(value) >= 0.05 else { return "—" }
        return (value > 0 ? "+" : "−") + String(format: "%.1f", abs(value))
    }

    // MARK: Share (YOU-R12)

    var shareMessage: String {
        let link = profile?.inviteLink.absoluteString ?? "uvva.app"
        return String(localized: "This is my wine palate. Map yours on UVVA and we'll find the perfect wine to drink together. \(link)", bundle: .module)
    }

    // MARK: Settings (YOU-R14 to R27)

    var settings: SettingsUIModel {
        let isPublic = profile?.mapIsPublic ?? true
        return SettingsUIModel(
            name: profile?.firstName ?? "",
            signedInWith: profile?.authProvider == .google ? "Google" : "Apple",
            phone: profile?.phone.map(Self.displayPhone) ?? String(localized: "Add", bundle: .module),
            photo: profile?.photo,
            reminder: reminder?.time ?? String(localized: "Set a time", bundle: .module),
            mapVisibility: isPublic ? String(localized: "Public", bundle: .module) : String(localized: "Friends", bundle: .module),
            tables: "0",
            certificates: "0",
            mapIsPublic: isPublic,
            mapPublicNote: isPublic
                ? String(localized: "Anyone with your link can see your palate map.", bundle: .module)
                : String(localized: "Only friends you share a table with can see your map.", bundle: .module)
        )
    }

    /// "+351 912 345 678"
    static func displayPhone(_ e164: String) -> String {
        let digits = String(e164.dropFirst())
        guard let country = PhoneCountries.all.filter({ digits.hasPrefix($0.callingCode) })
            .max(by: { $0.callingCode.count < $1.callingCode.count }) else { return e164 }
        return "+\(country.callingCode) " + PhoneNumber.grouped(String(digits.dropFirst(country.callingCode.count)))
    }

    /// The phone as its country and national digits, for editing.
    var phoneParts: (country: PhoneCountry, national: String) {
        guard let phone = profile?.phone else { return (PhoneCountries.defaultCountry(), "") }
        let digits = String(phone.dropFirst())
        let country = PhoneCountries.all.filter { digits.hasPrefix($0.callingCode) }
            .max { $0.callingCode.count < $1.callingCode.count } ?? PhoneCountries.defaultCountry()
        return (country, String(digits.dropFirst(country.callingCode.count)))
    }

    /// YOU-R15: the name follows ONB-R15.
    func saveName(_ name: String) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, var profile else { return false }
        profile.firstName = trimmed
        return await save(profile, publish: true)
    }

    /// YOU-R15: a new number takes the old contact key back and publishes its own; an empty one removes it.
    func savePhone(national: String, country: PhoneCountry) async -> Bool {
        guard var profile else { return false }
        let phone: String?
        if national.isEmpty {
            phone = nil
        } else {
            guard let valid = PhoneNumber.e164(national: national, country: country) else { return false }
            phone = valid
        }
        let old = profile.phone
        profile.phone = phone
        guard await save(profile, publish: false) else { return false }
        if old != phone {
            let social = social
            let id = profile.id
            Task.detached {
                if let old { try? await social.removeContactKey(phone: old) }
                if let phone { _ = try? await social.publishContactKey(phone: phone, userID: id) }
            }
        }
        return true
    }

    func savePhoto(_ jpeg: Data) async {
        guard var profile else { return }
        profile.photo = jpeg
        _ = await save(profile, publish: false)
    }

    /// YOU-R22
    func setMapPublic(_ isPublic: Bool) async {
        guard var profile else { return }
        profile.mapIsPublic = isPublic
        _ = await save(profile, publish: true)
    }

    /// YOU-R18 to R20. The first reminder asks iOS for notifications.
    func saveReminder(_ reminder: Reminder?) async {
        if reminder != nil, self.reminder == nil { _ = await scheduler.requestPermission() }
        do {
            try await reminders.save(reminder)
        } catch {
            notice = String(localized: "The reminder could not be saved. Try again.", bundle: .module)
            return
        }
        self.reminder = reminder
        await scheduler.schedule(reminder)
    }

    private func save(_ profile: Profile, publish: Bool) async -> Bool {
        do {
            try await profiles.save(profile)
        } catch {
            notice = String(localized: "Your changes could not be saved. Try again.", bundle: .module)
            return false
        }
        self.profile = profile
        if publish {
            let social = social
            let map = map
            Task.detached {
                try? await social.publish(PublicProfile(id: profile.id, firstName: profile.firstName,
                                                        map: profile.mapIsPublic ? map : nil, hasMap: map != nil))
            }
        }
        return true
    }

    func openLearn() { onOpenLearn() }

    /// YOU-R26: the data stays; the session ends.
    func signOut() async {
        await scheduler.schedule(nil)
        onSignOut()
    }

    /// YOU-R27: the public records first, so nothing is left behind when the network fails; then everything
    /// kept on the device and in iCloud.
    func deleteAccount() async {
        guard let profile, !isWorking else { return }
        isWorking = true
        notice = nil
        defer { isWorking = false }
        do {
            try await social.deleteAccount(userID: profile.id, phone: profile.phone)
            try await profiles.deleteAccount()
        } catch {
            notice = String(localized: "Your account could not be deleted. Check your connection and try again.", bundle: .module)
            return
        }
        await scheduler.schedule(nil)
        onAccountDeleted()
    }
}
