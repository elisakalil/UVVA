import DesignSystem
import SwiftUI

/// The group table (FRI-R19): the match, where the table lands, reading by reading, the bottles and the menu.
struct GroupTableView<ViewModel: GroupTableViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    private var model: GroupTableUIModel { viewModel.uiModel }
    private var resources: GroupTableResourcesUIModel { model.resources }

    var body: some View {
        ZStack(alignment: .top) {
            PageBackground(blur: 2, veiled: true)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: viewModel.close) {
                        Image(systemName: resources.closeIcon)
                            .font(.system(size: 15, weight: .light))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(resources.closeText)
                    .padding(.leading, -12)
                    .padding(.top, 8)

                    Eyebrow(text: model.membersText).padding(.top, 18)
                    Text(model.matchTitle).font(UVVAFont.sans(26, .ultraLight)).lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .accessibilityAddTraits(.isHeader)
                    Text(model.phrase).font(UVVAFont.sans(15, .light)).lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 16)

                    SectionLabel(text: resources.whereItLandsText).padding(.top, 22)
                    PalateMapChart(values: model.averageChart, labels: PalateAxisLabels.all, outline: model.boldestChart)
                        .scaleEffect(0.84)
                        .frame(width: PalateMapChart.size.width * 0.84, height: PalateMapChart.size.height * 0.84)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                    legend

                    readingByReading.padding(.top, 20)

                    SectionLabel(text: resources.table.openTogetherText).padding(.top, 14)
                    TableBottlesList(resources: resources.table, bottles: model.bottles, style: .axis)

                    SectionLabel(text: resources.perfectTableText).padding(.top, 14)
                    Text(model.dinnerTitle).font(UVVAFont.sans(22, .ultraLight)).lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                    TableBottlesList(resources: resources.table, bottles: model.bottles, style: .course)
                        .padding(.top, 6)
                    Text(model.footerText.uppercased()).font(UVVAFont.sans(8.5)).tracking(1.8).opacity(0.55)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .task { await viewModel.load() }
    }

    /// The table in a dashed shape with dots; the boldest reading in a fine dotted line.
    private var legend: some View {
        HStack(spacing: 18) {
            legendItem(dash: [2.5, 3.5], text: resources.averageText)
            legendItem(dash: [1, 3], text: resources.boldestText)
        }
        .frame(maxWidth: .infinity)
    }

    private func legendItem(dash: [CGFloat], text: String) -> some View {
        HStack(spacing: 8) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 1))
                path.addLine(to: CGPoint(x: 22, y: 1))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: dash))
            .frame(width: 22, height: 2)
            Text(text.uppercased()).font(UVVAFont.sans(9)).tracking(1.6).opacity(0.75)
        }
    }

    private var readingByReading: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel(text: resources.readingByReadingText)
                Spacer()
                TextAction(model.isReadingsExpanded ? resources.collapseText : resources.expandText, opacity: 0.8) {
                    withAnimation(.easeOut(duration: 0.25)) { viewModel.toggleReadings() }
                }
            }
            if model.isReadingsExpanded {
                VStack(spacing: 0) {
                    ForEach(model.readings) { row in
                        AxisSpreadRow(row: row)
                        if row.id != model.readings.last?.id { FriendsRule() }
                    }
                }
                .padding(.top, 6)
                .transition(.opacity)
            }
        }
    }
}

#if DEBUG
#Preview {
    GroupTableView(viewModel: MockGroupTableViewModel())
}
#endif
