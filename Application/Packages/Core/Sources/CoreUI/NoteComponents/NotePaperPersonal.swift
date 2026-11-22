#if os(iOS)
import Core
import SwiftUI

/// The wine and you, the same on the new note and on a saved note: the match with its Hide button, and under it
/// what is the user's own (the grape, region and palate lines, then the two maps). Hide folds it all away; on the
/// new note the choice holds until the user opens it again, a saved note always opens with it shown.
public struct NotePaperPersonal: View {
    var match: Int?
    var insights: [NoteInsightUIModel]
    var profile: PalateMap
    var palate: PalateMap?
    /// "High in body, like your map." and "More oak than you usually drink.", shown under the maps only when there
    /// is no "For you" line to say it.
    var shared: String?
    var apart: String?
    var resources: NotePaperResources
    /// The new note keeps Hide for the next one; a saved note always opens with it all shown.
    var remembersChoice: Bool

    @AppStorage("note.insights.shown") private var rememberedShown = true
    @State private var localShown = true

    private var isShown: Binding<Bool> { remembersChoice ? $rememberedShown : $localShown }

    public init(match: Int?, insights: [NoteInsightUIModel], profile: PalateMap, palate: PalateMap?,
                shared: String?, apart: String?, remembersChoice: Bool = true,
                resources: NotePaperResources = NotePaperResources()) {
        self.match = match
        self.insights = insights
        self.profile = profile
        self.palate = palate
        self.shared = shared
        self.apart = apart
        self.remembersChoice = remembersChoice
        self.resources = resources
    }

    private var showsReasons: Bool {
        !insights.contains { $0.icon == .palate } && (shared != nil || apart != nil)
    }

    public var body: some View {
        // As much room above the first line as between the lines, so it does not read as part of the match.
        VStack(alignment: .leading, spacing: 32) {
            // The pill on the line of "match with your map", not floating at the middle of the 72%.
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                NotePaperMatch(match: match, resources: resources)
                Spacer(minLength: 0)
                NotePaperExpandButton(isExpanded: isShown, resources: resources)
            }
            if isShown.wrappedValue {
                // Wider than between the lines, so the maps read as their own part.
                VStack(alignment: .leading, spacing: 56) {
                    if !insights.isEmpty {
                        NotePaperInsights(insights: insights)
                    }
                    VStack(alignment: .leading, spacing: 28) {
                        NotePaperMaps(profile: profile, palate: palate, resources: resources)
                        if showsReasons {
                            NotePaperMatchReasons(shared: shared, apart: apart)
                        }
                    }
                }
                // A short drop as they fade in, so the paper under them moves with them.
                .transition(.opacity.combined(with: .offset(y: -10)))
            }
        }
    }
}
#endif
