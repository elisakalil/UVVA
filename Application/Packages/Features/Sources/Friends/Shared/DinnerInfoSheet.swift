import DesignSystem
import SwiftUI

/// What "Set the perfect dinner" does, from the info button beside its title. Made like the guided tour's card: cream
/// paper and moss ink, a small eyebrow over the title, then each part as a step and a full-width capsule to close.
/// Every word is in Red Grapes. The sheet is as tall as its words, and scrolls once they are taller than the screen.
struct DinnerInfoSheet: View {
    var resources: DinnerResourcesUIModel
    var onClose: () -> Void

    /// The height of the words, for the sheet to fit them.
    @State private var contentHeight: CGFloat = 0

    private var info: DinnerInfoResources { resources.info }
    private var ink: Color { UVVAColor.mossDeep }

    private var steps: [(title: String, text: String)] {
        [(resources.coursesText, info.courses),
         (resources.onTheTableText, info.onTheTable),
         (resources.whenText, info.when),
         (info.bottlesTitle, info.bottles),
         (resources.setTableButtonText, info.setTable)]
    }

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 26)
                .padding(.top, 34)
                .padding(.bottom, 24)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .foregroundStyle(ink)
        .presentationBackground(UVVAColor.creamFill)
        .presentationDetents([.height(max(320, contentHeight))])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(info.eyebrow.uppercased())
                .font(UVVAFont.redGrapes(13))
                .tracking(1.2)
                .opacity(0.55)
            Text(info.title.uppercased())
                .font(UVVAFont.redGrapes(30))
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 12)
            Text(info.intro.uppercased())
                .font(UVVAFont.redGrapes(16))
                .lineSpacing(5)
                .opacity(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            VStack(alignment: .leading, spacing: 22) {
                ForEach(steps.indices, id: \.self) { step($0) }
            }
            .padding(.top, 28)
            Button(action: onClose) {
                Text(info.closeText.uppercased())
                    .font(UVVAFont.redGrapes(17))
                    .tracking(1.6)
                    .foregroundStyle(UVVAColor.creamFill)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Capsule().fill(ink))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A part of the dinner, as a step of the tour: its number and name, then what it does.
    private func step(_ index: Int) -> some View {
        let step = steps[index]
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(verbatim: "\(index + 1)")
                    .font(UVVAFont.redGrapes(13))
                    .opacity(0.5)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().strokeBorder(ink.opacity(0.25), lineWidth: 0.75))
                Text(step.title.uppercased())
                    .font(UVVAFont.redGrapes(19))
            }
            Text(step.text.uppercased())
                .font(UVVAFont.redGrapes(15))
                .lineSpacing(5)
                .opacity(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 28)
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        DinnerInfoSheet(resources: DinnerResourcesUIModel(), onClose: {})
    }
}
#endif
