import Core
import DesignSystem
import SwiftUI

/// Daily reminder (YOU-R16 to R20): a moment or any time, the days, or reminders off.
struct ReminderView<ViewModel: ReminderViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PageBackground()
            LinearGradient(colors: [Color(hex: 0x181E12).opacity(0.35), Color(hex: 0x181E12).opacity(0.55)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    FlowTopBar(caption: viewModel.uiModel.dailyReminderText) { dismiss() }
                    Text(viewModel.uiModel.dailyReminderText).font(UVVAFont.sans(30, .ultraLight)).tracking(-0.4)
                        .padding(.top, 40)
                    Text(viewModel.uiModel.pickTheMomentOfTheText)
                        .font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.86).frame(maxWidth: 280, alignment: .leading)
                        .padding(.top, 14)

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
                    .padding(.top, 30)

                    Text(viewModel.uiModel.daysText.uppercased())
                        .font(UVVAFont.sans(9, .semibold)).tracking(3.2).opacity(viewModel.uiModel.draft.isOff ? 0.35 : 0.82)
                        .padding(.top, 30)
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

                    if let notice = viewModel.uiModel.notice {
                        Text(notice).font(UVVAFont.sans(12)).padding(.top, 12)
                    }
                    Text(viewModel.uiModel.summary).font(UVVAFont.sans(11.5)).opacity(0.86).multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity).padding(.top, 34)
                    ActionButton(viewModel.uiModel.saveText, isEnabled: viewModel.uiModel.draft.canSave && !viewModel.uiModel.isSaving) {
                        Task {
                            if await viewModel.saveReminder(viewModel.uiModel.draft.reminder) { dismiss() }
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
