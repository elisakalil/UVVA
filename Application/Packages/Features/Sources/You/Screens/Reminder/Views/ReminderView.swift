import Core
import DesignSystem
import SwiftUI

/// Daily reminder (YOU-R16 to R20): a moment or any time, the days, or reminders off.
struct ReminderView: View {
    @State private var draft: ReminderDraft
    @State private var customTime: Date
    var onSave: (Reminder?) async -> Void
    @Environment(\.dismiss) private var dismiss

    init(reminder: Reminder?, onSave: @escaping (Reminder?) async -> Void) {
        _draft = State(initialValue: ReminderDraft(reminder))
        let hour = reminder?.hour ?? 20
        let minute = reminder?.minute ?? 0
        _customTime = State(initialValue: Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now)
        self.onSave = onSave
    }

    private static let moments: [(ReminderMoment, String)] = [
        (.coffee, String(localized: "With my coffee", bundle: .module)),
        (.lunch, String(localized: "Around lunch", bundle: .module)),
        (.dinner, String(localized: "Before dinner", bundle: .module)),
        (.late, String(localized: "Late, with a glass", bundle: .module))
    ]

    private static func dayLabel(_ weekday: Int) -> String {
        Calendar(identifier: .gregorian).shortWeekdaySymbols[weekday - 1]
    }

    private var summary: String {
        if draft.isOff { return String(localized: "No reminders. You open the app whenever you feel like it.", bundle: .module) }
        guard let reminder = draft.reminder else {
            return String(localized: "Pick a moment and at least one day.", bundle: .module)
        }
        let days = ReminderDraft.week.filter(reminder.weekdays.contains).map(Self.dayLabel).joined(separator: ", ")
        return String(localized: "At \(reminder.time) on \(days).", bundle: .module)
    }

    var body: some View {
        ZStack {
            PageBackground()
            LinearGradient(colors: [Color(hex: 0x181E12).opacity(0.35), Color(hex: 0x181E12).opacity(0.55)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    FlowTopBar(caption: String(localized: "Daily reminder", bundle: .module)) { dismiss() }
                    Text("Daily reminder", bundle: .module).font(UVVAFont.sans(30, .ultraLight)).tracking(-0.4)
                        .padding(.top, 40)
                    Text("Pick the moment of the day and the days of the week. Change it whenever you like.", bundle: .module)
                        .font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.86).frame(maxWidth: 280, alignment: .leading)
                        .padding(.top, 14)

                    VStack(spacing: 10) {
                        ForEach(Self.moments, id: \.0) { moment, title in
                            ReminderOption(title: title, detail: String(format: "%02d:00", moment.hour),
                                           isSelected: !draft.isOff && draft.moment == moment) { draft.pick(moment) }
                        }
                        ReminderTimeOption(time: $customTime,
                                           isSelected: !draft.isOff && draft.hour != nil && draft.moment == nil) { date in
                            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                            draft.pickTime(hour: parts.hour ?? 20, minute: parts.minute ?? 0)
                        }
                        ReminderOption(title: String(localized: "Turn reminders off", bundle: .module),
                                       subtitle: String(localized: "You open the app whenever you feel like it.", bundle: .module),
                                       isSelected: draft.isOff) { draft.turnOff() }
                    }
                    .padding(.top, 30)

                    Text(String(localized: "Days", bundle: .module).uppercased())
                        .font(UVVAFont.sans(9, .semibold)).tracking(3.2).opacity(draft.isOff ? 0.35 : 0.82)
                        .padding(.top, 30)
                    HStack(spacing: 7) {
                        ForEach(ReminderDraft.week, id: \.self) { weekday in
                            let isOn = draft.weekdays.contains(weekday)
                            Button { draft.toggle(weekday) } label: {
                                Text(Self.dayLabel(weekday))
                                    .font(UVVAFont.sans(11))
                                    .foregroundStyle(isOn ? UVVAColor.mossDeep : UVVAColor.creamFill)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(Capsule().fill(UVVAColor.creamFill.opacity(isOn ? 1 : 0)))
                                    .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(isOn ? 0 : 0.3), lineWidth: 0.5))
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 14)

                    Text(summary).font(UVVAFont.sans(11.5)).opacity(0.86).multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity).padding(.top, 34)
                    ActionButton(String(localized: "Save", bundle: .module), isEnabled: draft.canSave) {
                        Task {
                            await onSave(draft.reminder)
                            dismiss()
                        }
                    }
                    .padding(.top, 14)
                }
                .padding(.horizontal, 30)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(UVVAColor.creamFill)
    }
}
