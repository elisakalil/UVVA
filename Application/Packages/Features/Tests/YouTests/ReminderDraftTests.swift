import Core
import Testing
@testable import You

struct ReminderDraftTests {
    // MARK: YOU-R18 · Guardar

    @Test func YOU_R18_momentWithoutDays_cannotSave() {
        var draft = ReminderDraft(nil)
        draft.pick(.dinner)
        #expect(!draft.canSave)
    }

    @Test func YOU_R18_momentAndDays_saveAtThatHour() {
        var draft = ReminderDraft(nil)
        draft.pick(.dinner)
        [2, 4, 6].forEach { draft.toggle($0) }
        #expect(draft.canSave)
        #expect(draft.reminder == Reminder(hour: 19, weekdays: [2, 4, 6]))
        #expect(draft.reminder?.time == "19:00")
    }

    @Test func D8_anyTime_canBeSaved() {
        var draft = ReminderDraft(nil)
        draft.pickTime(hour: 20, minute: 15)
        draft.toggle(1)
        #expect(draft.reminder?.time == "20:15")
        #expect(draft.moment == nil)
    }

    // MARK: YOU-R19 · Desligar

    @Test func YOU_R19_turnOff_savesNothing() {
        var draft = ReminderDraft(Reminder(hour: 8, weekdays: [2]))
        #expect(draft.moment == .coffee)
        draft.turnOff()
        #expect(draft.canSave)
        #expect(draft.reminder == nil)
        #expect(draft.weekdays.isEmpty)
    }

    @Test func picking_afterTurningOff_turnsItBackOn() {
        var draft = ReminderDraft(nil)
        draft.turnOff()
        draft.pick(.lunch)
        #expect(!draft.isOff)
    }
}
