import Core
import DesignSystem
import SwiftUI

/// The invite (D2): the user's palate card with the link, as Story, WhatsApp or Save image (SHARED-R20).
struct FriendsInviteView: View {
    var invite: FriendsInviteUIModel
    var onFinish: () -> Void

    var body: some View {
        ShareScreen(title: invite.title, message: invite.message, showsMessage: true, dismissAfterAction: false) { format in
            PalateShareCard(heading: invite.heading, phrase: invite.name,
                            chartValues: invite.chartValues, chartLabels: PalateAxis.allCases.map(\.label),
                            strong: invite.strongAxes, lines: [ShareCardLine(tag: invite.heading, text: invite.phrase)],
                            format: format)
        } onFinish: {
            onFinish()
        }
    }
}
