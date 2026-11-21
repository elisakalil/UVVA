import CoreUI
import DesignSystem
import SwiftUI

/// The group table (FRI-R19), laid out as a friend: "Back", `+` and who sits at it stay at the top; under them the
/// match, where the table lands, reading by reading, the bottles to open together and, at the foot, the choices of
/// the dinner, which opens in its own sheet (FRI-R15a).
struct GroupTableView<ViewModel: GroupTableViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    /// The pill that opened the share screen (FRI-R21).
    @State private var shareFormat: ShareFormat = .story

    private var model: GroupTableUIModel { viewModel.uiModel }
    private var resources: GroupTableResourcesUIModel { model.resources }

    var body: some View {
        ZStack(alignment: .top) {
            PageBackground(photo: UVVAPhoto.hills, veiled: true)
            VStack(spacing: 0) {
                // As on a friend, "Back", `+` and who sits at the table stay at the top; only the page scrolls.
                topBar
                header.padding(.horizontal, 26)
                FriendsHairline().padding(.top, 26)
                ScrollView {
                    content
                        .padding(.horizontal, 26)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
                .scrollEdgeFade(12, throughBottomInset: true)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        // The glass shows the hills it scrolls over.
        .environment(\.glassPhoto, .hills)
        .task { await viewModel.load() }
        // A bottle or a scanned wine, read on every map at the table, to send to them all.
        .sheet(item: Binding(get: { model.friendWine }, set: { if $0 == nil { viewModel.closeWine() } })) { wine in
            FriendWineView(model: wine, onPrimary: { Task { await viewModel.sendWine() } })
        }
        // The label scanner; the wine it reads opens in Friend Wine once it is gone.
        .sheet(item: Binding(get: { model.scanner }, set: { if $0 == nil { viewModel.closeScanner() } }),
               onDismiss: viewModel.scannerDismissed) { scanner in
            NewNoteView(viewModel: scanner)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        // FRI-R15a: the table, its recipes and its shares, in a sheet; the share screen opens over it.
        .sheet(isPresented: Binding(get: { model.isTableOpen }, set: { if !$0 { viewModel.closeTable() } })) {
            TableSheet(guests: model.guestsText, footer: model.footerText, bottles: model.bottles,
                       recipes: model.recipes, canShare: model.share != nil, table: resources.table,
                       dinner: resources.dinner) { format in
                shareFormat = format
                viewModel.openShare()
            }
            .fullScreenCover(isPresented: Binding(get: { model.isSharing }, set: { if !$0 { viewModel.closeShare() } })) {
                if let share = model.share { TableShareView(model: share, format: shareFormat, onFinish: viewModel.closeShare) }
            }
        }
    }

    /// "Back" in a pill and, on the right, `+` to scan a wine, as on a friend.
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

    /// Everyone's face, "The table" and "4 maps · one bottle".
    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(model.memberNames.indices, id: \.self) { _ in FriendsAvatar(size: 46) }
            }
            .accessibilityHidden(true)
            Text(resources.tableText)
                .font(UVVAFont.sans(27, .ultraLight))
                .tracking(-0.4)
                .padding(.top, 16)
                .accessibilityAddTraits(.isHeader)
            Text(model.mapsText.uppercased())
                .font(UVVAFont.sans(10))
                .tracking(2.6)
                .opacity(0.7)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 26)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            FlowLayout(spacing: 8) {
                ForEach(Array(model.memberNames.enumerated()), id: \.offset) { _, name in
                    Text(name)
                        .font(UVVAFont.sans(12))
                        .opacity(0.86)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 14)
                        .background(UVVAColor.creamFill.opacity(0.05), in: Capsule())
                        .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.22), lineWidth: 0.5))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.membersText)

            match.padding(.top, 24)
            readingByReading.padding(.top, 36)

            // A bottle opens Friend Wine, read on every map at the table, to send to them all.
            FriendWinesCard(title: resources.table.openTogetherText, rows: model.togetherWines,
                            loadingText: resources.table.buildingText, emptyText: resources.table.noBottlesText,
                            onOpen: viewModel.openTableWine)
                .padding(.top, sectionGap)
            DinnerChoicesSection(dinner: model.dinner, resources: resources.dinner,
                                 onToggleCourse: viewModel.toggleCourse, onPickFood: viewModel.pickFood,
                                 onToggleInSeason: viewModel.toggleInSeason, onPickTime: viewModel.pickTime,
                                 onSetTable: { Task { await viewModel.setTable() } })
                .padding(.top, sectionGap)
        }
    }

    /// Between the bottles and the dinner, as on a friend's Compatibility.
    private var sectionGap: CGFloat { 52 }

    /// "71%" large and thin, as a friend's match, and on its right "match across all 4 palate maps at the table"
    /// and what the table shares.
    private var match: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(model.matchValueText)
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
                Text(model.phrase)
                    .font(UVVAFont.sans(14))
                    .lineSpacing(4)
                    .opacity(0.9)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// FRI-R19, on its glass card as a friend's: where the table lands over the boldest reading, then, expanded, each
    /// axis with the range at the table.
    private var readingByReading: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                FriendsCardTitle(text: resources.readingByReadingText)
                Spacer(minLength: 0)
                Button { withAnimation(.easeOut(duration: 0.25)) { viewModel.toggleReadings() } } label: {
                    FriendsPillLabel(text: model.isReadingsExpanded ? resources.collapseText : resources.expandText)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(resources.readingByReadingText)
                .accessibilityValue(model.isReadingsExpanded ? resources.collapseText : resources.expandText)
            }
            // The chart is 330 pt wide: it takes the card's whole width, past the padding of the text.
            FriendsMapChart(style: .table(average: model.averageChart, boldest: model.boldestChart))
                .padding(.horizontal, -20)
                .padding(.top, 8)
            // The same lines as the chart: where the table lands solid, the boldest reading dashed. On one line when
            // they fit, one under the other when they do not.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) { legend }.fixedSize()
                VStack(alignment: .leading, spacing: 9) { legend }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .accessibilityHidden(true)
            if model.isReadingsExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(model.readings) { row in
                        if row.id != model.readings.first?.id {
                            Rectangle().fill(UVVAColor.creamFill.opacity(0.09)).frame(height: 1)
                        }
                        AxisSpreadRow(row: row)
                    }
                    HStack(spacing: 16) {
                        ChartLegendItem(text: resources.rangeAtTableText, lineOpacity: 0.5, weight: .light)
                        HStack(spacing: 8) {
                            Circle().fill(UVVAColor.creamFill.opacity(0.85)).frame(width: 7, height: 7)
                                .frame(width: 14)
                            Text(resources.middleText.uppercased())
                                .font(UVVAFont.sans(8, .light))
                                .tracking(1.1)
                                .opacity(0.4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .accessibilityHidden(true)
                }
                .padding(.top, 14)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background { FrostedGlass(radius: UVVARadius.card) }
    }

    @ViewBuilder private var legend: some View {
        ChartLegendItem(text: resources.whereItLandsText, weight: .light)
        ChartLegendItem(text: resources.boldestText, dash: [3, 4], lineOpacity: 0.55, weight: .light)
    }
}

#if DEBUG
#Preview {
    GroupTableView(viewModel: MockGroupTableViewModel())
}
#endif
