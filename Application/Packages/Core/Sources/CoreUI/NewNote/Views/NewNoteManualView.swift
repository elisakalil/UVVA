#if os(iOS)
import Core
import DesignSystem
import SwiftUI

/// "Fill in by hand" (CELLAR-R23): the name, producer, vintage and alcohol typed; the type, region, appellation,
/// legal term, grapes, notes, time in wood, woods and awards chosen from lists. "Continue" once there is a name and
/// a base for the map (CELLAR-R23a).
struct NewNoteManualView: View {
    var model: NewNoteUIModel
    var onChange: (NewNoteField, String) -> Void
    var onPickType: (String) -> Void
    var loadOptions: (NewNoteManualChipField) async -> [String]
    /// A word typed for the region, appellation, grapes or notes, checked by "Add" (CELLAR-R18a).
    var validate: (String, NewNoteManualChipField) async -> ChipWordResult
    var onChoose: ([String], NewNoteManualChipField) -> Void
    var onRemove: (String, NewNoteManualChipField) -> Void
    var onPickOak: (OakAging) -> Void
    var onAddAward: (WineAward) -> Void
    var onRemoveAward: (WineAward) -> Void
    var onContinue: () -> Void

    @FocusState private var focus: NewNoteField?
    @State private var chipField: NewNoteManualChipField?
    @State private var isAddingAward = false

