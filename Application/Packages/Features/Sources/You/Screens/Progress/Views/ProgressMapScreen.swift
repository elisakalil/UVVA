import DesignSystem
import SwiftUI

/// The Progress map full screen (YOU-R07a), opened by one tap on it: the world filling the screen, pinched, dragged
/// and double-tapped as in the page, the legend over its foot, and a tap on a place lists its wines. A wine picked
/// there closes the map and opens its note.
struct ProgressMapScreen: View {
    var title: String
    var model: ProgressMapUIModel
    var onPickWine: (String) -> Void
    var onClose: () -> Void

    @State private var selectedPlace: ProgressMapPin?
    @State private var pickedWine: String?

    var body: some View {
        ZStack(alignment: .top) {
            PageBackground(photo: UVVAPhoto.hills, veiled: true)
            ProgressWorldMap(model: model, onSelectPlace: { selectedPlace = $0 }, fillsScreen: true)
            header
        }
        .foregroundStyle(UVVAColor.creamFill)
        .sheet(item: $selectedPlace, onDismiss: {
            guard let wine = pickedWine else { return }
            pickedWine = nil
            onPickWine(wine)
        }) { place in
            ProgressPlaceSheet(place: place) { wine in
                pickedWine = wine.id
                selectedPlace = nil
            }
            .presentationBackground { PageBackground(photo: UVVAPhoto.hills, veiled: true) }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    /// "Back" in a thin outlined pill, as on a friend's page, and the title level with it on the other side, over the
    /// top of the map.
    private var header: some View {
        HStack(spacing: 16) {
            Button(action: onClose) {
                Text(String(localized: "Back", bundle: .module).uppercased())
                    .font(UVVAFont.sans(7.5, .semibold))
                    .tracking(1.65)
                    .opacity(0.75)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.32), lineWidth: 0.5))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, -2)
            Spacer(minLength: 0)
            SectionTitle(text: title)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, 26)
        .padding(.top, 8)
    }
}
