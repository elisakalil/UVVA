import Core
import DesignSystem
import SwiftUI

struct ChooseYourWineCard: View {
    var resources = HomeResourcesUIModel()
    @State private var type: String
    @State private var region: String
    @State private var notes: [String] = []

    init(resources: HomeResourcesUIModel = HomeResourcesUIModel()) {
        self.resources = resources
        _type = State(initialValue: resources.wineTypes[0])
        _region = State(initialValue: resources.anywhere)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: resources.chooseYourWineCardSectionTitle)
            FrostedCard(radius: UVVARadius.hero, padding: 26) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(resources.chooseYourWineCardPrompt)
                        .font(UVVAFont.sans(17.5))
                        .lineSpacing(2)

                    group(resources.chooseYourWineCardTypeTitle) {
                        ForEach(resources.wineTypes, id: \.self) { item in
                            Chip(text: item, isSelected: type == item) { type = item }
                        }
                    }
                    group(resources.chooseYourWineCardRegionTitle) {
                        ForEach(resources.regions, id: \.self) { item in
                            Chip(text: item, isSelected: region == item) { region = item }
                        }
                    }
                    group(resources.chooseYourWineCardNotesTitle, hint: resources.chooseYourWineCardNotesHint) {
                        ForEach(resources.wineNotes, id: \.self) { item in
                            Chip(text: item, isSelected: notes.contains(item)) { toggle(item) }
                        }
                    }

                    PillButton(action: {}) { Text(resources.chooseYourWineCardFindTitle) }
                        .padding(.top, 30)
                }
            }
        }
    }

    private func toggle(_ note: String) {
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
