#if os(iOS)
import Core
import DesignSystem
import SwiftUI

/// The words of the rating, the same in the new note and in a saved note.
public struct NoteRatingResources {
    public var paper: NotePaperResources
    public var rateText = String(localized: "Rate this wine", bundle: .module)
    public var scoreText = String(localized: "Score", bundle: .module)
    public var saveText = String(localized: "Save rating", bundle: .module)
    public var notTastedText = String(localized: "Not tasted yet", bundle: .module)
    public var notePromptText = String(localized: "What stood out in the glass?", bundle: .module)

    public init(paper: NotePaperResources = NotePaperResources()) {
        self.paper = paper
    }

    /// "Rate this wine" before; then "Your rating: Maybe", with "· 4/5" when there is a score.
    public func linkText(_ verdict: Verdict?, score: Int?) -> String {
        guard let verdict else { return rateText }
        let label = paper.verdict(verdict)
        guard let score else { return String(localized: "Your rating: \(label)", bundle: .module) }
        return String(localized: "Your rating: \(label) · \(score)/5", bundle: .module)
    }

    /// "4 of 5", for VoiceOver.
    func scoreValue(_ score: Int?) -> String {
        guard let score else { return String(localized: "No score", bundle: .module) }
        return String(localized: "\(score) of 5", bundle: .module)
    }
}

/// The rating under the label photos, in the hand of the tasting guide: it opens the rating sheet.
public struct NoteRatingLink: View {
    var text: String
    var action: () -> Void

