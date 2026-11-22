import Core
import Foundation
import Match

/// One line under the match, behind its Hide button: what the user knows of the grape, of the region, and why the
/// wine should or should not suit their map.
public struct NoteInsightUIModel: Identifiable, Equatable {
    public enum Icon: Equatable { case grape, region, palate }

    /// How the circle round the icon reads before any word: filled for what the user likes, a dashed line for what
    /// is new to them, a plain line for the rest.
    public enum Tone: Equatable { case liked, known, new }

    public var icon: Icon
    public var tone: Tone
    /// What the line is about: "Grape", "Region", "For you".
    public var category: String
    /// The verdict, with the grape or region in bold markdown: "You like **Syrah**".
    public var text: String
    /// What it rests on, "You said yes to 3 of 4", or the reason for the palate line. Nil when there is nothing.
    public var detail: String?
    public var id: Icon { icon }

    public init(icon: Icon, tone: Tone, category: String, text: String, detail: String? = nil) {
        self.icon = icon
        self.tone = tone
        self.category = category
        self.text = text
        self.detail = detail
    }

    /// The grape, the region and the palate lines, each when there is something to say: a wine with no grape or
    /// region, or a user without a map, has fewer.
    public static func lines(wine: Wine, palate: PalateMap?, history: TasteHistory,
                             resources: NotePaperResources = NotePaperResources()) -> [NoteInsightUIModel] {
        var lines: [NoteInsightUIModel] = []
        if let (grape, tally) = history.telling(wine.grapes) {
            lines.append(NoteInsightUIModel(icon: .grape, tone: Tone(tally.familiarity),
                                            category: resources.grapeCategoryText,
                                            text: resources.grapeInsight(tally.familiarity, grape: grape),
                                            detail: resources.evidence(tally)))
        }
        if let region = wine.region?.trimmingCharacters(in: .whitespacesAndNewlines), !region.isEmpty {
            let tally = history.tally(region: region)
            lines.append(NoteInsightUIModel(icon: .region, tone: Tone(tally.familiarity),
                                            category: resources.regionCategoryText,
                                            text: resources.regionInsight(tally.familiarity, region: region),
                                            detail: resources.evidence(tally)))
        }
        if let palate {
            let outlook = WineOutlook(wine: wine.profile, map: palate)
            lines.append(NoteInsightUIModel(icon: .palate, tone: outlook.lean == .likely ? .liked : .known,
                                            category: resources.forYouCategoryText,
                                            text: resources.outlookHeadline(outlook.lean),
                                            detail: resources.outlookReason(outlook)))
        }
        return lines
    }
}

extension NoteInsightUIModel.Tone {
    init(_ familiarity: Familiarity) {
        switch familiarity {
        case .likes: self = .liked
        case .dislikes, .knowsLittle: self = .known
        case .unknown: self = .new
        }
    }
}

public extension NotePaperResources {
    /// The button beside the match, closed and open.
    var expandInsightsText: String { String(localized: "Expand", bundle: .module) }
    var hideInsightsText: String { String(localized: "Hide", bundle: .module) }
    var insightsShownText: String { String(localized: "Shown", bundle: .module) }
    var insightsHiddenText: String { String(localized: "Hidden", bundle: .module) }

    var grapeCategoryText: String { String(localized: "Grape", bundle: .module) }
    var regionCategoryText: String { String(localized: "Region", bundle: .module) }
    var forYouCategoryText: String { String(localized: "For you", bundle: .module) }

    func grapeInsight(_ familiarity: Familiarity, grape: String) -> String {
        switch familiarity {
        case .likes: String(localized: "You like **\(grape)**", bundle: .module)
        case .dislikes: String(localized: "**\(grape)** hasn't won you over yet", bundle: .module)
        case .knowsLittle: String(localized: "You know **\(grape)**, but have had little of it", bundle: .module)
        case .unknown: String(localized: "**\(grape)** is new to you, worth exploring", bundle: .module)
        }
    }

    func regionInsight(_ familiarity: Familiarity, region: String) -> String {
        switch familiarity {
        case .likes: String(localized: "You like wines from **\(region)**", bundle: .module)
        case .dislikes: String(localized: "**\(region)** hasn't won you over yet", bundle: .module)
        case .knowsLittle: String(localized: "You know **\(region)**, but have had little from it", bundle: .module)
        case .unknown: String(localized: "**\(region)** is new to you, worth exploring", bundle: .module)
        }
    }

    /// "You said yes to 3 of 4", "1 rated so far"; nil when nothing was rated.
    func evidence(_ tally: Tally) -> String? {
        switch tally.familiarity {
        case .likes: return String(localized: "You said yes to \(tally.yes) of \(tally.rated)", bundle: .module)
        case .dislikes: return String(localized: "You said no to \(tally.no) of \(tally.rated)", bundle: .module)
        case .knowsLittle:
            return tally.rated == 1
                ? String(localized: "1 rated so far", bundle: .module)
                : String(localized: "\(tally.rated) rated so far", bundle: .module)
        case .unknown: return nil
        }
    }

    func outlookHeadline(_ lean: WineOutlook.Lean) -> String {
        switch lean {
        case .likely: String(localized: "You'll likely enjoy it", bundle: .module)
        case .mixed: String(localized: "Could go either way", bundle: .module)
        case .unlikely: String(localized: "It may not be for you", bundle: .module)
        }
    }

    /// "High in body and fruit, like your map." or "More oak than you usually drink.": what the lean rests on.
    func outlookReason(_ outlook: WineOutlook) -> String {
        let shared = sharedPhrase(outlook.shared)
        let apart = outlook.apart.map { apartPhrase($0, more: outlook.hasMore) }
        switch (outlook.lean, shared, apart) {
        case let (.likely, shared?, _):
            return String(localized: "\(shared), like your map.", bundle: .module)
        case (.likely, nil, _):
            return String(localized: "Close to your map on every axis.", bundle: .module)
        case let (.unlikely, _, apart?):
            return String(localized: "\(apart) than you usually drink.", bundle: .module)
        case (.unlikely, _, nil):
            return String(localized: "Far from your map.", bundle: .module)
        case let (.mixed, shared?, apart?):
            return String(localized: "\(shared) like your map, but \(apart.lowercased()) than you usually drink.", bundle: .module)
        case let (.mixed, nil, apart?):
            return String(localized: "\(apart) than you usually drink.", bundle: .module)
        case let (.mixed, shared?, nil):
            return String(localized: "\(shared) like your map, but different elsewhere.", bundle: .module)
        case (.mixed, nil, nil):
            return String(localized: "Neither close to your map nor far from it.", bundle: .module)
        }
    }

    /// "High in body and fruit", nil when they share no high axis.
    private func sharedPhrase(_ axes: [PalateAxis]) -> String? {
        let names = axes.map { $0.label.lowercased() }
        switch names.count {
        case 0: return nil
        case 1: return String(localized: "High in \(names[0])", bundle: .module)
        default: return String(localized: "High in \(names[0]) and \(names[1])", bundle: .module)
        }
    }

    /// "More tannin" or "Less acidity".
    private func apartPhrase(_ axis: PalateAxis, more: Bool) -> String {
        let name = axis.label.lowercased()
        return more ? String(localized: "More \(name)", bundle: .module) : String(localized: "Less \(name)", bundle: .module)
    }
}
