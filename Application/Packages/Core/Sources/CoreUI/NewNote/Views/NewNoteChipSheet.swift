#if os(iOS)
import Core
import DesignSystem
import SwiftUI

/// What a chip sheet does with a word typed in it (CELLAR-R18a): what it must name, and the check "Add" runs.
struct NewNoteChipWriting {
    var kind: ChipWordKind
    var validate: (String) async -> ChipWordResult
}

/// Chips to add to a field: the suggestions, and a word of one's own (CELLAR-R18a). The word is not looked for
/// among the suggestions: "Add" checks it, and takes it, offers the word of the list it is close to, or says why
/// not. Without `writing`, the field is a fixed list, only chosen from. `allowsMany` off keeps one chip at a time.
struct NewNoteChipSheet: View {
    var title: String
    var resources: NewNoteResourcesUIModel
    var existing: [String]
    var writing: NewNoteChipWriting?
    var allowsMany = true
    /// How an option reads: an aroma or a wood in the phone's language.
    var display: (String) -> String = { $0 }
    var loadOptions: () async -> [String]
    var onAdd: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var options: [String] = []
    @State private var selected: [String] = []
    @State private var isLoading = true
    @State private var headerFade = 0.0
    @State private var isChecking = false
    /// Why the typed word was not taken, or the word of the list it is close to.
    @State private var feedback: ChipWordResult?
    @FocusState private var isWriting: Bool

    private var typed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The suggestions not chosen yet; what is typed does not filter them.
    private var visibleOptions: [String] {
        let available = options.filter { option in
            !existing.contains { $0.localizedCaseInsensitiveCompare(option) == .orderedSame }
        }
        return Array(available.prefix(48))
    }

    var body: some View {
        Group {
            if isLoading {
                GrapeLoop()
                    .frame(width: 60, height: 84)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                editor
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
        .newNoteSheetGround()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .task {
            options = await loadOptions()
            isLoading = false
        }
    }

    /// The height "Add" takes at the foot, kept free under the last chip.
    private static let addHeight: CGFloat = 44 + 20 + 14

    private var addButton: some View {
        PillButton(style: .filled, action: add) { Text(isChecking ? resources.checkingText : resources.addText) }
            .disabled(!canAdd || isChecking)
            // Disabled, it is only a ring: the sheet's ground under it keeps the chips out of its label.
            .background { if !canAdd || isChecking { NewNoteSheetGroundCapsule() } }
            .padding(.top, 20)
            .padding(.bottom, 14)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title.uppercased())
                .font(UVVAFont.redGrapes(20))
                .tracking(0.8)
                .accessibilityAddTraits(.isHeader)
            if let writing {
                VStack(alignment: .leading, spacing: 12) {
                    TextField(resources.writePrompt(writing.kind), text: $text)
                        .font(UVVAFont.sans(14))
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .onSubmit(add)
                        .focused($isWriting)
                        .tint(UVVAColor.creamFill)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.4), lineWidth: 0.75))
                        .onChange(of: text) { feedback = nil }
                    if let feedback { feedbackView(feedback, kind: writing.kind) }
                }
            }

            // "Add" floats over the chips: they scroll on behind it, with no band of their own.
            ZStack(alignment: .bottom) {
                ScrollView {
                    if visibleOptions.isEmpty {
                        Text(resources.noOptionsText)
                            .font(UVVAFont.sans(13))
                            .foregroundStyle(UVVAColor.cream84)
                    } else {
                        FlowLayout {
                            ForEach(visibleOptions, id: \.self) { option in
                                Chip(text: display(option), isSelected: selected.contains(option)) {
                                    if let index = selected.firstIndex(of: option) {
                                        selected.remove(at: index)
                                    } else {
                                        // One choice: the chip tapped takes the place of the one before.
                                        selected = allowsMany ? selected + [option] : [option]
                                    }
                                }
                            }
                        }
                    }
                }
                .onScrollGeometryChange(for: Double.self) { geometry in
                    min(1, max(0, (geometry.contentOffset.y + geometry.contentInsets.top) / 8))
                } action: { _, opacity in
                    headerFade = opacity
                }
                .mask(alignment: .top) {
                    VStack(spacing: 0) {
                        LinearGradient(stops: [
                            .init(color: .black.opacity(1 - headerFade), location: 0),
                            .init(color: .black.opacity(1 - headerFade * 0.75), location: 0.35),
                            .init(color: .black, location: 1)
                        ], startPoint: .top, endPoint: .bottom)
                        .frame(height: 30)
                        Color.black
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .contentMargins(.bottom, Self.addHeight, for: .scrollContent)
                .ignoresSafeArea(.container, edges: .bottom)

                addButton
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 34)
    }

    /// "Did you mean Cabernet Sauvignon?" with the word to tap, or why the word was not taken.
    @ViewBuilder
    private func feedbackView(_ feedback: ChipWordResult, kind: ChipWordKind) -> some View {
        switch feedback {
        case let .didYouMean(word):
            HStack(spacing: 10) {
                Text(resources.didYouMeanText).font(UVVAFont.sans(12.5))
                Chip(text: display(word)) { take(word) }
                    .accessibilityHint(Text(resources.addText))
            }
        case let .rejected(rejection):
            VStack(alignment: .leading, spacing: 6) {
                Text(resources.chipWordRejection(rejection, kind: kind))
                    .font(UVVAFont.sans(12.5))
                    .foregroundStyle(UVVAColor.cream84)
                    .fixedSize(horizontal: false, vertical: true)
                #if DEBUG
                // Why the model on the phone gave no answer, as the reading's debug section says it.
                if let reason = rejection.debugReason {
                    Text(reason)
                        .font(.system(size: 10.5, design: .monospaced))
                        .opacity(0.6)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                #endif
            }
        case .accepted:
            EmptyView()
        }
    }

    private var canAdd: Bool { !selected.isEmpty || (writing != nil && !typed.isEmpty) }

    /// What is chosen; with a word typed, the word once it is checked (CELLAR-R18a).
    private func add() {
        guard canAdd, !isChecking else { return }
        guard let writing, !typed.isEmpty else {
            finish(selected)
            return
        }
        isChecking = true
        Task {
            let result = await writing.validate(typed)
            isChecking = false
            if case let .accepted(word) = result {
                take(word)
            } else {
                feedback = result
                isWriting = true
                if case let .rejected(rejection) = result {
                    AccessibilityNotification.Announcement(
                        resources.chipWordRejection(rejection, kind: writing.kind)).post()
                }
            }
        }
    }

    /// A checked word joins what is chosen; for one choice, it is the choice.
    private func take(_ word: String) {
        finish(allowsMany ? selected.adding([word]) : [word])
    }

    private func finish(_ values: [String]) {
        onAdd(values)
        dismiss()
    }
}
#endif
