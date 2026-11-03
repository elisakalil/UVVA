import DesignSystem
import SwiftUI

/// A course in a list. Tapped, it opens on its description, its lessons and its button (LEARN-R07, R09, R11).
struct CourseRow: View {
    var model: CourseRowUIModel
    var onToggle: () -> Void
    var onStart: () -> Void
    var onCertificate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    StateDot(state: model.state)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.title).font(UVVAFont.sans(15))
                        Text(model.meta.uppercased())
                            .font(UVVAFont.sans(9.5))
                            .tracking(1.6)
                            .opacity(0.6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(verbatim: "›")
                        .font(UVVAFont.sans(18, .ultraLight))
                        .opacity(0.55)
                        .rotationEffect(.degrees(model.isOpen ? 90 : 0))
                }
                .padding(.vertical, 18)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(model.isOpen ? "Closes the course" : "Opens the course", bundle: .module))

            if model.isOpen {
                VStack(alignment: .leading, spacing: 0) {
                    Text(model.about)
                        .font(UVVAFont.sans(13.5))
                        .lineSpacing(5)
                        .opacity(0.82)
                    if !model.grapes.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(model.grapes, id: \.self) { grape in
                                Text(grape)
                                    .font(UVVAFont.sans(11))
                                    .opacity(0.8)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.3), lineWidth: 0.5))
                            }
                        }
                        .padding(.top, 14)
                    }
                    HStack(spacing: 22) {
                        link("\(model.cta)  ›", action: onStart)
                        if model.hasCertificate {
                            link(String(localized: "View certificate", bundle: .module), action: onCertificate)
                        }
                    }
                    .padding(.top, 22)
                }
                .padding(.leading, 19)
                .padding(.trailing, 6)
                .padding(.bottom, 26)
                // It stays where it is and the row grows over it, so it unfolds downwards from under the title
                // instead of sliding over it.
                .transition(.opacity)
            }
        }
        .clipped()
    }

    private func link(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.sans(9.5, .regular))
                .tracking(2.6)
                .padding(.bottom, 9)
                .overlay(alignment: .bottom) { Rectangle().fill(UVVAColor.creamFill.opacity(0.5)).frame(height: 0.5) }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
