#if os(iOS)
import Core
import DesignSystem
import SwiftUI

/// The wine and the user's additions, shared by the label reading and the Home's wine sheet.
struct NewNotePaperView: View {
    var model: NewNoteUIModel
    var onAnswer: (Bool) -> Void
    var onPick: (Verdict) -> Void
    var onNote: (String) -> Void
    var onAddChip: (String, NewNoteChipField) -> Void
    var loadChipOptions: (NewNoteChipField) async -> [String]
    var onIntensity: (Double, PalateAxis) -> Void
    var onReplacePhoto: (Data) -> Void
    var onSave: () -> Void

    @FocusState private var isNoteFocused: Bool
    @State private var chipField: NewNoteChipField?
    @State private var isExplainingIntensity = false
    @State private var isTakingPhoto = false
    /// A verdict was just given here: the question has shown it marked and gone.
    @State private var isVerdictGiven = false
    /// The question fades where it stands, then its place closes from above.
    @State private var isQuestionFading = false
    /// While the place closes, the page holds its bottom, so what is above comes down into it.
    @State private var holdsBottom = false
    @State private var verdictFade: Task<Void, Never>?

    private let ink = UVVAColor.mossDeep

    private var resources: NewNoteResourcesUIModel { model.resources }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if let content = model.content {
                    // The same parts, in the same order, as a saved note of the Cellar; here they can be added to.
                    VStack(alignment: .leading, spacing: NotePaper.sectionSpacing) {
                        VStack(alignment: .leading, spacing: 28) {
                            NotePaperTitle(title: content.title, producer: content.producer)
                            photo
                        }
                        NotePaperMatch(match: content.match, resources: resources.paper)
                        NotePaperFacts(content: content, resources: resources.paper)
                        WineAppellationCard(appellation: content.appellation)
                        ForEach([NewNoteChipField.grapes, .notes, .pairings]) { field in
                            NotePaperChips(label: chipTitle(field), chips: content.chips(field),
                                           addLabel: resources.paper.addText(chipTitle(field))) {
                                isNoteFocused = false
                                chipField = field
                            }
                        }
                        NotePaperIntensity(title: resources.paper.intensityText, profile: content.profile,
                                           infoLabel: resources.intensityInfoText,
                                           onInfo: { isExplainingIntensity = true }, onPick: onIntensity)
                        NotePaperMaps(profile: content.profile, palate: content.palate, resources: resources.paper)
                        noteField
                        end(findURL: content.findURL)
                        #if DEBUG
                        if let text = model.readingDebugText { NewNoteReadingDebugView(text: text) }
                        #endif
                    }
                    .padding(.horizontal, 26)
                    .padding(.top, 42)
                    .padding(.bottom, 16)
                }
            }
            .defaultScrollAnchor(holdsBottom ? .bottom : nil, for: .sizeChanges)
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
        .disabled(model.isWorking)
        .foregroundStyle(ink)
        .background(UVVAColor.parchment.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sheet(isPresented: $isTakingPhoto) {
            NewNotePhotoSheet(resources: resources, onPhoto: onReplacePhoto)
        }
        .sheet(isPresented: $isExplainingIntensity) {
            NewNoteInfoSheet(title: resources.paper.intensityText, paragraphs: resources.intensityInfoParagraphs,
                             resources: resources)
        }
        .sheet(item: $chipField) { field in
            NewNoteChipSheet(title: chipTitle(field), resources: resources,
                             existing: model.wine.map { field.values(in: $0) } ?? [],
                             loadOptions: { await loadChipOptions(field) }) { values in
                for value in values { onAddChip(value, field) }
            }
        }
    }

    /// The photo taken, or the vineyard with "Add photo +" when there is none; either way a tap takes another
    /// (CELLAR-R24).
    private var photo: some View {
        Button {
            isNoteFocused = false
            isTakingPhoto = true
        } label: {
            Color.clear
                .frame(height: 220)
                .overlay {
                    if let data = model.photo, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        UVVAPhoto.background.resizable().scaledToFill()
                            .overlay { NotePalette.veil.opacity(0.5) }
                            .overlay {
                                HStack(spacing: 8) {
                                    Text(resources.addPhotoText.uppercased())
                                        .font(UVVAFont.sans(10, .medium))
                                        .tracking(2.6)
                                    Image(systemName: resources.addPhotoIcon)
                                        .font(.system(size: 12, weight: .regular))
                                }
                                .foregroundStyle(UVVAColor.creamFill)
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(model.photo == nil ? resources.addPhotoText : resources.changePhotoText)
    }

    private func chipTitle(_ field: NewNoteChipField) -> String {
        switch field {
        case .grapes: resources.paper.grapesText
        case .notes: resources.paper.notesText
        case .pairings: resources.paper.pairingsText
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 18) {
            NoteEyebrow(text: resources.paper.yourNoteText)
            TextField("", text: Binding(get: { model.draftNote }, set: { onNote($0) }),
                      prompt: Text(resources.notePromptText).foregroundStyle(NotePalette.ink.opacity(0.4)),
                      axis: .vertical)
                .font(UVVAFont.sans(15))
                .lineSpacing(NoteRule.lineSpacing)
                .tint(NotePalette.ink)
                .focused($isNoteFocused)
                .padding(.bottom, NoteRule.belowText)
                .background(alignment: .top) { NoteRule(color: NotePalette.ink) }
                .accessibilityLabel(resources.paper.yourNoteText)
        }
    }

    /// "Have you had this wine?", then the verdict; "Not yet" leaves only the button (CELLAR-R18). A wine rated
    /// before is asked "Rate it again?": Yes asks for the verdict, No keeps the one it had (CELLAR-R14a).
    private var tastingQuestion: WineTastingActions.Question? {
        switch model.tasting {
        case .asking where model.isRatedBefore:
            .init(text: resources.rateAgainQuestionText, choices: [
                .init(title: resources.yesText) { answer(true) },
                .init(title: resources.noText) { answer(false) }
            ])
        case .asking:
            .init(text: resources.tastedQuestionText, choices: [
                .init(title: resources.yesText) { answer(true) },
                .init(title: resources.notYetText) { answer(false) }
            ])
        // Answered here, the question has nothing left to ask.
        case .tasted where isVerdictGiven:
            nil
        case .tasted:
            .init(text: resources.drinkAgainText, choices: model.verdicts.map { option in
                .init(title: option.label, isSelected: option.isSelected) { give(option.verdict) }
            })
        case .notYet, .keptRating:
            nil
        }
    }

    /// The verdict fills its button, and after a moment the question fades away and the button below rises into
    /// its place.
    private func give(_ verdict: Verdict) {
        onPick(verdict)
        verdictFade?.cancel()
        verdictFade = Task {
            // The verdict shows marked for a moment.
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.35)) { isQuestionFading = true }
            try? await Task.sleep(for: .milliseconds(380))
            guard !Task.isCancelled else { return }
            holdsBottom = true
            withAnimation(.easeInOut(duration: 0.45)) { isVerdictGiven = true }
            try? await Task.sleep(for: .milliseconds(500))
            holdsBottom = false
        }
    }

    private func answer(_ hasTasted: Bool) {
        withAnimation(.smooth(duration: 0.25)) { onAnswer(hasTasted) }
    }

    /// The same question and button as the foot of the Home's wine sheet.
    private func end(findURL: URL?) -> some View {
        VStack(spacing: 12) {
            if let tastingQuestion {
                WineTastingActions(question: tastingQuestion, primaryTitle: nil,
                                   questionOpacity: isQuestionFading ? 0 : 1)
            }
            NotePaperFindWine(title: resources.paper.findWineText, url: findURL)
            // Always there: unanswered, the wine goes in as Not yet; a "Yes" with no verdict is asked for it.
            WineTastingActions(question: nil, primaryTitle: resources.saveNoteText,
                               isPrimaryEnabled: !model.isWorking) {
                isNoteFocused = false
                onSave()
            }
            if let error = model.errorText {
                Text(error).font(UVVAFont.sans(12)).opacity(0.74)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Ruled paper under the note: one rule beneath each line written, so a new line gets its own rule as it appears.
private struct NoteRule: View {
    var color: Color

    static let lineSpacing: CGFloat = 14
    /// How far a rule sits below its line of text.
    static let belowText: CGFloat = 9
    /// The height of one line of `UVVAFont.sans(15)`, drawn one step heavier than its light weight.
    private static let lineHeight = UIFont.systemFont(ofSize: 15, weight: .regular).lineHeight
    private static let pitch = lineHeight + lineSpacing

    var body: some View {
        Canvas { context, size in
            let textHeight = size.height - Self.belowText
            let lines = max(1, Int(((textHeight + Self.lineSpacing) / Self.pitch).rounded()))
            for line in 0..<lines {
                let y = CGFloat(line) * Self.pitch + Self.lineHeight + Self.belowText
                context.fill(Path(CGRect(x: 0, y: y - 0.5, width: size.width, height: 0.5)), with: .color(color))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
