import Core
import Foundation
import Match

/// Turns the wine list's state into what its screens draw (WINELIST.md).
struct WineListPresentationBuilder {
    let state: WineListState
    let resources: WineListResourcesUIModel

    /// From this match up, a wine "already fits your palate" (WINELIST-R03).
    static let fitPercent = 80
    /// The dishes' share at or above which a wine is "made for" them, and "holds up to" them.
    static let madeFor = 78
    static let holdsUp = 65

    private var format: WineListPriceFormat { WineListPriceFormat(currency: state.currency) }

    func build(into model: inout WineListUIModel) {
        model.step = state.step
        buildCapture(into: &model)
        buildQuestions(into: &model)
        buildResults(into: &model)
        if let pick = state.asked {
            model.ask = WineListAskWriter(language: state.language, format: format).ask(for: pick)
        }
    }

    // MARK: Camera (WINELIST-R03)

    private func buildCapture(into model: inout WineListUIModel) {
        model.isReading = state.isReading
        model.readingPhoto = state.readingPhoto
        model.pagesRead = state.pagesRead
        model.wineCount = state.wines.count
        model.fitCount = state.palate.map { palate in
            state.wines.filter { Similarity.percent(palate, $0.wine.profile) >= Self.fitPercent }.count
        } ?? 0
        model.canUseList = !state.wines.isEmpty && !state.isReading
        model.pageMessage = state.pageMessage
        model.captureTitle = state.wines.isEmpty ? resources.captureTitleText
            : resources.winesFoundText(state.wines.count)
        let usual = state.wines.isEmpty ? resources.captureHintText : resources.fitText(model.fitCount)
        model.captureBody = state.isReading ? usual : state.pageMessage ?? usual
    }

    // MARK: What's on the table? (WINELIST-R06)

    private func buildQuestions(into model: inout WineListUIModel) {
        model.wineCountText = resources.winesOnListText(state.wines.count)
        model.dishes = MenuDish.allCases.map {
            WineListChipUIModel(id: $0.rawValue, text: resources.dishText($0), isSelected: state.dishes.contains($0))
        }
        let options = state.budgetOptions
        model.budgets = options.isEmpty ? [] : options.map {
            WineListChipUIModel(id: String($0), text: format.text($0), isSelected: state.budget == $0)
        } + [WineListChipUIModel(id: "none", text: resources.noLimitText, isSelected: state.budget == nil)]
        model.people = state.friends.isEmpty ? [] : [
            WineListChipUIModel(id: "you", text: resources.youText, isSelected: true, isFixed: true)
        ] + state.friends.map {
            WineListChipUIModel(id: $0.id, text: $0.name, isSelected: state.people.contains($0.id))
        }
    }

    // MARK: Order this (WINELIST-R07)

    private func buildResults(into model: inout WineListUIModel) {
        let palates = state.palates
        let who = palates.count > 1 ? resources.forPeopleText(palates.count) : resources.forYouText
        let dishes = dishNames
        let limit = state.budget.map { resources.upToText(format.text($0)) } ?? resources.anyPriceText
        model.contextLine = ([who] + (dishes.isEmpty ? [] : [dishes]) + [limit]).joined(separator: " · ")
        model.footLine = resources.footText(maps: max(1, palates.count), wines: state.wines.count)
        let picks = state.picks
        guard let first = picks.first else {
            model.hero = nil
            model.others = []
            model.budgetNote = nil
            return
        }
        model.budgetNote = first.fitsBudget ? nil : resources.nothingInBudgetText
        model.hero = pick(first, role: nil)
        model.others = picks.dropFirst().enumerated().map { offset, other in
            pick(other, role: role(of: other, at: offset + 1, after: first))
        }
    }

    private func role(of pick: WineListPick, at index: Int, after hero: WineListPick) -> String? {
        switch index {
        case 1:
            // "Same feel" only for the same kind of wine.
            if pick.wine.wine.type == hero.wine.wine.type, let price = pick.wine.entry.price,
               let top = hero.wine.entry.price, price < top {
                return resources.cheaperText
            }
            return resources.closeSecondText
        case 2:
            return pick.wine.wine.type != hero.wine.wine.type ? resources.differentText : resources.alsoText
        default:
            return nil
        }
    }

    private func pick(_ pick: WineListPick, role: String?) -> WineListPickUIModel {
        let entry = pick.wine.entry
        let wine = pick.wine.wine
        let price = entry.price.map(format.text)
        let place = entry.section.map { resources.placeText(position: entry.position, section: $0) }
        return WineListPickUIModel(
            id: pick.id, role: role, title: title(of: pick.wine), name: entry.name,
            meta: [price, place].compactMap { $0 }.joined(separator: " · "),
            match: pick.percent, price: price, why: why(pick, wine: wine),
            isOverBudget: !pick.fitsBudget, isEstimated: !pick.wine.isKnown)
    }

    /// The grape and the place, as a sommelier would say what the wine is; the list's own line under the name when
    /// neither is known.
    private func title(of listed: WineListWine) -> String {
        let wine = listed.wine
        let grapes = wine.grapes.prefix(2).joined(separator: ", ")
        let place = wine.appellation ?? wine.region ?? (wine.origin.isEmpty ? nil : wine.origin)
        let parts = [grapes.isEmpty ? nil : grapes, place].compactMap { $0 }
        if !parts.isEmpty { return parts.joined(separator: " · ") }
        return listed.entry.details.first ?? listed.entry.name
    }

    private func why(_ pick: WineListPick, wine: Wine) -> String {
        var sentences: [String] = []
        if let palate = state.palates.isEmpty ? nil : TableMatch.crossed(state.palates) {
            let fit = WineFit(wine: wine.profile, map: palate)
            let shared = fit.shared.map { $0.localizedLabel.lowercased() }
            if let first = shared.first {
                sentences.append(resources.sharedText(first, shared.dropFirst().first))
            } else if let apart = fit.apart {
                let label = apart.localizedLabel.lowercased()
                let isMore = WineRuler.position(of: wine.profile[apart], on: apart)
                    > WineRuler.position(of: palate[apart], on: apart)
                sentences.append(isMore ? resources.moreThanUsualText(label) : resources.lessThanUsualText(label))
            } else {
                sentences.append(resources.closeEverywhereText)
            }
            if state.palates.count > 1 { sentences.append(resources.tableText(state.palates.count)) }
        }
        if let dish = pick.dishPercent, !dishNames.isEmpty {
            sentences.append(dish >= Self.madeFor ? resources.madeForText(dishNamesLowercased)
                : dish >= Self.holdsUp ? resources.holdsUpText(dishNamesLowercased)
                : resources.notObviousText(dishNamesLowercased))
        }
        return sentences.joined(separator: " ")
    }

    private var orderedDishes: [MenuDish] { MenuDish.allCases.filter(state.dishes.contains) }

    private var dishNames: String {
        orderedDishes.map(resources.dishText).map { $0.lowercased() }.joined(separator: ", ")
    }

    private var dishNamesLowercased: String {
        orderedDishes.map { resources.dishText($0).lowercased() }.formatted(.list(type: .and))
    }
}
