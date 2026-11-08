import Core
import DesignSystem
import SwiftUI

/// Map (YOU-R09 to R13).
struct MapTabView<ViewModel: MapViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @State private var sharing = false

    var body: some View {
        if let model = viewModel.uiModel.content {
            YouPanel {
                VStack(alignment: .leading, spacing: 0) {
                    PalateMapChart(values: model.map.chartValues, labels: PalateAxis.allCases.map(\.label),
                                   strong: Set(model.highlighted.compactMap { PalateAxis.allCases.firstIndex(of: $0) }))
                        .scaleEffect(0.84)
                        // The scaled size, so the chart's own 330 pt never widens the page.
                        .frame(width: PalateMapChart.size.width * 0.84, height: PalateMapChart.size.height * 0.84)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)

                    SectionTitle(text: viewModel.uiModel.yourReadingsText).padding(.top, 48)
                    VStack(spacing: 0) {
                        ForEach(model.readings) { row in
                            ReadingLine(row: row)
                        }
                    }
                    .padding(.top, 10)

                    if !model.snapshots.isEmpty {
                        OverTimeSection(model: model)
                            .padding(.top, 60)
                    }

                    SectionTitle(text: viewModel.uiModel.whereTheMapPointsText).padding(.top, 60)
                    Text(model.narrative).font(UVVAFont.sans(14)).lineSpacing(9).opacity(0.86)
                        .padding(.top, 14)

                    ActionButton(viewModel.uiModel.shareMyMapText) { sharing = true }
                        .padding(.top, 40)
                    ActionButton(viewModel.uiModel.redoTheMapText, style: .outline, action: viewModel.redoMap)
                        .padding(.top, 10)
                }
            }
            .fullScreenCover(isPresented: $sharing) {
                ShareScreen(title: viewModel.uiModel.shareMyMapText, message: viewModel.uiModel.shareMessage) { format in
                    PalateShareCard(heading: viewModel.uiModel.thisIsMyWinePalateText,
                                    phrase: viewModel.uiModel.name,
                                    chartValues: model.map.chartValues, chartLabels: PalateAxis.allCases.map(\.label),
                                    strong: Set(model.highlighted.compactMap { PalateAxis.allCases.firstIndex(of: $0) }),
                                    lines: [ShareCardLine(tag: viewModel.uiModel.palateText,
                                                          text: model.dominantPhrase)],
                                    format: format)
                } onFinish: {
                    sharing = false
                }
            }
        }
    }
}