    private var resources: NewNoteResourcesUIModel { model.resources }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(resources.fillInByHandText)
                        .font(UVVAFont.sans(30, .ultraLight))
                        .tracking(-0.6)
                        .accessibilityAddTraits(.isHeader)
                    Text(resources.manualBodyText)
                        .font(UVVAFont.sans(12.5))
                        .opacity(0.7)
                        .padding(.top, 10)
                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(model.manualFields) { field($0) }
                    }
                    .padding(.top, 34)
                    VStack(alignment: .leading, spacing: 26) {
                        choices(resources.typeFieldText) {
                            ForEach(model.types) { type in
                                choice(type.label, isSelected: type.isSelected) { onPickType(type.type) }
                            }
                        }
                        ForEach(model.manualChipRows) { chipRow($0) }
                        choices(resources.oakFieldText) {
                            ForEach(model.oakAgings) { oak in
                                choice(oak.label, isSelected: oak.isSelected) { onPickOak(oak.aging) }
                            }
                        }
                        if let woods = model.oakWoodsRow { chipRow(woods) }
                        awards
                    }
                    .padding(.top, 26)
                    if let error = model.errorText {
                        Text(error).font(UVVAFont.sans(12)).opacity(0.74).padding(.top, 20)
                    }
                    #if DEBUG
                    // Why the reading gave no name.
                    if let text = model.readingDebugText {
                        NewNoteReadingDebugView(text: text, export: model.readingExportText).padding(.top, 40)
                    }
                    #endif
                }
                .padding(.horizontal, 28)
                .padding(.top, 44)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            VStack(spacing: 10) {
                if let hint = model.mapBasisHint {
                    Text(hint)
                        .font(UVVAFont.sans(11.5))
                        .multilineTextAlignment(.center)
                        .opacity(0.7)
                }
                NewNotePill(title: resources.continueText, style: .filled, ink: NotePalette.ink,
                            ground: UVVAColor.creamFill, isEnabled: model.canContinue && !model.isWorking) {
                    focus = nil
                    onContinue()
                }
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 20)
        }
        .foregroundStyle(NotePalette.ink)
        .background(NotePalette.paper.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sheet(item: $chipField) { field in
            let row = (model.manualChipRows + [model.oakWoodsRow].compactMap { $0 }).first { $0.field == field }
            NewNoteChipSheet(title: row?.label ?? "", resources: resources,
                             existing: row?.chips.map(\.value) ?? [],
                             writing: field.wordKind.map { kind in
                                 NewNoteChipWriting(kind: kind) { await validate($0, field) }
                             },
                             allowsMany: field.allowsMany, display: { resources.manualChip($0, field: field) },
                             loadOptions: { await loadOptions(field) }) { values in
                onChoose(values, field)
            }
        }
        .sheet(isPresented: $isAddingAward) {
            NewNoteAwardSheet(resources: resources,
                              vintage: Int(model.manualFields.first { $0.field == .vintage }?.text ?? ""),
                              currentYear: Calendar(identifier: .gregorian).component(.year, from: Date()),
                              onAdd: onAddAward)
        }
    }

    // MARK: Typed

    private func field(_ field: NewNoteManualFieldUIModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NoteEyebrow(text: field.label)
            TextField("", text: Binding(get: { field.text }, set: { onChange(field.field, $0) }),
                      prompt: Text(field.prompt).foregroundStyle(NotePalette.ink.opacity(0.4)))
                .font(UVVAFont.sans(15))
                .tint(NotePalette.ink)
                .keyboardType(keyboard(field.field))
                .textInputAutocapitalization(isNumber(field.field) ? .never : .words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focus, equals: field.field)
                .onSubmit { focus = next(after: field.field) }
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    NotePalette.ink.opacity(field.text.isEmpty ? 0.22 : 0.5).frame(height: 0.5)
                }
                .accessibilityLabel(field.label)
            if let hint = field.hint {
                Text(hint).font(UVVAFont.sans(11)).opacity(0.7)
            }
        }
    }

    private func isNumber(_ field: NewNoteField) -> Bool { field == .vintage || field == .alcohol }

    private func keyboard(_ field: NewNoteField) -> UIKeyboardType {
        switch field {
        case .vintage: .numberPad
        case .alcohol: .decimalPad
        case .name, .producer: .default
        }
    }

    private func next(after field: NewNoteField) -> NewNoteField? {
        let order = model.manualFields.map(\.field)
        guard let index = order.firstIndex(of: field), index + 1 < order.count else { return nil }
        return order[index + 1]
    }

    // MARK: Chosen

    /// What was chosen, each tapped to take it out, and "Add" for the list.
    private func chipRow(_ row: NewNoteManualChipRowUIModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NoteEyebrow(text: row.label)
            FlowLayout {
                ForEach(row.chips) { chip in
                    // A chip's icon takes the place of its text, so the "×" is written after the name.
                    Chip(text: Self.removable(chip.label), isSelected: true, surface: .paper) {
                        onRemove(chip.value, row.field)
                    }
                    .accessibilityLabel(chip.label)
                    .accessibilityHint(Text(resources.removeText))
                }
                // A single choice is changed by taking it out first.
                if row.field.allowsMany || row.chips.isEmpty {
                    Chip(text: row.addLabel, surface: .paper, icon: "plus") { chipField = row.field }
                }
            }
        }
    }

    /// "Douro  ×": what was chosen, tapped to take it out.
    private static func removable(_ label: String) -> String { label + "  ×" }

    private var awards: some View {
        VStack(alignment: .leading, spacing: 10) {
            NoteEyebrow(text: resources.awardsFieldText)
            FlowLayout {
                ForEach(model.awards) { award in
                    Chip(text: Self.removable(award.label), isSelected: true, surface: .paper) {
                        onRemoveAward(award.award)
                    }
                    .accessibilityLabel(award.label)
                    .accessibilityHint(Text(resources.removeText))
                }
                Chip(text: resources.paper.addText(resources.awardsFieldText), surface: .paper, icon: "plus") {
                    isAddingAward = true
                }
            }
        }
    }

    private func choices(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            NoteEyebrow(text: title)
            NewNoteFlowLayout(spacing: 6) { content() }
        }
    }

    private func choice(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(UVVAFont.sans(11.5))
                .foregroundStyle(isSelected ? UVVAColor.creamFill : NotePalette.ink.opacity(0.72))
                .padding(.horizontal, 13)
                .frame(minHeight: 32)
                .background {
                    if isSelected {
                        Capsule().fill(NotePalette.ink)
                    } else {
                        Capsule().strokeBorder(NotePalette.ink.opacity(0.22), lineWidth: 0.5)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
#endif
