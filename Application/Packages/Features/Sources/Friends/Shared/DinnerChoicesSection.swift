import Core
import DesignSystem
import SwiftUI

/// "Set the perfect dinner" (FRI-R13, R13a), at the foot of a friend's Compatibility and of a group table: the
/// title with an info button that explains the feature in a sheet, the choices of the evening as chips, and the
/// button that sets the table in its sheet (FRI-R15a).
struct DinnerChoicesSection: View {
    var dinner: DinnerUIModel
    var resources: DinnerResourcesUIModel
    var onToggleCourse: (TableCourse) -> Void
    var onPickFood: (DinnerPreferences.Food) -> Void
    var onToggleInSeason: () -> Void
    var onPickTime: (DinnerPreferences.Time) -> Void
    var onSetTable: () -> Void

    @State private var isInfoPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                FriendsCardTitle(text: resources.setTableButtonText)
                Button { isInfoPresented = true } label: {
                    InfoMark()
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(resources.info.title)
                // The 44 pt target reaches past the title's line without pushing the chips down.
                .padding(.vertical, -12)
                .padding(.trailing, -12)
            }
            choices(resources.coursesText, dinner.courses, pick: onToggleCourse)
                .padding(.top, 24)
            choices(resources.onTheTableText, dinner.food, pick: onPickFood)
                .padding(.top, 20)
            VStack(alignment: .leading, spacing: 10) {
                label(resources.whenText)
                FlowLayout(spacing: 8) {
                    Chip(text: dinner.season.title, isSelected: dinner.season.isOn, action: onToggleInSeason)
                    ForEach(dinner.time) { option in
                        Chip(text: option.title, isSelected: option.isOn) { onPickTime(option.value) }
                    }
                }
            }
            .padding(.top, 20)
            ActionButton(dinner.buttonTitle, action: onSetTable)
                .padding(.top, 28)
        }
        .animation(.easeOut(duration: 0.18), value: dinner)
        .sheet(isPresented: $isInfoPresented) {
            DinnerInfoSheet(resources: resources, onClose: { isInfoPresented = false })
        }
    }

    private func choices<Value: Equatable>(_ title: String, _ options: [DinnerUIModel.Option<Value>],
                                           pick: @escaping (Value) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            label(title)
            FlowLayout(spacing: 8) {
                ForEach(options) { option in
                    Chip(text: option.title, isSelected: option.isOn) { pick(option.value) }
                }
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .medium))
            .tracking(2)
            .opacity(0.55)
            .accessibilityAddTraits(.isHeader)
    }
}
