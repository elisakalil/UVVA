import Core
import DesignSystem
import SwiftUI

/// "Set the perfect dinner" (FRI-R13, R13a), at the foot of a friend's Compatibility and of a group table: the
/// choices of the evening as chips, and the button that sets the table in its sheet (FRI-R15a).
struct DinnerChoicesSection: View {
    var dinner: DinnerUIModel
    var resources: DinnerResourcesUIModel
    /// "The dishes follow your choices; the bottles, both your maps" / "all 4 maps".
    var intro: String
    var onToggleCourse: (TableCourse) -> Void
    var onPickFood: (DinnerPreferences.Food) -> Void
    var onToggleInSeason: () -> Void
    var onPickTime: (DinnerPreferences.Time) -> Void
    var onSetTable: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FriendsCardTitle(text: resources.setTableButtonText)
            Text(intro)
                .font(UVVAFont.sans(12.5))
                .lineSpacing(3)
                .opacity(0.6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
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
