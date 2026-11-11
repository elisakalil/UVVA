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
    var onRedo: () -> Void
    var onSave: () -> Void

    @FocusState private var isNoteFocused: Bool
    @State private var isFinding = false
    @State private var chipField: NewNoteChipField?
    @State private var isExplainingIntensity = false

    private let ink = UVVAColor.mossDeep

    private var resources: NewNoteResourcesUIModel { model.resources }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if let wine = model.wine {
                    VStack(alignment: .leading, spacing: 32) {
                        title(producer: wine.producer)
                        match
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(alignment: .top, spacing: 24) {
                                detail(resources.originText, value: wine.origin)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                detail(resources.producerFieldText, value: wine.producer)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            ForEach(model.facts) { fact in
                                detail(fact.label, value: fact.value)
                            }
                            detail(resources.serveText, value: model.servingText)
                        }
                        findWine
                        chipSection(resources.grapesText, field: .grapes, wine: wine)
                        chipSection(resources.notesText, field: .notes, wine: wine)
                        chipSection(resources.pairingsText, field: .pairings, wine: wine)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 2) {
                                NoteEyebrow(text: resources.intensityText)
                                Button { isExplainingIntensity = true } label: {
                                    Image(systemName: resources.infoIcon)
                                        .font(.system(size: 12))
                                        .foregroundStyle(ink.opacity(0.62))
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(resources.intensityInfoText)
                            }
                            .padding(.vertical, -14)
                            NoteIntensityView(profile: wine.profile, onPick: onIntensity)
                                .padding(.top, 8)
                        }
                        noteField
                        maps(wine.profile)
                            .padding(.top, 24)
                        end
                    }
                    .padding(.horizontal, 26)
                    .padding(.top, 42)
                    .padding(.bottom, 16)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
        .disabled(model.isWorking)
        .foregroundStyle(ink)
        .background(UVVAColor.parchment.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sheet(isPresented: $isFinding) {
            if let url = model.findURL { SafariSheet(url: url).ignoresSafeArea() }
        }
        .sheet(isPresented: $isExplainingIntensity) {
            NewNoteInfoSheet(title: resources.intensityText, paragraphs: resources.intensityInfoParagraphs,
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

    private func title(producer: String) -> some View {
        let size: CGFloat = model.title.count >= 23 ? 24 : model.title.count >= 15 ? 29 : 36
        return VStack(alignment: .leading, spacing: 12) {
            Text(model.title.uppercased())
                .font(UVVAFont.redGrapes(size))
                .lineSpacing(-size * 0.1)
                .accessibilityAddTraits(.isHeader)
            if !producer.isEmpty {
                Text(producer.uppercased())
                    .font(UVVAFont.sans(8.5, .medium))
                    .tracking(2.2)
                    .foregroundStyle(ink.opacity(0.6))
            }
        }
    }

    private var match: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let match = model.match {
                Text("\(match)%")
                    .font(UVVAFont.sans(44, .ultraLight))
                    .tracking(-1.3)
            }
            Text(model.match == nil ? resources.noMapText : resources.matchText)
                .font(UVVAFont.sans(12.5))
                .foregroundStyle(ink.opacity(0.78))
        }
        .accessibilityElement(children: .combine)
    }

    private func detail(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            NoteEyebrow(text: label)
            Text(value.isEmpty ? "—" : value)
                .font(UVVAFont.sans(13))
        }
        .accessibilityElement(children: .combine)
    }

    private var findWine: some View {
        WineSheetButton(title: resources.findWineText, style: .outlined) { isFinding = true }
            .disabled(model.findURL == nil)
    }

    private func chipTitle(_ field: NewNoteChipField) -> String {
        switch field {
        case .grapes: resources.grapesText
        case .notes: resources.notesText
        case .pairings: resources.pairingsText
        }
    }

    private func chipSection(_ label: String, field: NewNoteChipField, wine: Wine) -> some View {
        let chips = field.values(in: wine)
        return VStack(alignment: .leading, spacing: 10) {
            NoteEyebrow(text: label)
            FlowLayout {
                ForEach(chips.indices, id: \.self) { index in
                    Chip(text: chips[index], surface: .paper)
                }
                Chip(text: String(localized: "Add to \(label)", bundle: .module), surface: .paper, icon: "plus") {
                    isNoteFocused = false
                    chipField = field
                }
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 18) {
            NoteEyebrow(text: resources.yourNoteText)
            TextField("", text: Binding(get: { model.draftNote }, set: { onNote($0) }),
                      prompt: Text(resources.notePromptText).foregroundStyle(NotePalette.ink.opacity(0.4)),
                      axis: .vertical)
                .font(UVVAFont.sans(15))
                .lineSpacing(5)
                .tint(NotePalette.ink)
                .focused($isNoteFocused)
                .padding(.bottom, 12)
                .overlay(alignment: .bottom) { NotePalette.ink.frame(height: 0.5) }
                .accessibilityLabel(resources.yourNoteText)
        }
    }

    private func maps(_ profile: PalateMap) -> some View {
        WineMapCarousel(copy: .init(wineTitle: resources.wineMapText, comparisonTitle: resources.comparisonText,
                                    wineLegend: resources.wineText, palateLegend: resources.palateText,
                                    overlapLegend: resources.overlapText),
                        labels: PalateAxis.allCases.map(\.label), wine: profile.chartValues,
                        palate: model.palate?.chartValues, tint: ink)
    }

    /// "Have you had this wine?", then the verdict; "Not yet" leaves only the button (CELLAR-R18).
    private var tastingQuestion: WineTastingActions.Question? {
        switch model.tasting {
        case .asking:
            .init(text: resources.tastedQuestionText, choices: [
                .init(title: resources.yesText) { answer(true) },
                .init(title: resources.notYetText) { answer(false) }
            ])
        case .tasted:
            .init(text: resources.drinkAgainText, choices: model.verdicts.map { option in
                .init(title: option.label, isSelected: option.isSelected) { onPick(option.verdict) }
            })
        case .notYet:
            nil
        }
    }

    private func answer(_ hasTasted: Bool) {
        withAnimation(.smooth(duration: 0.25)) { onAnswer(hasTasted) }
    }

    /// The same question and button as the foot of the Home's wine sheet.
    private var end: some View {
        VStack(spacing: 12) {
            WineTastingActions(question: tastingQuestion, primaryTitle: resources.saveNoteText,
                               isPrimaryEnabled: model.canSave && !model.isWorking,
                               secondaryTitle: model.canRedo ? resources.redoText : nil, onSecondary: onRedo) {
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
#endif
