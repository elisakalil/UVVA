import DesignSystem
import SwiftUI

/// The cream card of the tour: the intro with "Show me", or a step with its dots, `‹`, Next / Start (HOME-R32).
struct TourCard<ViewModel: GuidedTourViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    static var estimatedHeight: CGFloat { 150 }

    private var ink: Color { UVVAColor.mossDeep }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let step = viewModel.uiModel.current {
                HStack(spacing: 12) {
                    HStack(spacing: 5) {
                        ForEach(1...viewModel.uiModel.stepCount, id: \.self) { index in
                            Capsule()
                                .fill(ink.opacity(index == viewModel.uiModel.step ? 0.85 : index < viewModel.uiModel.step ? 0.5 : 0.2))
                                .frame(width: index == viewModel.uiModel.step ? 16 : 4, height: 4)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                                .onTapGesture { viewModel.pick(index) }
                        }
                    }
                    Spacer(minLength: 0)
                    Text(viewModel.uiModel.counter.uppercased())
                        .font(UVVAFont.sans(8.5)).tracking(1.7).opacity(0.5)
                    Button(action: viewModel.back) {
                        Image(systemName: viewModel.uiModel.backIcon).font(.system(size: 11, weight: .regular))
                            .frame(width: 34, height: 34)
                            .overlay(Circle().strokeBorder(ink.opacity(0.2), lineWidth: 1))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(viewModel.uiModel.backTitle))
                    Button(action: viewModel.next) {
                        Text(viewModel.uiModel.nextTitle.uppercased())
                            .font(UVVAFont.sans(9.5, .semibold)).tracking(2.5)
                            .foregroundStyle(UVVAColor.creamFill)
                            .padding(.horizontal, 16)
                            .frame(height: 34)
                            .background(Capsule().fill(ink))
                    }
                    .buttonStyle(.plain)
                }
                Text(step.title)
                    .font(UVVAFont.sans(17)).tracking(-0.17)
                    .padding(.top, 12)
                Text(step.body)
                    .font(UVVAFont.sans(12)).lineSpacing(5).opacity(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            } else {
                HStack {
                    Text(viewModel.uiModel.quickLook.uppercased())
                        .font(UVVAFont.sans(9)).tracking(2.7).lineSpacing(5).opacity(0.6)
                    Spacer()
                    HStack(spacing: 5) {
                        Capsule().fill(ink.opacity(0.85)).frame(width: 16, height: 4)
                        ForEach(0..<viewModel.uiModel.stepCount, id: \.self) { _ in
                            Capsule().fill(ink.opacity(0.2)).frame(width: 4, height: 4)
                        }
                    }
                }
                Button(action: viewModel.next) {
                    Text(viewModel.uiModel.showTitle.uppercased())
                        .font(UVVAFont.sans(9.5, .semibold)).tracking(3.2)
                        .foregroundStyle(UVVAColor.creamFill)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule().fill(ink))
                }
                .buttonStyle(.plain)
                .padding(.top, 40)
            }
        }
        .padding(.leading, viewModel.uiModel.current == nil ? 20 : 18)
        .padding(.trailing, viewModel.uiModel.current == nil ? 20 : 14)
        .padding(.top, viewModel.uiModel.current == nil ? 22 : 14)
        .padding(.bottom, viewModel.uiModel.current == nil ? 18 : 16)
        .background(RoundedRectangle(cornerRadius: viewModel.uiModel.current == nil ? 24 : 22, style: .continuous)
            .fill(UVVAColor.creamFill)
            .shadow(color: Color(hex: 0x080C06).opacity(0.3), radius: 21, y: 18))
        .foregroundStyle(ink)
    }
}
