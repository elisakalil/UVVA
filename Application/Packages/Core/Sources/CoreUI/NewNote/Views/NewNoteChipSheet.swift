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
    @State private var headerFade = 0.0

    private var typed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var visibleOptions: [String] {
        let available = options.filter { option in
            !existing.contains { $0.localizedCaseInsensitiveCompare(option) == .orderedSame }
        }
        let matching = available.filter { typed.isEmpty || $0.localizedStandardContains(typed) }
        return Array(matching.prefix(48))
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

    private var editor: some View {
        VStack(spacing: 0) {
            chipPanel

            PillButton(style: .filled, action: add) { Text(resources.addText) }
                .disabled(typed.isEmpty && selected.isEmpty)
                .opacity(typed.isEmpty && selected.isEmpty ? 0.5 : 1)
                .padding(.horizontal, 26)
                .padding(.top, 20)
                .padding(.bottom, 14)
        }
    }

    private var chipPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title.uppercased())
                .font(UVVAFont.redGrapes(20))
                .tracking(0.8)
                .accessibilityAddTraits(.isHeader)
            TextField(resources.writeOptionText, text: $text)
                .font(UVVAFont.sans(14))
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onSubmit(add)
                .tint(UVVAColor.creamFill)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.4), lineWidth: 0.75))

            ScrollView {
                if visibleOptions.isEmpty {
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

        }
        .padding(.horizontal, 26)
        .padding(.top, 34)
    }

    private func add() {
        guard !typed.isEmpty || !selected.isEmpty else { return }
        onAdd(typed.isEmpty ? selected : selected + [typed])
        dismiss()
    }
}
#endif
