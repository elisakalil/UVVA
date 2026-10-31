import Core
import DesignSystem
import SwiftUI

/// Map (YOU-R09 to R13).
struct MapTabView: View {
    var viewModel: YouViewModel
    @State private var sharing = false

    var body: some View {
        if let model = viewModel.mapModel {
            YouPanel {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        PanelTitle(text: String(localized: "The map", bundle: .module))
                        Spacer()
                        PanelTitle(text: model.readOn, opacity: 0.86)
                    }
                    PalateMapChart(values: model.map.chartValues, labels: PalateAxis.allCases.map(\.label),
                                   strong: Set(model.top3.prefix(2).compactMap { PalateAxis.allCases.firstIndex(of: $0) }))
                        .scaleEffect(0.84)
                        // The scaled size, so the chart's own 330 pt never widens the page.
                        .frame(width: PalateMapChart.size.width * 0.84, height: PalateMapChart.size.height * 0.84)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                    Text(model.caption).font(UVVAFont.sans(13.5)).lineSpacing(6).opacity(0.84)
                        .padding(.top, 10)

                    PanelTitle(text: String(localized: "Your readings", bundle: .module)).padding(.top, 44)
                    VStack(spacing: 0) {
                        ForEach(Array(model.readings.enumerated()), id: \.element.id) { index, row in
                            if index > 0 { Rectangle().opacity(0.09).frame(height: 1) }
                            ReadingLine(row: row)
                        }
                    }
                    .padding(.top, 10)

                    if model.showsOverTime {
                        OverTimeSection(model: model, onSelect: viewModel.selectSnapshot)
                            .padding(.top, 44)
                    }

                    PanelTitle(text: String(localized: "Where the map points", bundle: .module)).padding(.top, 44)
                    Text(model.narrative).font(UVVAFont.sans(14)).lineSpacing(9).opacity(0.86)
                        .padding(.top, 14)

                    ActionButton(String(localized: "Share my map", bundle: .module)) { sharing = true }
                        .padding(.top, 32)
                    ActionButton(String(localized: "Redo the map", bundle: .module), style: .outline, action: viewModel.redoMap)
                        .padding(.top, 10)
                }
            }
            .fullScreenCover(isPresented: $sharing) {
                ShareScreen(title: String(localized: "Share my map", bundle: .module), message: viewModel.shareMessage) { format in
                    PalateShareCard(heading: String(localized: "This is my wine palate", bundle: .module),
                                    phrase: viewModel.header.name,
                                    chartValues: model.map.chartValues, chartLabels: PalateAxis.allCases.map(\.label),
                                    strong: Set(model.top3.prefix(2).compactMap { PalateAxis.allCases.firstIndex(of: $0) }),
                                    lines: [ShareCardLine(tag: String(localized: "Palate", bundle: .module),
                                                          text: model.top3.map(\.label).joined(separator: " · "))],
                                    format: format)
                } onFinish: {
                    sharing = false
                }
            }
        }
    }
}
