//
//  ChooseYourWineCard.swift
//  UVVA
//
//  Created by Elisa Elias on 28/10/2026.
//

import SwiftUI

struct ChooseYourWineCard: View {
    static let types = ["Red", "White", "Rosé", "Sparkling", "Sweet", "Fortified"]
    static let anywhere = "Anywhere"
    static let regions = [anywhere, "Portugal", "France", "Italy", "Spain", "United States", "Argentina", "Chile",
                          "Germany", "Austria", "Australia", "New Zealand", "South Africa"]
    static let notes = ["Citrus", "Orchard fruit", "Tropical", "Red fruit", "Dark fruit", "Floral", "Herbal",
                        "Spiced", "Mineral", "Earthy", "Toasty"]
    static let maxNotes = 3

    @State private var type = types[0]
    @State private var region = anywhere
    @State private var notes: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Choose your wine")
            FrostedCard(radius: UVVARadius.hero, padding: 26) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Tell us what you feel like tonight.")
                        .font(UVVAFont.sans(17.5))
                        .lineSpacing(2)

                    group("Type") {
                        ForEach(Self.types, id: \.self) { item in
                            Chip(text: item, isSelected: type == item) { type = item }
                        }
                    }
                    group("Region") {
                        ForEach(Self.regions, id: \.self) { item in
                            Chip(text: item, isSelected: region == item) { region = item }
                        }
                    }
                    group("Notes", hint: "Pick up to three") {
                        ForEach(Self.notes, id: \.self) { item in
                            Chip(text: item, isSelected: notes.contains(item)) { toggle(item) }
                        }
                    }

                    PillButton(action: {}) { Text("Find my wine") }
                        .padding(.top, 30)
                }
            }
        }
    }

    private func toggle(_ note: String) {
        if let index = notes.firstIndex(of: note) {
            notes.remove(at: index)
        } else if notes.count < Self.maxNotes {
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
