#if os(iOS)
import DesignSystem
import SwiftUI

/// "Order this" (WINELIST-R07): the best match for tonight first and largest, with why and how to ask for it; the
/// other wines under it, smaller, best first. Tapping any of them opens the line for the waiter.
struct WineListResultsView: View {
    var model: WineListUIModel
    var onBack: () -> Void
    var onAsk: (String) -> Void

    private var resources: WineListResourcesUIModel { model.resources }
    @State private var appeared = false

    var body: some View {
        ZStack {
            PageBackground()
            LinearGradient(colors: [.clear, UVVAColor.night.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    WineListTopBar(caption: model.contextLine, backText: resources.backText, onBack: onBack)
                    if let hero = model.hero {
                        Spacer().frame(height: 64)
                        if let note = model.budgetNote {
                            Text(note)
                                .font(UVVAFont.sans(12))
                                .foregroundStyle(UVVAColor.cream84)
                                .padding(.horizontal, 4)
                        }
                        heroCard(hero)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                        ForEach(Array(model.others.enumerated()), id: \.element.id) { index, pick in
                            otherCard(pick)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 24)
                                .animation(.spring(duration: 0.6, bounce: 0.2).delay(0.12 + Double(min(index, 6)) * 0.05),
                                           value: appeared)
                        }
                        Text(model.footLine.uppercased())
                            .font(UVVAFont.sans(9, .regular))
                            .tracking(2)
                            .foregroundStyle(UVVAColor.creamFill.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.top, 18)
                    } else {
                        empty
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
        .onAppear { withAnimation(.spring(duration: 0.6, bounce: 0.2)) { appeared = true } }
    }

    private func heroCard(_ hero: WineListPickUIModel) -> some View {
        FrostedCard(radius: UVVARadius.hero, padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(resources.orderThisText)
                        .font(UVVAFont.sans(13.5, .regular))
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(hero.match)")
                            .font(UVVAFont.sans(44, .ultraLight))
                            .tracking(-1.8)
                        Text("%").font(UVVAFont.sans(13)).foregroundStyle(UVVAColor.creamFill.opacity(0.82))
                    }
                    .accessibilityElement(children: .combine)
                }
                Text(hero.title)
                    .font(UVVAFont.sans(30))
                    .tracking(-0.6)
                    .lineSpacing(-2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
                    .padding(.trailing, 40)
                Text(hero.name)
                    .font(UVVAFont.sans(14.5, .medium))
                    .padding(.top, 18)
                    .fixedSize(horizontal: false, vertical: true)
                metaLine(hero)
                    .padding(.top, 6)
                if !hero.why.isEmpty {
                    Text(hero.why)
                        .font(UVVAFont.sans(12.5))
                        .lineSpacing(3)
                        .foregroundStyle(UVVAColor.creamFill.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 16)
                        .overlay(alignment: .top) {
                            Rectangle().fill(UVVAColor.creamFill.opacity(0.14)).frame(height: 1)
                        }
                        .padding(.top, 18)
                }
                ActionButton(resources.howToAskText, style: .outline) { onAsk(hero.id) }
                    .padding(.top, 18)
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 20)
        }
    }

    private func metaLine(_ pick: WineListPickUIModel) -> some View {
        HStack(spacing: 8) {
            Text(pick.meta)
            if pick.isOverBudget { tag(resources.overBudgetText) }
            if pick.isEstimated { tag(resources.estimatedText) }
        }
        .font(UVVAFont.sans(12, .regular))
        .foregroundStyle(UVVAColor.creamFill.opacity(0.92))
    }

    private func tag(_ text: String) -> some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(8.5, .regular))
            .tracking(1.2)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.35), lineWidth: 0.5))
    }

    private func otherCard(_ pick: WineListPickUIModel) -> some View {
        Button { onAsk(pick.id) } label: {
            FrostedCard(radius: UVVARadius.card, padding: 0) {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let role = pick.role {
                            Text(role.uppercased())
                                .font(UVVAFont.sans(10, .regular))
                                .tracking(1.8)
                        }
                        Text(pick.title)
                            .font(UVVAFont.sans(16))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(pick.name)
                            .font(UVVAFont.sans(11.5))
                            .foregroundStyle(UVVAColor.creamFill.opacity(0.84))
                            .fixedSize(horizontal: false, vertical: true)
                        if pick.isOverBudget || pick.isEstimated {
                            HStack(spacing: 6) {
                                if pick.isOverBudget { tag(resources.overBudgetText) }
                                if pick.isEstimated { tag(resources.estimatedText) }
                            }
                            .foregroundStyle(UVVAColor.creamFill.opacity(0.8))
                        }
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("\(pick.match)%")
                            .font(UVVAFont.sans(22, .ultraLight))
                            .tracking(-0.6)
                        if let price = pick.price {
                            Text(price)
                                .font(UVVAFont.sans(11))
                                .foregroundStyle(UVVAColor.creamFill.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 17)
            }
            .opacity(pick.isOverBudget ? 0.72 : 1)
        }
        .buttonStyle(.plain)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(resources.emptyTitleText).font(UVVAFont.whiteGrape(30))
            Text(resources.emptyBodyText).font(UVVAFont.sans(13)).foregroundStyle(UVVAColor.cream84)
        }
        .padding(.top, 120)
    }
}
#endif
