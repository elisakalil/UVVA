import Core
import DesignSystem
import SwiftUI

/// Daily reminder (YOU-R16 to R20), in the sheet of the account rows: a moment or any time, the days, or reminders off.
struct ReminderView<ViewModel: ReminderViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        YouSheet(title: viewModel.uiModel.dailyReminderText, message: viewModel.uiModel.pickTheMomentOfTheText,
                 height: 760) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(spacing: 10) {
                        ForEach(viewModel.uiModel.moments, id: \.0) { moment, title in
                            ReminderOption(title: title, detail: String(format: "%02d:00", moment.hour),
                                           isSelected: !viewModel.uiModel.draft.isOff && viewModel.uiModel.draft.moment == moment) { viewModel.pick(moment) }
                        }
                        ReminderTimeOption(time: Binding(get: { viewModel.uiModel.customTime }, set: { viewModel.updateTime($0) }),
                                           title: viewModel.uiModel.anotherTimeText, isSelected: !viewModel.uiModel.draft.isOff && viewModel.uiModel.draft.hour != nil && viewModel.uiModel.draft.moment == nil) { date in
                            viewModel.updateTime(date)
                        }
                        ReminderOption(title: viewModel.uiModel.turnRemindersOffText,
                                       subtitle: viewModel.uiModel.youOpenTheAppWheneverText,
                                       isSelected: viewModel.uiModel.draft.isOff) { viewModel.turnOff() }
                    }

                    Text(viewModel.uiModel.daysText.uppercased())
                        .font(UVVAFont.sans(9, .semibold)).tracking(3.2).opacity(viewModel.uiModel.draft.isOff ? 0.35 : 0.82)
                        .padding(.top, 26)
                    HStack(spacing: 7) {
                        ForEach(ReminderDraft.week, id: \.self) { weekday in
                            let isOn = viewModel.uiModel.draft.weekdays.contains(weekday)
                            Button { viewModel.toggle(weekday) } label: {
                                Text(ReminderUIModel.dayLabel(weekday))
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
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            if let notice = viewModel.uiModel.notice {
                Text(notice).font(UVVAFont.sans(12)).padding(.top, 12)
            }
            Text(viewModel.uiModel.summary).font(UVVAFont.sans(11.5)).opacity(0.86).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity).padding(.top, 14)
            ActionButton(viewModel.uiModel.saveText, isEnabled: viewModel.uiModel.draft.canSave && !viewModel.uiModel.isSaving) {
                Task {
                    if await viewModel.saveReminder(viewModel.uiModel.draft.reminder) { dismiss() }
                }
            }
            .padding(.top, 14)
        }
        .onAppear { viewModel.prepare() }
    }
}
