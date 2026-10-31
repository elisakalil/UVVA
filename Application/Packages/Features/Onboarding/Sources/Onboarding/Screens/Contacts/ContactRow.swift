import DesignSystem
import SwiftUI

/// A contact: initials, name, the palate line for people on UVVA, and Add / Requested / Invite / Invited.
struct ContactRow: View {
    var row: ContactRowUIModel
    var action: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            Text(row.initials)
                .font(UVVAFont.sans(11, .regular)).tracking(0.9).opacity(0.8)
                .frame(width: 38, height: 38)
                .background(Circle().fill(UVVAColor.creamFill.opacity(0.12)))
            VStack(alignment: .leading, spacing: 5) {
                Text(row.name).font(UVVAFont.sans(13)).lineLimit(1)
                if let note = row.note {
                    Text(note).font(UVVAFont.sans(10.5)).tracking(0.4).opacity(0.62)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ContactButton(state: row.state, action: action)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { Rectangle().opacity(0.14).frame(height: 0.5) }
    }
}