    public init(text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(text).font(UVVAFont.redGrapes(18))
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(NotePaper.ink)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// "Would you drink it again?" on paper, sliding up from the foot (CELLAR-R18): the verdict, the score from 0 to 5,
/// "Your note", and the button that keeps them. When they are not kept, the sheet stays with the error. Writing the
/// note opens the sheet to its full height, so the keyboard covers nothing.
public struct NoteRatingSheet: View {
    var resources: NoteRatingResources
    var errorText: String?
    /// Kept or not: false leaves the sheet open.
    var onSave: (Verdict, Int?, String) async -> Bool
    /// "Not tasted yet": nil hides it.
    var onNotTasted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var verdict: Verdict?
    @State private var score: Int?
    @State private var note: String
    @State private var isSaving = false
    @State private var detent: PresentationDetent
    @FocusState private var isNoteFocused: Bool

    private var resting: PresentationDetent { .height(onNotTasted == nil ? 440 : 490) }

    public init(resources: NoteRatingResources, verdict: Verdict?, score: Int?, note: String = "",
                errorText: String? = nil, onSave: @escaping (Verdict, Int?, String) async -> Bool,
                onNotTasted: (() -> Void)? = nil) {
        self.resources = resources
        self.errorText = errorText
        self.onSave = onSave
        self.onNotTasted = onNotTasted
        _verdict = State(initialValue: verdict)
        _score = State(initialValue: score)
        _note = State(initialValue: note)
        _detent = State(initialValue: .height(onNotTasted == nil ? 440 : 490))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(resources.paper.drinkAgainText)
                    .font(UVVAFont.redGrapes(22))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 10) {
                    ForEach([Verdict.yes, .maybe, .no], id: \.self) { option in
                        WineSheetButton(title: resources.paper.verdict(option), style: .choice,
                                        isSelected: verdict == option) { verdict = option }
                    }
                }
                .padding(.top, 22)
                NoteScoreControl(title: resources.scoreText, value: resources.scoreValue(score), score: $score)
                    .padding(.top, 26)
                VStack(alignment: .leading, spacing: 14) {
                    NoteEyebrow(text: resources.paper.yourNoteText)
                    NoteRuledField(text: $note, prompt: resources.notePromptText,
                                   label: resources.paper.yourNoteText)
                        .focused($isNoteFocused)
                }
                .padding(.top, 26)
                WineSheetButton(title: resources.saveText, style: .filled) { save() }
                    .disabled(verdict == nil || isSaving)
                    .opacity(verdict == nil ? 0.45 : 1)
                    .padding(.top, 30)
                if let errorText {
                    Text(errorText)
                        .font(UVVAFont.sans(12))
                        .opacity(0.74)
                        .padding(.top, 12)
                }
                if let onNotTasted {
                    NotePaperLink(title: resources.notTastedText) {
                        onNotTasted()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isSaving)
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 34)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .disabled(isSaving)
        .foregroundStyle(NotePaper.ink)
        .onChange(of: isNoteFocused) { _, isFocused in
            if isFocused { withAnimation { detent = .large } }
        }
        .presentationDetents([resting, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationBackground(UVVAColor.parchment)
        .presentationCornerRadius(28)
        .interactiveDismissDisabled(isSaving)
    }

    private func save() {
        guard let verdict else { return }
        isNoteFocused = false
        isSaving = true
        Task {
            let isKept = await onSave(verdict, score, note)
            isSaving = false
            if isKept { dismiss() }
        }
    }
}

/// "Your note" on two ruled lines, as on paper.
struct NoteRuledField: View {
    @Binding var text: String
    var prompt: String
    var label: String

    var body: some View {
        TextField("", text: $text, prompt: Text(prompt).foregroundStyle(NotePalette.ink.opacity(0.4)),
                  axis: .vertical)
            .font(UVVAFont.sans(15))
            .lineLimit(2, reservesSpace: true)
            .lineSpacing(NoteRule.lineSpacing)
            .tint(NotePalette.ink)
            .frame(minHeight: NoteRule.textHeight)
            .padding(.bottom, NoteRule.belowText)
            .background(alignment: .top) { NoteRule(color: NotePalette.ink) }
            .accessibilityLabel(label)
    }
}

/// Two fixed rules beneath the visible rows of the note.
struct NoteRule: View {
    var color: Color
    @Environment(\.displayScale) private var displayScale

    static let lineSpacing: CGFloat = 14
    /// How far a rule sits below its line of text.
    static let belowText: CGFloat = 9
    /// The height of one line of `UVVAFont.sans(15)`, drawn one step heavier than its light weight.
    private static let lineHeight = UIFont.systemFont(ofSize: 15, weight: .regular).lineHeight
    private static let pitch = lineHeight + lineSpacing
    static let textHeight = lineHeight + pitch

    var body: some View {
        // Each rule on whole device pixels: the line height is fractional, so the second rule otherwise falls
        // between pixels and draws fainter than the first.
        let scale = max(displayScale, 1)
        let thickness = max((0.5 * scale).rounded(), 1) / scale
        return Canvas { context, size in
            for line in 0..<2 {
                let y = CGFloat(line) * Self.pitch + Self.lineHeight + Self.belowText
                let top = ((y - thickness) * scale).rounded() / scale
                context.fill(Path(CGRect(x: 0, y: top, width: size.width, height: thickness)), with: .color(color))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The score from 0 to 5, in six pips joined by a hairline, the one it stands at breathing, as the axes of the note
/// are: set by a tap or a sideways slide, the first pip being 0. Nil, before any score, leaves every pip hollow and
/// shows a dash.
struct NoteScoreControl: View {
    var title: String
    /// "4 of 5", for VoiceOver.
    var value: String
    @Binding var score: Int?

    private static let top = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // "SCORE 4/5", read together.
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                NoteEyebrow(text: title)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    if let score {
                        Text(String(score)).font(UVVAFont.redGrapes(26))
                            .contentTransition(.numericText())
                    } else {
                        Text("–").font(UVVAFont.sans(20, .light)).opacity(0.6)
                    }
                    Text("/5").font(UVVAFont.sans(12)).opacity(0.6)
                }
            }
            // The same height with the dash or a number, so nothing below moves when the first score is given.
            .frame(height: 32)
            PipScale(count: Self.top + 1, level: score) { picked in
                withAnimation(.snappy(duration: 0.15)) { score = picked }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: score = min((score ?? -1) + 1, Self.top)
            case .decrement: score = max((score ?? 1) - 1, 0)
            @unknown default: break
            }
        }
    }
}

#if DEBUG
#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        NoteRatingSheet(resources: NoteRatingResources(), verdict: .maybe, score: 3,
                        onSave: { _, _, _ in true }, onNotTasted: {})
    }
}
#endif
#endif
