import DesignSystem
import SwiftUI

/// Progress (YOU-R04 to R07). The level (D5) waits for its rules.
struct ProgressTabView: View {
    var viewModel: YouViewModel

    var body: some View {
        let model = viewModel.progress
        YouPanel {
            VStack(alignment: .leading, spacing: 0) {
                PanelTitle(text: String(localized: "Your progress", bundle: .module))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .leading), count: 3),
                          alignment: .leading, spacing: 34) {
                    ForEach(model.stats) { stat in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(stat.value).font(UVVAFont.sans(28, .ultraLight))
                            Text(stat.label.uppercased()).font(UVVAFont.sans(9)).tracking(2.2).opacity(0.82)
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                    }
                }
                .padding(.top, 28)

                Rectangle().opacity(0.12).frame(height: 1).padding(.vertical, 34)

                Text(String(localized: "Specialist in", bundle: .module).uppercased())
                    .font(UVVAFont.redGrapes(16)).tracking(0.64)
                Text(model.specialist)
                    .font(UVVAFont.sans(15)).lineSpacing(7)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text(model.suggestionEyebrow.uppercased())
                        .font(UVVAFont.redGrapes(16)).tracking(0.64)
                    Text(model.suggestionTitle).font(UVVAFont.sans(14))
                    Text(model.suggestionNote).font(UVVAFont.sans(12.5)).opacity(0.84)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { Rectangle().opacity(0.1).frame(height: 1) }
                .padding(.top, 24)

                ActionButton(model.cta, style: .outline, action: viewModel.startCourse)
                    .padding(.top, 8)
            }
        }
    }
}
