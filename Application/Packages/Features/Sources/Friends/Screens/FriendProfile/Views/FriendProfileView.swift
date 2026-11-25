import CoreUI
import DesignSystem
import SwiftUI

/// A friend (FRIENDS.md §5): "Back" and `+`, who they are, and the Map and Compatibility tabs stay at the
/// top, as on You; only the tab's page scrolls under them.
struct FriendProfileView<ViewModel: FriendProfileViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    /// The Cellar's new note, for "Add to cellar" on a wine for the two: it opens over the friend.
    var newNote: Binding<NewNoteViewModel?> = .constant(nil)
    /// The pill that opened the share screen (FRI-R21).
    @State private var shareFormat: ShareFormat = .story

    private var model: FriendProfileUIModel { viewModel.uiModel }
    private var resources: FriendProfileResourcesUIModel { model.resources }

    var body: some View {
        ZStack(alignment: .top) {
            PageBackground(photo: UVVAPhoto.hills, veiled: true)
            VStack(spacing: 0) {
                topBar
                header.padding(.horizontal, 26)
                FriendProfileTabBar(resources: resources, selected: model.tab, onSelect: viewModel.selectTab)
                    .padding(.top, 26)
                ScrollView {
                    content
                        .padding(.horizontal, 26)
                        .padding(.top, 24)
                        // On Map, "Remove friend" sits halfway between the last card and the foot of the screen.
                        .padding(.bottom, model.tab == .map ? 4 : 40)
                        // As on the Home: the cards leave the photo to the scroll view's backdrop, drawn once
                        // behind it, instead of each moving its own copy on every frame of the scroll.
                        .glassPanes(rimOpacity: 0.5)
                }
                .glassBackdrop()
                .scrollIndicators(.hidden)
                .scrollEdgeFade(12, throughBottomInset: true)
                // Each tab opens at its top.
                .id(model.tab)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        // The glass shows the hills it scrolls over.
        .environment(\.glassPhoto, .hills)
        .task { await viewModel.load() }
        // FRI-R11a: Friend Wine, whose foot sends the wine to the friend (FRI-R11b).
        .sheet(item: Binding(get: { model.friendWine }, set: { if $0 == nil { viewModel.closeWine() } }),
               onDismiss: viewModel.wineDismissed) { wine in
            FriendWineView(model: wine, onPrimary: { Task { await viewModel.sendWine() } },
                           onAddToCellar: viewModel.addWineToCellar)
        }
        .newNoteSheet(newNote)
        // FRI-R12a: the label scanner; the wine it reads opens in Friend Wine once it is gone.
        .sheet(item: Binding(get: { model.scanner }, set: { if $0 == nil { viewModel.closeScanner() } }),
               onDismiss: viewModel.scannerDismissed) { scanner in
            NewNoteView(viewModel: scanner)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        // FRI-R15a: the table for two, its recipes and its shares, in a sheet; the share screen opens over it.
        .sheet(isPresented: Binding(get: { model.isTableOpen }, set: { if !$0 { viewModel.closeTable() } })) {
            TableSheet(guests: model.guestsText, footer: resources.menuFooterText, bottles: model.bottles,
                       recipes: model.recipes, canShare: model.share != nil, table: resources.table,
                       dinner: resources.dinner) { format in
                shareFormat = format
                viewModel.openShare()
            }
            .fullScreenCover(isPresented: Binding(get: { model.isSharing }, set: { if !$0 { viewModel.closeShare() } })) {
                if let share = model.share { TableShareView(model: share, format: shareFormat, onFinish: viewModel.closeShare) }
            }
        }
        .confirmationDialog(model.removeTitle,
                            isPresented: Binding(get: { model.isConfirmingRemoval }, set: { if !$0 { viewModel.cancelRemoval() } }),
                            titleVisibility: .visible) {
            Button(resources.removeText, role: .destructive) { Task { await viewModel.confirmRemoval() } }
            Button(resources.cancelText, role: .cancel) { viewModel.cancelRemoval() }
        } message: {
            Text(model.removeBody)
        }
    }

    /// "Back" in a pill and, on the right, `+` to scan a wine (FRI-R12a), as the `+` of the Cellar and the Home.
    private var topBar: some View {
        FriendsTopBar(caption: nil, backText: resources.table.backText, onBack: viewModel.close) {
            if model.canScan {
                Button(action: viewModel.scanWine) {
                    Text(verbatim: "+")
                        .font(UVVAFont.sans(38, .ultraLight))
                        .frame(width: 52, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(resources.scanButtonText)
                .padding(.trailing, -14)
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 8)
    }

    /// The avatar, the name and the signature, in the middle of the page.
    private var header: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                FriendsAvatar(size: 70)
                Text(model.name)
                    .font(UVVAFont.sans(27, .ultraLight))
                    .tracking(-0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 14)
                    .accessibilityAddTraits(.isHeader)
                Text(model.signature)
                    .font(UVVAFont.sans(10))
                    .tracking(2.6)
                    .opacity(0.7)
                    .padding(.top, 12)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 26)
        }
    }

    @ViewBuilder private var content: some View {
        switch model.tab {
        case .map: mapTab
        case .compatibility: compatibility
        }
    }

    // MARK: FRI-R11 · Map

    /// "[Name] Map", then "Picks for [name]" once the catalog has some.
    private var mapTab: some View {
        VStack(spacing: 10) {
            readingsPanel
            if let wines = model.giftWines, !wines.isEmpty {
                // FRI-R11: a wine opens Friend Wine.
                FriendWinesCard(title: model.giftTitle, rows: wines, onOpen: viewModel.openWine)
                    .transition(.opacity)
            }
            // D4: at the foot of the friend, where it is not tapped by chance.
            Button(resources.removeText, action: viewModel.askToRemove)
                .font(UVVAFont.sans(11.5))
                .opacity(0.55)
                .frame(minHeight: 44)
                .buttonStyle(.plain)
                .padding(.top, 18)
        }
        .animation(.easeOut(duration: 0.25), value: model.giftWines)
    }

    private var readingsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            FriendsCardTitle(text: model.mapTitle)
            FriendMiniChart(values: model.friendChart, strong: model.strongAxes)
                .padding(.top, 22)
            Text(model.caption)
                .font(UVVAFont.sans(13.5, .regular))
                .lineSpacing(5)
                .opacity(0.72)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
            VStack(spacing: 0) {
                ForEach(model.readings) { row in
                    if row.id != model.readings.first?.id {
                        Rectangle().fill(UVVAColor.creamFill.opacity(0.09)).frame(height: 1)
                    }
                    PalateReadingLine(name: row.name, level: row.level, word: row.word, isStrong: row.isStrong)
                }
            }
            .padding(.top, 18)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background { FrostedGlass(radius: UVVARadius.card) }
    }

    // MARK: FRI-R12 · Compatibility

    /// The match, the two maps, reading by reading, the bottles to open together and, at the foot, the choices of
    /// the table for two, which opens in its own sheet (FRI-R15a).
    private var compatibility: some View {
        VStack(alignment: .leading, spacing: 0) {
            match
            readingByReading.padding(.top, 36)
            // FRI-R11a: a bottle opens Friend Wine, read on both maps, to send to the friend.
            FriendWinesCard(title: resources.table.openTogetherText, rows: model.togetherWines,
                            loadingText: resources.table.buildingText, emptyText: resources.table.noBottlesText,
                            onOpen: viewModel.openTableWine)
                .padding(.top, sectionGap)
            dinner.padding(.top, sectionGap)
        }
    }

    /// Between the parts of Compatibility.
    private var sectionGap: CGFloat { 52 }

    /// "82%" large and thin, and on its right "of your palate map matches Marina" and what the two maps share.
    private var match: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(model.compatibilityText)
                .font(UVVAFont.sans(78, .ultraLight))
                .tracking(-2)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
                .accessibilityLabel(model.matchTitle)
            VStack(alignment: .leading, spacing: 10) {
                Text(model.matchCaption)
                    .font(UVVAFont.sans(12))
                    .lineSpacing(3)
                    .opacity(0.68)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
                Text(model.overlapPhrase)
                    .font(UVVAFont.sans(14))
                    .lineSpacing(4)
                    .opacity(0.9)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// FRI-R12: the two maps over each other, then each axis with the verdict, and both readings as rows of pips,
    /// the user's over the friend's.
    private var readingByReading: some View {
        VStack(alignment: .leading, spacing: 0) {
            FriendsCardTitle(text: resources.readingByReadingText)
            // The chart is 330 pt wide: it takes the card's whole width, past the padding of the text.
            FriendsMapChart(style: .overlap(mine: model.userChart, theirs: model.friendChart))
                .padding(.horizontal, -20)
                .padding(.top, 18)
            HStack(spacing: 22) {
                ChartLegendItem(text: resources.youText, weight: .light)
                ChartLegendItem(text: model.firstName, dash: [3, 4], lineOpacity: 0.55, weight: .light)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .accessibilityHidden(true)
            VStack(spacing: 0) {
                ForEach(model.compareRows) { row in
                    if row.id != model.compareRows.first?.id {
                        Rectangle().fill(UVVAColor.creamFill.opacity(0.09)).frame(height: 1)
                    }
                    FriendCompareRow(row: row, youText: resources.youText, friendName: model.firstName)
                }
            }
            .padding(.top, 14)
            .padding(.bottom, -14)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background { FrostedGlass(radius: UVVARadius.card) }
    }

    // MARK: FRI-R13, R13a, R15 · Set the perfect dinner

    /// The choices of the dinner, as chips, and "Set the perfect dinner".
    private var dinner: some View {
        DinnerChoicesSection(dinner: model.dinner, resources: resources.dinner,
                             onToggleCourse: viewModel.toggleCourse, onPickFood: viewModel.pickFood,
                             onToggleInSeason: viewModel.toggleInSeason, onPickTime: viewModel.pickTime,
                             onSetTable: { Task { await viewModel.setTable() } })
    }
}

/// An axis of "Reading by reading" (FRI-R12): its name and how far apart the two are, then the user's reading and
/// the friend's, each as ten pips like the Map's readings; the friend's a shade fainter.
struct FriendCompareRow: View {
    var row: FriendCompareRowUIModel
    var youText: String
    var friendName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name.uppercased())
                    .font(UVVAFont.sans(11.5))
                    .tracking(1.8)
                    .opacity(row.isSame ? 1 : 0.8)
                Spacer()
                Text(row.verdict.uppercased())
                    .font(UVVAFont.sans(9))
                    .tracking(1.8)
                    .opacity(0.5)
            }
            VStack(alignment: .leading, spacing: 8) {
                reading(youText, level: row.mineLevel, opacity: 0.92)
                reading(friendName, level: row.theirsLevel, opacity: 0.5)
            }
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.name)
        .accessibilityValue("\(row.verdict). \(youText) \(row.mineLevel + 1) of 10, \(friendName) \(row.theirsLevel + 1) of 10")
    }

    private func reading(_ who: String, level: Int, opacity: Double) -> some View {
        HStack(spacing: 14) {
            Text(who.uppercased())
                .font(UVVAFont.sans(8.5))
                .tracking(1.5)
                .opacity(0.55)
                .lineLimit(1)
                .frame(width: 72, alignment: .leading)
            HStack(spacing: 5) {
                ForEach(0..<10, id: \.self) { index in
                    if index <= level {
                        Circle().opacity(opacity).frame(width: 5, height: 5)
                    } else {
                        Circle().strokeBorder(lineWidth: 0.5).opacity(0.3).frame(width: 5, height: 5)
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    FriendProfileView(viewModel: MockFriendProfileViewModel())
}
#endif
