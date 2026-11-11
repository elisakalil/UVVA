import CoreUI
import DesignSystem
import SwiftUI

/// A saved note on paper (CELLAR.md §5), in a sheet that is dragged down to close (CELLAR-R13). Edit turns it into
/// the form of the new note, with the verdict and "Your note".
public struct NoteView<ViewModel: NoteViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @FocusState private var isNoteFocused: Bool

    private var model: NoteUIModel { viewModel.uiModel }
    private var resources: NoteResourcesUIModel { model.resources }

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if model.isEditing { editTop } else { savedTop }
                if !model.facts.isEmpty {
                    NoteFacts(facts: model.facts).padding(.top, 56)
                }
                if model.hasReading {
                    NoteReading(resources: resources, text: model.readingText,
                                structure: model.wineProfile == nil ? model.structure : [], aromas: model.aromas)
                        .padding(.top, 56)
                }
                if let profile = model.wineProfile {
                    NoteIntensityView(profile: profile, onPick: nil).padding(.top, 24)
                }
                if !model.pairings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        NoteEyebrow(text: String(localized: "Pairings", bundle: .module))
                        Text(model.pairings.joined(separator: " · "))
                            .font(UVVAFont.sans(12))
                    }
                    .padding(.top, 24)
                }
                if model.isEditing { editEnd } else { savedEnd }
            }
            .padding(.horizontal, 28)
            .padding(.top, 44)
            .padding(.bottom, 64)
            .animation(.easeOut(duration: 0.25), value: model.isEditing)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .foregroundStyle(NotePalette.ink)
        .background(NotePalette.paper.ignoresSafeArea())
        // Dark status bar over the light paper.
        .preferredColorScheme(.light)
        .task { await viewModel.load() }
        .interactiveDismissDisabled(model.isWorking)
        .sheet(isPresented: Binding(get: { model.isConfirmingDelete }, set: { if !$0 { viewModel.cancelDelete() } })) {
            NoteDeleteSheet(resources: resources, isWorking: model.isWorking,
                            onDelete: { Task { await viewModel.confirmDelete() } },
                            onCancel: viewModel.cancelDelete)
        }
    }

    // MARK: Saved (CELLAR-R26)

    private var savedTop: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    NoteEyebrow(text: model.date)
                    title
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 12) {
                    NoteEyebrow(text: resources.againText)
                    Text(model.again).font(UVVAFont.sans(12))
                }
                .accessibilityElement(children: .combine)
            }
            NoteCover(front: model.photoFront, back: model.photoBack, tag: model.coverTag)
                .padding(.top, 44)
            if let note = model.note {
                NoteEyebrow(text: resources.yourNoteText).padding(.top, 56)
                Text(note)
                    .font(UVVAFont.sans(15))
                    .lineSpacing(5)
                    .padding(.top, 18)
            }
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

    private var savedEnd: some View {
        VStack(spacing: 0) {
            HStack(spacing: 32) {
                linkButton(resources.editText) { viewModel.edit() }
                linkButton(resources.deleteText) { viewModel.askToDelete() }
            }
            if let error = model.errorText {
                Text(error).font(UVVAFont.sans(12)).opacity(0.74).padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
    }

    private func linkButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text.uppercased())
                .font(UVVAFont.sans(9, .regular))
                .tracking(2.3)
                .opacity(0.7)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Editing (CELLAR-R27)

    private var editTop: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            NoteVerdictPicker(title: resources.drinkAgainText, verdicts: model.verdicts) { verdict in
                withAnimation(.easeOut(duration: 0.2)) { viewModel.pick(verdict) }
            }
            .padding(.top, 44)
            NoteCover(front: model.photoFront, back: model.photoBack, tag: nil)
                .padding(.top, 24)
        }
    }

    private var editEnd: some View {
        VStack(alignment: .leading, spacing: 0) {
            NoteEyebrow(text: resources.yourNoteText)
            TextField("", text: Binding(get: { model.draftNote }, set: { viewModel.updateNote($0) }),
                      prompt: Text(resources.notePromptText).foregroundStyle(NotePalette.ink.opacity(0.4)),
                      axis: .vertical)
                .font(UVVAFont.sans(15))
                .lineSpacing(5)
                .tint(NotePalette.ink)
                .focused($isNoteFocused)
                .padding(.bottom, 12)
                .overlay(alignment: .bottom) { NotePalette.ink.frame(height: 0.5) }
                .padding(.top, 18)
            HStack(spacing: 22) {
                Button { viewModel.cancelEdit() } label: {
                    Text(resources.cancelText.uppercased())
                        .font(UVVAFont.sans(9.5, .medium))
                        .tracking(2.7)
                        .opacity(0.8)
                        .frame(minHeight: 48)
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button {
                    isNoteFocused = false
                    Task { await viewModel.save() }
                } label: {
                    Text(resources.saveChangesText.uppercased())
                        .font(UVVAFont.sans(9.5, .semibold))
                        .tracking(2.85)
                        .foregroundStyle(UVVAColor.creamFill)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(NotePalette.ink, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(model.isWorking)
            }
            .padding(.top, 56)
            if let error = model.errorText {
                Text(error).font(UVVAFont.sans(12)).opacity(0.74).padding(.top, 16)
            }
        }
        .padding(.top, 56)
    }
}

#if DEBUG
#Preview {
    NoteView(viewModel: MockNoteViewModel())
}
#endif
