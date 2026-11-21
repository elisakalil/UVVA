import DesignSystem
import SwiftUI

/// The empty tab's call (FRI-R06): the engraved grapes, "Find out what your friends like to drink" in the brush
/// lettering, and "Invite friends", which opens the contacts list of the Onboarding.
/// With the contacts refused, the button opens the Settings and says why underneath.
struct FriendsCompareCall: View {
    var resources: FriendsResourcesUIModel
    var isDenied: Bool
    var onAdd: () -> Void
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            UVVAIllustration.grape(4)
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 128)
                .accessibilityHidden(true)
            Text(resources.compareTitleText.uppercased())
                .font(UVVAFont.redGrapes(24))
                .tracking(0.5)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 26)
                .padding(.horizontal, 12)
                .accessibilityAddTraits(.isHeader)
            ActionButton(isDenied ? resources.openSettingsText : resources.addFriendsText,
                         action: isDenied ? onOpenSettings : onAdd)
                .padding(.top, 28)
            if isDenied {
                Text(resources.deniedAccessText)
                    .font(UVVAFont.sans(11.5))
                    .lineSpacing(3)
                    .opacity(0.7)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
