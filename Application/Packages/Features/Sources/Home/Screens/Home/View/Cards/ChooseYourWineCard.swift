import Core
import DesignSystem
import SwiftUI

struct ChooseYourWineCard: View {
    var resources = HomeResourcesUIModel()
    var palateMap: PalateMap
    var catalog: WineList
    /// "Find my wine": the matching wines, best first, for the Home to show in its sheet (HOME-R28).
    var onFind: (_ suggestions: [Wine], _ direction: WineDiscovery.Direction) -> Void = { _, _ in }

    @State private var direction: WineDiscovery.Direction = .familiar
    @State private var type = "Red"
    @State private var country = "Anywhere"
    @State private var pairing: WineDiscovery.Pairing?
    @State private var notes: [WineDiscovery.Note] = []
    /// The search for "Find my wine" is running: a second tap waits for it.
    @State private var isFinding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FrostedCard(radius: UVVARadius.hero, padding: 26) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(resources.chooseYourWineCardTitle)
                        .font(UVVAFont.redGrapes(21))
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.bottom, 30)
                    directionPicker
                    group(resources.chooseYourWineCardTypeTitle) {
                        ForEach(WineDiscovery.types, id: \.self) { item in
                            Chip(text: resources.wineFilterLabel(item), isSelected: type == item, cutsOutSelectedLabel: true, glassTint: .white) { type = item }
                        }
                    }
                    group(resources.chooseYourWineCardRegionTitle) {
                        ForEach(WineDiscovery.countries, id: \.self) { item in
                            Chip(text: resources.wineFilterLabel(item), isSelected: country == item, cutsOutSelectedLabel: true, glassTint: .white) { country = item }
                        }
                    }
                    group(resources.chooseYourWinePairingTitle) {
                        ForEach(WineDiscovery.Pairing.allCases, id: \.self) { item in
                            Chip(text: resources.wineFilterLabel(item.rawValue), isSelected: pairing == item, cutsOutSelectedLabel: true, glassTint: .white) {
                                pairing = pairing == item ? nil : item
                            }
                        }
                    }
                    group(resources.chooseYourWineCardNotesTitle, hint: resources.chooseYourWineCardNotesHint) {
                        ForEach(WineDiscovery.Note.allCases, id: \.self) { note in
                            Chip(text: resources.wineFilterLabel(note.rawValue), isSelected: notes.contains(note), cutsOutSelectedLabel: true, glassTint: .white) { toggle(note) }
                                .disabled(notes.count >= resources.maximumNotes && !notes.contains(note))
                        }
                    }

                    PillButton(tint: .white, action: findWine) { Text(resources.chooseYourWineCardFindTitle) }
                        .padding(.top, 30)
                }
            }
        }
    }

    private var directionPicker: some View {
        HStack(spacing: 6) {
            Chip(text: resources.chooseYourWineFamiliarTitle, isSelected: direction == .familiar, fillsWidth: true, cutsOutSelectedLabel: true, glassTint: .white) {
                direction = .familiar
            }
            Chip(text: resources.chooseYourWineSurpriseTitle, isSelected: direction == .surprise, fillsWidth: true, cutsOutSelectedLabel: true, glassTint: .white) {
                direction = .surprise
            }
        }
    }

    /// The new wines of the catalog (HOME-R08a) are searched away from the main actor: thousands of them, scored
    /// against the map. Only Sendable values cross into the background task.
    private func findWine() {
        guard !isFinding else { return }
        isFinding = true
        let (wines, map, direction, type, country, notes, pairing) = (catalog.wines, palateMap, direction, type,
                                                                       country, notes, pairing)
        Task {
            let suggestions = await Task.detached(priority: .userInitiated) {
                WineDiscovery.suggestions(in: wines, for: map, direction: direction, type: type, country: country,
                                          notes: notes, pairing: pairing)
            }.value
            isFinding = false
            onFind(suggestions, direction)
        }
    }

    private func toggle(_ note: WineDiscovery.Note) {
        if let index = notes.firstIndex(of: note) {
            notes.remove(at: index)
        } else if notes.count < resources.maximumNotes {
            notes.append(note)
        }
    }

    private func group<Chips: View>(_ title: String, hint: String? = nil, @ViewBuilder chips: () -> Chips) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Caption(text: title, color: .white)
                Spacer()
                if let hint {
                    Text(hint).font(UVVAFont.sans(11.5)).foregroundStyle(.white)
                }
            }
            FlowLayout(spacing: 6, lineSpacing: 8) { chips() }
        }
        .padding(.top, 30)
    }
}
