#if os(iOS)
import DesignSystem
import SwiftUI

/// "Fill in by hand" (CELLAR-R23): name, producer, region, vintage, grape and type; "Continue" once there is a name.
struct NewNoteManualView: View {
    var model: NewNoteUIModel
    var onChange: (NewNoteField, String) -> Void
    var onPickType: (String) -> Void
    var onContinue: () -> Void

    @FocusState private var focus: NewNoteField?

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
                    NoteEyebrow(text: resources.typeFieldText).padding(.top, 26)
                    NewNoteFlowLayout(spacing: 6) {
                        ForEach(model.types) { type in
                            Button { onPickType(type.type) } label: {
                                Text(type.label)
                                    .font(UVVAFont.sans(11.5))
                                    .foregroundStyle(type.isSelected ? UVVAColor.creamFill : NotePalette.ink.opacity(0.72))
                                    .padding(.horizontal, 13)
                                    .frame(minHeight: 32)
                                    .background {
                                        if type.isSelected {
                                            Capsule().fill(NotePalette.ink)
                                        } else {
                                            Capsule().strokeBorder(NotePalette.ink.opacity(0.22), lineWidth: 0.5)
                                        }
                                    }
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(type.isSelected ? .isSelected : [])
                        }
                    }
                    .padding(.top, 12)
                    if let error = model.errorText {
                        Text(error).font(UVVAFont.sans(12)).opacity(0.74).padding(.top, 20)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 44)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            NewNotePill(title: resources.continueText, style: .filled, ink: NotePalette.ink, ground: UVVAColor.creamFill,
                        isEnabled: model.canContinue && !model.isWorking) {
                focus = nil
                onContinue()
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 20)
        }
        .foregroundStyle(NotePalette.ink)
        .background(NotePalette.paper.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private func field(_ field: NewNoteManualFieldUIModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NoteEyebrow(text: field.label)
            TextField("", text: Binding(get: { field.text }, set: { onChange(field.field, $0) }),
                      prompt: Text(field.prompt).foregroundStyle(NotePalette.ink.opacity(0.4)))
                .font(UVVAFont.sans(15))
                .tint(NotePalette.ink)
                .keyboardType(field.field == .vintage ? .numberPad : .default)
                .textInputAutocapitalization(field.field == .vintage ? .never : .words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focus, equals: field.field)
                .onSubmit { focus = next(after: field.field) }
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    NotePalette.ink.opacity(field.text.isEmpty ? 0.22 : 0.5).frame(height: 0.5)
                }
                .accessibilityLabel(field.label)
        }
    }

    private func next(after field: NewNoteField) -> NewNoteField? {
        let order = model.manualFields.map(\.field)
        guard let index = order.firstIndex(of: field), index + 1 < order.count else { return nil }
        return order[index + 1]
    }
}
#endif
