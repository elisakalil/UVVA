#if os(iOS)
import DesignSystem
import SwiftUI

struct NewNoteChipSheet: View {
    var title: String
    var resources: NewNoteResourcesUIModel
    var existing: [String]
    var loadOptions: () async -> [String]
    var onAdd: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var options: [String] = []
    @State private var selected: [String] = []
    @State private var isLoading = true

    private var typed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var visibleOptions: [String] {
        let available = options.filter { option in
            !existing.contains { $0.localizedCaseInsensitiveCompare(option) == .orderedSame }
        }
        let matching = available.filter { typed.isEmpty || $0.localizedStandardContains(typed) }
        return Array(matching.prefix(48))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(title.uppercased())
                    .font(UVVAFont.redGrapes(20))
                    .tracking(0.8)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: resources.closeIcon)
                        .font(.system(size: 11))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(resources.closeText)
            }
            TextField(resources.writeOptionText, text: $text)
                .font(UVVAFont.sans(14))
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onSubmit(add)
                .tint(UVVAColor.creamFill)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.4), lineWidth: 0.75))

            Text(resources.selectOptionText.uppercased())
                .font(UVVAFont.sans(9, .medium))
                .tracking(2.2)

            ScrollView {
                if isLoading {
                    ProgressView().tint(UVVAColor.creamFill)
                } else if visibleOptions.isEmpty {
                    Text(resources.noOptionsText)
                        .font(UVVAFont.sans(13))
                        .foregroundStyle(UVVAColor.cream84)
                } else {
                    FlowLayout {
                        ForEach(visibleOptions, id: \.self) { option in
                            Chip(text: option, isSelected: selected.contains(option)) {
                                if let index = selected.firstIndex(of: option) {
                                    selected.remove(at: index)
                                } else {
                                    selected.append(option)
                                }
                                text = ""
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            PillButton(action: add) { Text(resources.addText) }
                .disabled(typed.isEmpty && selected.isEmpty)
                .opacity(typed.isEmpty && selected.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 26)
        .padding(.top, 22)
        .padding(.bottom, 14)
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
        .presentationBackground {
            ZStack {
                PageBackground()
                NotePalette.veil.ignoresSafeArea()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .task {
            options = await loadOptions()
            isLoading = false
        }
    }

    private func add() {
        guard !typed.isEmpty || !selected.isEmpty else { return }
        onAdd(typed.isEmpty ? selected : selected + [typed])
        dismiss()
    }
}
#endif
