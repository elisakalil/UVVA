import DesignSystem
import SwiftUI

/// Back, the small wordmark and the step counter ("01 / 02", ONB-R00).
struct SignUpHeader: View {
    var uiModel = OnboardingChromeUIModel()
    var counter: String
    var onBack: () -> Void

    var body: some View {
        HStack {
            BackChevron(uiModel: uiModel, action: onBack)
            Spacer()
            HStack(spacing: 9) {
                Text(uiModel.brand).font(UVVAFont.whiteGrape(15)).tracking(1.5).opacity(0.55)
                Rectangle().opacity(0.22).frame(width: 0.5, height: 11)
                Text(counter).font(UVVAFont.sans(9)).tracking(2.7).opacity(0.45)
            }
        }
    }
}
