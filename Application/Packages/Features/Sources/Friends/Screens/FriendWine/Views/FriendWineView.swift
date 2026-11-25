import CoreUI
import DesignSystem
import SwiftUI

/// Friend Wine (FRI-R11a, R12a, R11c): a wine of a friend's Map, one scanned on Compatibility, or one a friend sent,
/// on parchment like every wine sheet. The body is the app's wine sheet body (CoreUI), with the match read against
/// the friend's map, the two maps together, or the user's own; at the foot, "Find the wine" and either "Send to
/// [name]" or, for a wine received, "Add to cellar", as the app's sheet buttons (DesignSystem). A wine for the user and
/// the friend(s) can be kept too: "Add to cellar" takes the place of "Find the wine", which shrinks to a magnifying
/// glass beside it.
/// A sheet over the friend; full screen, with `‹`, when a friend's wine is opened from the tab or its push.
struct FriendWineView: View {
    var model: FriendWineUIModel
    var onPrimary: () -> Void
    /// "Add to cellar" beside the magnifying glass, for a wine read for the user and the friend(s).
    var onAddToCellar: () -> Void = {}
    /// Full screen: the `‹` that closes it.
    var onClose: (() -> Void)?

    @State private var search: URL?

    private let ink = UVVAColor.mossDeep

    var body: some View {
        VStack(spacing: 0) {
            if let onClose { closeBar(onClose) }
            ScrollView {
                WineSheetBody(content: model.content, strings: model.strings, onFindWine: nil,
                              headerAccessory: { people }, afterHeader: { EmptyView() })
                    .padding(.horizontal, 26)
                    .padding(.top, onClose == nil ? 42 : 12)
                    .padding(.bottom, 44)
            }
            .scrollIndicators(.hidden)
            footer
        }
        .background(UVVAColor.parchment.ignoresSafeArea())
        .presentationDetents([.fraction(0.86), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(UVVAColor.parchment)
        .sheet(item: $search) { url in SafariSheet(url: url).ignoresSafeArea() }
    }

    /// `‹` and "MARINA SENT YOU THIS WINE".
    private func closeBar(_ onClose: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Button(action: onClose) {
                Text(verbatim: "‹")
                    .font(UVVAFont.sans(26, .ultraLight))
                    .frame(width: 24, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.resources.backText)
            if let note = model.note {
                Text(note.uppercased())
                    .font(UVVAFont.sans(9, .medium))
                    .tracking(2.2)
                    .opacity(0.62)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    /// A scanned wine (FRI-R12a): each one's match under the producer, "You 68%" beside "Marina 81%"; at a group
    /// table, everyone, onto a second line when they do not fit.
    @ViewBuilder private var people: some View {
        if !model.people.isEmpty {
            FlowLayout(spacing: 28, lineSpacing: 14) {
                ForEach(model.people) { person in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(person.name.uppercased())
                            .font(UVVAFont.sans(9, .medium))
                            .tracking(2)
                            .opacity(0.6)
                        Text(person.percentage)
                            .font(UVVAFont.sans(28, .ultraLight))
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .foregroundStyle(ink)
            .padding(.top, 14)
        }
    }

    /// "Find the wine" (or "Add to cellar" and its magnifying glass) over "Send to Marina" or, for a wine received,
    /// "Add to cellar".
    private var footer: some View {
        VStack(spacing: 12) {
            if case let .send(_, _, failed?) = model.footer {
                Text(failed)
                    .font(UVVAFont.sans(11.5))
                    .opacity(0.7)
                    .transition(.opacity)
            }
            if let cellar = model.cellar {
                cellarRow(cellar)
            } else if let url = model.content.findURL {
                WineSheetButton(title: model.resources.findWineText, style: .outlined) { search = url }
            }
            WineTastingActions(question: nil, primaryTitle: primaryTitle, isPrimaryEnabled: isPrimaryEnabled,
                               onPrimary: onPrimary)
        }
        .animation(.easeOut(duration: 0.2), value: model.footer)
        .animation(.easeOut(duration: 0.2), value: model.cellar)
        .padding(.horizontal, 26)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(alignment: .top) {
            // The wine fades out under the buttons instead of being cut by them.
            LinearGradient(colors: [UVVAColor.parchment.opacity(0), UVVAColor.parchment], startPoint: .top, endPoint: .bottom)
                .frame(height: 36)
                .offset(y: -36)
                .allowsHitTesting(false)
        }
        .background(UVVAColor.parchment)
        .foregroundStyle(ink)
    }

    /// "Add to cellar" ("In your cellar" once there) and, on its right, the magnifying glass of "Find the wine".
    private func cellarRow(_ cellar: FriendWineUIModel.Cellar) -> some View {
        let isInCellar = cellar == .inCellar
        return HStack(spacing: 10) {
            WineSheetButton(title: isInCellar ? model.resources.inCellarText : model.resources.addToCellarText,
                            style: .outlined, action: onAddToCellar)
                .disabled(isInCellar)
                .opacity(isInCellar ? 0.55 : 1)
            if let url = model.content.findURL {
                Button { search = url } label: {
                    Image(systemName: model.resources.findIcon)
                        .font(.system(size: 15, weight: .regular))
                        .frame(width: 45, height: 45)
                        .overlay { Circle().strokeBorder(ink.opacity(0.5), lineWidth: 0.5) }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.resources.findWineText)
            }
        }
    }

    private var primaryTitle: String {
        switch model.footer {
        case let .send(title, _, _): title
        case let .addToCellar(isInCellar):
            isInCellar ? model.resources.inCellarText : model.resources.addToCellarText
        }
    }

    private var isPrimaryEnabled: Bool {
        switch model.footer {
        case let .send(_, isEnabled, _): isEnabled
        case let .addToCellar(isInCellar): !isInCellar
        }
    }
}
