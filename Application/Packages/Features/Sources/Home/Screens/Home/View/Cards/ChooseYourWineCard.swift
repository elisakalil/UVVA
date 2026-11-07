import Core
import DesignSystem
import SwiftUI

struct ChooseYourWineCard: View {
    var resources = HomeResourcesUIModel()
    var palateMap: PalateMap
    var catalog: [Wine]

    @State private var direction: WineDiscovery.Direction = .familiar
    @State private var type = "Red"
    @State private var country = "Anywhere"
    @State private var pairing: WineDiscovery.Pairing?
    @State private var notes: [WineDiscovery.Note] = []
    @State private var suggestions: [Wine] = []
    @State private var resultIndex = 0
    @State private var showingResult = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: resources.chooseYourWineCardSectionTitle)
            FrostedCard(radius: UVVARadius.hero, padding: 26) {
                VStack(alignment: .leading, spacing: 0) {
                    directionPicker
                    group(resources.chooseYourWineCardTypeTitle) {
                        ForEach(WineDiscovery.types, id: \.self) { item in
                            Chip(text: resources.wineFilterLabel(item), isSelected: type == item) { type = item }
                        }
                    }
                    group(resources.chooseYourWineCardRegionTitle) {
                        ForEach(WineDiscovery.countries, id: \.self) { item in
                            Chip(text: resources.wineFilterLabel(item), isSelected: country == item) { country = item }
                        }
                    }
                    group(resources.chooseYourWinePairingTitle) {
                        ForEach(WineDiscovery.Pairing.allCases, id: \.self) { item in
                            Chip(text: resources.wineFilterLabel(item.rawValue), isSelected: pairing == item) {
                                pairing = pairing == item ? nil : item
                            }
                        }
                    }
                    group(resources.chooseYourWineCardNotesTitle, hint: resources.chooseYourWineCardNotesHint) {
                        ForEach(WineDiscovery.Note.allCases, id: \.self) { note in
                            Chip(text: resources.wineFilterLabel(note.rawValue), isSelected: notes.contains(note)) { toggle(note) }
                                .disabled(notes.count >= resources.maximumNotes && !notes.contains(note))
                        }
                    }

                    PillButton(action: findWine) { Text(resources.chooseYourWineCardFindTitle) }
                        .padding(.top, 30)
                }
            }
        }
        .sheet(isPresented: $showingResult) {
            result
                .presentationDragIndicator(.visible)
        }
    }

    private var directionPicker: some View {
        HStack(spacing: 6) {
            Chip(text: resources.chooseYourWineFamiliarTitle, isSelected: direction == .familiar, fillsWidth: true) {
                direction = .familiar
            }
            Chip(text: resources.chooseYourWineSurpriseTitle, isSelected: direction == .surprise, fillsWidth: true) {
                direction = .surprise
            }
        }
    }

    private var result: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionLabel(text: direction == .familiar ? resources.chooseYourWineFamiliarTitle : resources.chooseYourWineSurpriseTitle)
                if suggestions.indices.contains(resultIndex) {
                    let wine = suggestions[resultIndex]
                    Text(wine.displayName)
                        .font(UVVAFont.sans(28))
                        .accessibilityAddTraits(.isHeader)
                    if let vintage = wine.vintage {
                        Caption(text: String(vintage))
                    }
                    if let note = wine.note {
                        Text(note)
                            .font(UVVAFont.sans(14))
                    }
                    WineMapPager(resources: resources, wine: wine.profile, palate: palateMap)
                        .id(wine.id)
                    if resultIndex + 1 < suggestions.count {
                        PillButton(action: { resultIndex += 1 }) { Text(resources.chooseYourWineAnotherTitle) }
                    }
                } else {
                    Text(resources.chooseYourWineNoMatch)
                        .font(UVVAFont.sans(17))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(26)
        }
        .foregroundStyle(UVVAColor.cream)
        .background(UVVAColor.moss.ignoresSafeArea())
    }

    private func findWine() {
        suggestions = WineDiscovery.suggestions(in: catalog, for: palateMap, direction: direction,
                                                 type: type, country: country, notes: notes, pairing: pairing)
        resultIndex = 0
        showingResult = true
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
                Caption(text: title)
                Spacer()
                if let hint {
                    Text(hint).font(UVVAFont.sans(11.5)).foregroundStyle(UVVAColor.cream84)
                }
            }
            FlowLayout(spacing: 6, lineSpacing: 8) { chips() }
        }
        .padding(.top, 30)
    }
}
