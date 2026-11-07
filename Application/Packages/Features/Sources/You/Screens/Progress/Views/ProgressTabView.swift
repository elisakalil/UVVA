import DesignSystem
import SwiftUI

/// Progress (YOU-R04 to R07). The level (D5) waits for its rules.
struct ProgressTabView<ViewModel: ProgressViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    @Binding var selectedStat: ProgressStat?

    var body: some View {
        let model = viewModel.uiModel
        YouPanel {
            VStack(alignment: .leading, spacing: 0) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .leading), count: 3),
                          alignment: .leading, spacing: 34) {
                    ForEach(model.stats) { stat in
                        Button { selectedStat = stat } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(stat.value).font(UVVAFont.sans(28, .ultraLight))
                            Text(stat.label.uppercased()).font(UVVAFont.sans(9)).tracking(2.2).opacity(0.82)
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(stat.items.isEmpty)
                    }
                }
                .padding(.top, 6)

                SectionTitle(text: viewModel.uiModel.specialistInText)
                    .padding(.top, 76)
                Text(model.specialist)
                    .font(UVVAFont.sans(15)).lineSpacing(7)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: model.suggestionEyebrow)
                        if !model.suggestionTitle.isEmpty {
                            Text(model.suggestionTitle).font(UVVAFont.sans(14))
                            Text(model.suggestionNote).font(UVVAFont.sans(12.5)).opacity(0.84)
                        }
                        if let reason = model.suggestionReason {
                            Text(reason).font(UVVAFont.sans(12.5)).opacity(0.84)
                        }
                    }

                    if let cta = model.cta {
                        ActionButton(cta, style: .outline, action: viewModel.startCourse)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(UVVAColor.creamFill, lineWidth: 0.35)
                        .allowsHitTesting(false)
                }
                .padding(.top, 56)
            }
        }
    }
}
