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

                SectionTitle(text: model.suggestionEyebrow)
                    .padding(.top, 56)

                if let cta = model.cta {
                    Button(action: viewModel.startCourse) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(model.suggestionTitle.isEmpty ? cta : model.suggestionTitle)
                                    .font(UVVAFont.sans(14))
                                Text(model.suggestionStatusMessage ?? model.suggestionNote)
                                    .font(UVVAFont.sans(12.5)).opacity(0.84)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .medium))
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 6)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                } else if let message = model.suggestionStatusMessage {
                    Text(message)
                        .font(UVVAFont.sans(12.5)).opacity(0.84)
                        .padding(.top, 16)
                }
            }
        }
    }
}
