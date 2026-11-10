import DesignSystem
import SwiftUI

/// The light cream card that rises at the foot of the screen when the account could not be deleted (YOU-R27).
/// The view model clears it after a few seconds; a tap clears it sooner.
struct DeleteFailureCard<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        let model = viewModel.uiModel
        ZStack {
            if model.deleteFailed {
                Button(action: viewModel.dismissDeleteFailure) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.yourAccountCouldNotBeText).font(UVVAFont.sans(13.5, .semibold))
                        Text(model.nothingWasRemovedText).font(UVVAFont.sans(12.5)).lineSpacing(4).opacity(0.78)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(UVVAColor.mossDeep)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 17)
                    .background(UVVAColor.creamFill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .shadow(color: Color(red: 12 / 255, green: 16 / 255, blue: 9 / 255).opacity(0.4), radius: 17, y: 14)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: model.deleteFailed)
        .onChange(of: model.deleteFailed) { _, failed in
            guard failed else { return }
            AccessibilityNotification.Announcement("\(model.yourAccountCouldNotBeText). \(model.nothingWasRemovedText)").post()
        }
    }
}
