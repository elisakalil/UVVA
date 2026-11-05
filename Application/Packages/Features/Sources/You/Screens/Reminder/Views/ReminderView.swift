import Core
import DesignSystem
import SwiftUI

/// Daily reminder (YOU-R16 to R20): a moment or any time, the days, or reminders off.
struct ReminderView: View {
    @Bindable var viewModel: ReminderViewModel
    @Environment(\.dismiss) private var dismiss

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
        if viewModel.draft.isOff { return String(localized: "No reminders. You open the app whenever you feel like it.", bundle: .module) }
        guard let reminder = viewModel.draft.reminder else {
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
                                           isSelected: !viewModel.draft.isOff && viewModel.draft.moment == moment) { viewModel.draft.pick(moment) }
                        }
                        ReminderTimeOption(time: $viewModel.customTime,
                                           isSelected: !viewModel.draft.isOff && viewModel.draft.hour != nil && viewModel.draft.moment == nil) { date in
                            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                            viewModel.draft.pickTime(hour: parts.hour ?? 20, minute: parts.minute ?? 0)
                        }
                        ReminderOption(title: String(localized: "Turn reminders off", bundle: .module),
                                       subtitle: String(localized: "You open the app whenever you feel like it.", bundle: .module),
                                       isSelected: viewModel.draft.isOff) { viewModel.draft.turnOff() }
                    }
                    .padding(.top, 30)

                    Text(String(localized: "Days", bundle: .module).uppercased())
                        .font(UVVAFont.sans(9, .semibold)).tracking(3.2).opacity(viewModel.draft.isOff ? 0.35 : 0.82)
                        .padding(.top, 30)
                    HStack(spacing: 7) {
                        ForEach(ReminderDraft.week, id: \.self) { weekday in
                            let isOn = viewModel.draft.weekdays.contains(weekday)
                            Button { viewModel.draft.toggle(weekday) } label: {
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

                    if let notice = viewModel.notice {
                        Text(notice).font(UVVAFont.sans(12)).padding(.top, 12)
                    }
                    Text(summary).font(UVVAFont.sans(11.5)).opacity(0.86).multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity).padding(.top, 34)
                    ActionButton(String(localized: "Save", bundle: .module), isEnabled: viewModel.draft.canSave && !viewModel.isSaving) {
                        Task {
                            if await viewModel.saveReminder(viewModel.draft.reminder) { dismiss() }
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
        .onAppear { viewModel.prepare() }
    }
}
