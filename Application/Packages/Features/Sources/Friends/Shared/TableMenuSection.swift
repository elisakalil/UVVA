import DesignSystem
import SwiftUI

/// "The perfect table" (FRI-R15): what it is, the menu on its glass card, and the three ways to share it (FRI-R21).
struct TableMenuSection: View {
    var resources: TableResourcesUIModel
    /// Nil: the title alone, as in the table sheet of a friend (FRI-R15a).
    var intro: String?
    /// "You & Marina", "The 4 of you".
    var guests: String
    var footer: String
    var bottles: [TableBottleUIModel]?
    var canShare: Bool
    /// The shape the share screen opens on.
    var onShare: (ShareFormat) -> Void
    /// The title in the brush lettering, as every part of a friend's Compatibility (FRI-R12).
    var brushTitle = false
    /// The shares under the card; the table sheet puts them at its foot instead, after the recipes (FRI-R15a).
    var showsShares = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if brushTitle {
                FriendsCardTitle(text: resources.perfectTableText)
            } else {
                FriendsSectionLabel(text: resources.perfectTableText)
            }
            if let intro {
                Text(intro)
                    .font(UVVAFont.sans(12.5))
                    .lineSpacing(3)
                    .opacity(0.55)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
            card.padding(.top, 16)
            if showsShares {
                TableSharePills(resources: resources, canShare: canShare, onShare: onShare).padding(.top, 10)
            }
        }
    }

    /// The menu: "The perfect dinner for", the guests in the brush lettering, the three courses and the footer.
    private var card: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(resources.dinnerForText.uppercased())
                    .font(UVVAFont.sans(9.5, .regular))
                    .tracking(1.9)
                Text(guests)
                    .font(UVVAFont.whiteGrape(26))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            TableBottlesState(resources: resources, bottles: bottles) { bottles in
                VStack(spacing: 0) {
                    ForEach(Array(bottles.enumerated()), id: \.element.id) { index, bottle in
                        course(bottle).padding(.top, index == 0 ? 0 : 12).padding(.bottom, 12)
                    }
                }
            }
            .padding(.top, 28)
            Text(footer.uppercased())
                .font(UVVAFont.sans(9, .regular))
                .tracking(2)
                .opacity(0.8)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 20)
        .background { FrostedGlass(radius: 0) }
    }

    private func course(_ bottle: TableBottleUIModel) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(bottle.courseText.uppercased())
                .font(UVVAFont.sans(7.5, .regular))
                .tracking(1.8)
                .opacity(0.8)
                .frame(width: 50, alignment: .leading)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 5) {
                Text(bottle.producer.isEmpty ? bottle.wineName : "\(bottle.wineName), \(bottle.producer)")
                    .font(UVVAFont.sans(15, .regular))
                    .fixedSize(horizontal: false, vertical: true)
                Text(bottle.dishTitle)
                    .font(UVVAFont.sans(11.5, .regular))
                    .lineSpacing(2)
                    .opacity(0.82)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The three ways to share a table (FRI-R21): WhatsApp and Instagram in outline, Save image solid.
struct TableSharePills: View {
    var resources: TableResourcesUIModel
    var canShare: Bool
    var onShare: (ShareFormat) -> Void

    var body: some View {
        HStack(spacing: 8) {
            sharePill(resources.whatsAppText, isSolid: false) { onShare(.whatsApp) }
            sharePill(resources.instagramText, isSolid: false) { onShare(.story) }
            sharePill(resources.saveImageText, isSolid: true) { onShare(.story) }
        }
        .disabled(!canShare)
        .opacity(canShare ? 1 : 0.4)
    }

    private func sharePill(_ title: String, isSolid: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.sans(8.5, .semibold))
                .tracking(2)
                .lineLimit(1)
                .foregroundStyle(isSolid ? UVVAColor.mossDeep : UVVAColor.creamFill.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background {
                    Capsule()
                        .fill(UVVAColor.creamFill.opacity(isSolid ? 0.92 : 0))
                        .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(isSolid ? 0 : 0.35), lineWidth: 0.5))
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
