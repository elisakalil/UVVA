import SwiftUI

/// The question about a wine and, under it, the button that keeps it: the foot of the Home's wine sheet and the
/// end of the Cellar's new note. The question comes one at a time and leaves once answered; the button is always
/// there.
public struct WineTastingActions: View {
    public struct Choice: Identifiable {
        public var title: String
        public var isSelected: Bool
        public var action: () -> Void
        public var id: String { title }

        public init(title: String, isSelected: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.isSelected = isSelected
            self.action = action
        }
    }

    public struct Question {
        public var text: String
        public var choices: [Choice]
        /// The answer is final: it stays marked and the others step back.
        public var isLocked: Bool

        public init(text: String, choices: [Choice], isLocked: Bool = false) {
            self.text = text
            self.choices = choices
            self.isLocked = isLocked
        }
    }

    var question: Question?
    var primaryTitle: String
    var isPrimaryEnabled: Bool
    var secondaryTitle: String?
    var onSecondary: () -> Void
    var onPrimary: () -> Void

    /// `question` is nil once there is nothing left to ask. `secondaryTitle` puts an outlined button beside the
    /// primary one ("Redo" in the new note).
    public init(question: Question?, primaryTitle: String, isPrimaryEnabled: Bool = true,
                secondaryTitle: String? = nil, onSecondary: @escaping () -> Void = {},
                onPrimary: @escaping () -> Void) {
        self.question = question
        self.primaryTitle = primaryTitle
        self.isPrimaryEnabled = isPrimaryEnabled
        self.secondaryTitle = secondaryTitle
        self.onSecondary = onSecondary
        self.onPrimary = onPrimary
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let question {
                VStack(alignment: .leading, spacing: 18) {
                    WineSheetQuestion(text: question.text)
                    HStack(spacing: 10) {
                        ForEach(question.choices) { choice in
                            WineSheetButton(title: choice.title, style: .choice, isSelected: choice.isSelected,
                                            action: choice.action)
                                .opacity(question.isLocked && !choice.isSelected ? 0.45 : 1)
                        }
                    }
                    .allowsHitTesting(!question.isLocked)
                }
                // One question gives way to the next instead of its words changing in place.
                .id(question.text)
                .transition(.opacity)
            }
            HStack(spacing: 10) {
                if let secondaryTitle {
                    WineSheetButton(title: secondaryTitle, style: .outlined, action: onSecondary)
                }
                WineSheetButton(title: primaryTitle, style: .filled, action: onPrimary)
                    .disabled(!isPrimaryEnabled)
                    .opacity(isPrimaryEnabled ? 1 : 0.45)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 40) {
        WineTastingActions(question: .init(text: "Have you had this wine?",
                                           choices: [.init(title: "Yes") {}, .init(title: "Not yet") {}]),
                           primaryTitle: "Add to cellar") {}
        WineTastingActions(question: .init(text: "Would you drink it again?",
                                           choices: [.init(title: "Yes", isSelected: true) {}, .init(title: "Maybe") {},
                                                     .init(title: "No") {}],
                                           isLocked: true),
                           primaryTitle: "Add to cellar") {}
        WineTastingActions(question: nil, primaryTitle: "Save note", isPrimaryEnabled: false,
                           secondaryTitle: "Redo") {}
    }
    .padding(26)
    .foregroundStyle(UVVAColor.mossDeep)
    .background(UVVAColor.parchment)
}
#endif
