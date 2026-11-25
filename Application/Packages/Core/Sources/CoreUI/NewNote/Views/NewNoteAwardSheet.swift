#if os(iOS)
import Core
import DesignSystem
import SwiftUI

/// An award chosen by hand (CELLAR-R23): the competition or critic from the list UVVA knows, then the medal or the
/// score, and the year when the person knows it.
struct NewNoteAwardSheet: View {
    var resources: NewNoteResourcesUIModel
    /// The wine's vintage: an award comes after it.
    var vintage: Int?
    var currentYear: Int
    var onAdd: (WineAward) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var source: AwardSource?
    @State private var medal: WineAward.Medal?
    @State private var points: Int?
    @State private var year: Int?

    /// The scores critics give a wine worth printing on its label.
    private static let scores = Array((85...100).reversed())

    private var years: [Int] {
        let first = max(vintage ?? currentYear - 15, currentYear - 30)
        return Array((first...currentYear).reversed())
    }

    private var award: WineAward? {
        guard let source else { return nil }
        if source.isCritic {
            return points.map { WineAward(competition: source.name, points: $0, year: year) }
        }
        return medal.map { WineAward(competition: source.name, medal: $0, year: year) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(resources.awardsFieldText.uppercased())
                    .font(UVVAFont.redGrapes(20))
                    .tracking(0.8)
                    .accessibilityAddTraits(.isHeader)
                section(resources.awardSourceText) {
                    ForEach(CertificationKeywords.sources, id: \.name) { option in
                        Chip(text: option.name, isSelected: source?.name == option.name) {
                            source = source?.name == option.name ? nil : option
                            medal = nil
                            points = nil
                        }
                    }
                }
                if let source, source.isCritic {
                    section(resources.scoreText) {
                        ForEach(Self.scores, id: \.self) { score in
                            Chip(text: "\(score)", isSelected: points == score) {
                                points = points == score ? nil : score
                            }
                        }
                    }
                } else if source != nil {
                    section(resources.medalText) {
                        ForEach(WineAward.Medal.allCases, id: \.self) { option in
                            Chip(text: resources.medal(option), isSelected: medal == option) {
                                medal = medal == option ? nil : option
                            }
                        }
                    }
                }
                if source != nil {
                    section(resources.yearText) {
                        ForEach(years, id: \.self) { option in
                            Chip(text: String(option), isSelected: year == option) {
                                year = year == option ? nil : option
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 34)
        }
        .scrollIndicators(.hidden)
        // "Add" floats over the chips: they scroll on behind it, under no band of their own.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PillButton(style: .filled, action: add) { Text(resources.addText) }
                .disabled(award == nil)
                // Disabled, it is only a ring: the sheet's ground under it keeps the chips out of its label.
                .background { if award == nil { NewNoteSheetGroundCapsule() } }
                .padding(.horizontal, 26)
                .padding(.top, 20)
                .padding(.bottom, 14)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
        .newNoteSheetGround()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func section(_ title: String, @ViewBuilder chips: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(UVVAFont.sans(12.5)).opacity(0.8)
            FlowLayout { chips() }
        }
    }

    private func add() {
        guard let award else { return }
        onAdd(award)
        dismiss()
    }
}
#endif
