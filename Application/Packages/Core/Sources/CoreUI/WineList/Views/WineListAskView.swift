#if os(iOS)
import DesignSystem
import SwiftUI

/// "Say it or show it" (WINELIST-R08): the line to order the wine, large enough to show the waiter, in the
/// restaurant's language; what to ask for if it is gone; where it is on the list. Once it is on the table, it goes to
/// the Cellar.
struct WineListAskView: View {
    var model: WineListUIModel
    var onClose: () -> Void
    var onLanguage: (String) -> Void
    var onAddToCellar: () -> Void

    private var resources: WineListResourcesUIModel { model.resources }
    private var ask: WineListAskUIModel { model.ask }

    var body: some View {
        ZStack {
            PageBackground(veiled: true)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .light))
                            .frame(width: 44, height: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(resources.closeText)
                    Spacer()
                    ScanSegmentedPicker(options: model.languages.map { .init(id: $0.rawValue, text: $0.name) },
                                        selection: ask.language.rawValue, onSelect: onLanguage)
                }
                Spacer(minLength: 24)
                Text(ask.label.uppercased())
                    .font(UVVAFont.sans(9, .semibold))
                    .tracking(3.2)
                    .foregroundStyle(UVVAColor.creamFill.opacity(0.82))
                Text(ask.line.uppercased())
                    .font(UVVAFont.redGrapes(38))
                    .tracking(0.8)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 20)
                    .id(ask.line)
                    .transition(.opacity.combined(with: .offset(y: 8)))
                Text(ask.fallback)
                    .font(UVVAFont.sans(15))
                    .lineSpacing(4)
                    .foregroundStyle(UVVAColor.creamFill.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 26)
                if !ask.place.isEmpty {
                    Text(ask.place)
                        .font(UVVAFont.sans(11, .regular))
                        .tracking(0.6)
                        .foregroundStyle(UVVAColor.sky)
                        .padding(.top, 14)
                }
                Spacer(minLength: 24)
                ActionButton(resources.addToCellarText, action: onAddToCellar)
            }
            .padding(.horizontal, 26)
            .padding(.top, 18)
            .padding(.bottom, 20)
            .animation(.easeOut(duration: 0.25), value: ask.language)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
    }
}
#endif
