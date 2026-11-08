import Core
import DesignSystem
import SwiftUI

/// The wine on paper after the reading (CELLAR-R18 to R20, decision L3): "Have you had this wine?", then the
/// verdict and "Your note" for a tasted wine, or "Add to cellar" and "Find it"; with the photos, the facts and
/// UVVA's reading, as the saved note will show them.
struct NewNotePaperView: View {
    var model: NewNoteUIModel
    var onAnswer: (Bool) -> Void
    var onPick: (Verdict) -> Void
    var onNote: (String) -> Void
    var onRedo: () -> Void
    var onSave: () -> Void
    var onClose: () -> Void

    @FocusState private var isNoteFocused: Bool
    @State private var isFinding = false

    private var resources: NewNoteResourcesUIModel { model.resources }
    private var noteResources: NoteResourcesUIModel { model.noteResources }

    var body: some View {
        VStack(spacing: 0) {
            NewNoteBar(label: resources.newNoteText, icon: resources.closeIcon, iconLabel: resources.closeText,
                       onClose: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    title
                    question.padding(.top, 44)
                    if model.tasting == .tasted {
                        NoteVerdictPicker(title: noteResources.drinkAgainText, verdicts: model.verdicts) { verdict in
                            withAnimation(.easeOut(duration: 0.2)) { onPick(verdict) }
                        }
                        .padding(.top, 36)
                    }
                    if model.photoFront != nil || model.photoBack != nil {
                        NoteCover(front: model.photoFront, back: model.photoBack, tag: nil).padding(.top, 24)
                    }
                    if !model.facts.isEmpty {
                        NoteFacts(facts: model.facts).padding(.top, 48)
                    }
                    if !model.structure.isEmpty {
                        NoteReading(resources: noteResources, text: model.readingText, structure: model.structure,
                                    aromas: model.aromas)
                            .padding(.top, 56)
                    }
                    if model.tasting == .tasted { noteField.padding(.top, 56) }
                    end.padding(.top, 56)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 64)
                .animation(.easeOut(duration: 0.25), value: model.tasting)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(NotePalette.ink)
        .background(NotePalette.paper.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sheet(isPresented: $isFinding) {
            if let url = model.findURL { SafariSheet(url: url).ignoresSafeArea() }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.title)
                .font(UVVAFont.sans(34, .ultraLight))
                .tracking(-0.85)
                .accessibilityAddTraits(.isHeader)
            if !model.subtitle.isEmpty {
                Text(model.subtitle).font(UVVAFont.sans(12)).opacity(0.7)
            }
        }
    }

    // MARK: Have you had this wine? (CELLAR-R18)

    private var question: some View {
        VStack(alignment: .leading, spacing: 0) {
            NoteEyebrow(text: resources.tastedQuestionText)
            VStack(spacing: 8) {
                answer(resources.tastedYesText, isOn: model.tasting == .tasted) { onAnswer(true) }
                answer(resources.notYetText, isOn: model.tasting == .notYet) { onAnswer(false) }
            }
            .padding(.top, 22)
        }
    }

    private func answer(_ text: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { action() }
        } label: {
            Text(text)
                .font(UVVAFont.sans(12.5))
                .foregroundStyle(isOn ? UVVAColor.creamFill : NotePalette.ink.opacity(0.8))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background {
                    if isOn {
                        Capsule().fill(NotePalette.ink)
                    } else {
                        Capsule().strokeBorder(NotePalette.ink.opacity(0.22), lineWidth: 0.5)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: Your note (CELLAR-R20)

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 0) {
            NoteEyebrow(text: noteResources.yourNoteText)
            TextField("", text: Binding(get: { model.draftNote }, set: onNote),
                      prompt: Text(noteResources.notePromptText).foregroundStyle(NotePalette.ink.opacity(0.4)),
                      axis: .vertical)
                .font(UVVAFont.sans(15))
                .lineSpacing(5)
                .tint(NotePalette.ink)
                .focused($isNoteFocused)
                .padding(.bottom, 12)
                .overlay(alignment: .bottom) { NotePalette.ink.frame(height: 0.5) }
                .padding(.top, 18)
        }
    }

    // MARK: Redo, then Save note or Add to cellar (CELLAR-R19, R24)

    private var end: some View {
        VStack(spacing: 0) {
            if model.tasting == .notYet, model.findURL != nil {
                Button { isFinding = true } label: {
                    Text(resources.findItText.uppercased())
                        .font(UVVAFont.sans(9, .regular))
                        .tracking(2.3)
                        .opacity(0.7)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
            }
            HStack(spacing: 22) {
                if model.canRedo {
                    Button(action: onRedo) {
                        Text(resources.redoText.uppercased())
                            .font(UVVAFont.sans(9.5, .medium))
                            .tracking(2.7)
                            .opacity(0.8)
                            .frame(minHeight: 50)
                            .padding(.horizontal, 4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                if model.tasting != .asking {
                    NewNotePill(title: model.tasting == .tasted ? resources.saveNoteText : resources.addToCellarText,
                                style: .filled, ink: NotePalette.ink, ground: UVVAColor.creamFill,
                                isEnabled: model.canSave && !model.isWorking) {
                        isNoteFocused = false
                        onSave()
                    }
                }
            }
            if model.tasting == .tasted, !model.canSave {
                Text(resources.requiredText).font(UVVAFont.sans(11)).opacity(0.55).padding(.top, 12)
            }
            if let error = model.errorText {
                Text(error).font(UVVAFont.sans(12)).opacity(0.74).padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
