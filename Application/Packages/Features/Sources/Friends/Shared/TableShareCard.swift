import DesignSystem
import SwiftUI

/// The pictures of a shared table (FRI-R21): "Tonight's table" as a Story, the invite on WhatsApp, and the
/// shopping guide that Save image keeps. Cream paper and ink, like the other share cards.
struct TableShareCard: View {
    enum Style { case story, whatsApp, guide }

    var model: TableShareUIModel
    var style: Style

    private let ink = Color(hex: 0x293022)
    private var size: CGSize { style == .whatsApp ? ShareFormat.whatsApp.cardSize : ShareFormat.story.cardSize }

    private var heading: String {
        switch style {
        case .story: model.tonightText
        case .whatsApp: model.invitedText
        case .guide: model.guideText
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(verbatim: "UVVA").font(UVVAFont.whiteGrape(13)).tracking(3)
            Text(heading.uppercased()).font(UVVAFont.sans(6.5, .medium)).tracking(2).opacity(0.6)
                .padding(.top, 14)
            Text(model.namesText).font(UVVAFont.whiteGrape(style == .whatsApp ? 20 : 24))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .padding(.top, 8)
            Spacer(minLength: 10)
            VStack(spacing: style == .whatsApp ? 10 : 18) {
                ForEach(model.courses) { course in courseView(course) }
            }
            Spacer(minLength: 10)
            Rectangle().fill(ink.opacity(0.2)).frame(height: 0.5)
            Text((style == .guide ? model.footerText : model.link.host().map { "\($0)\(model.link.path())" } ?? "").uppercased())
                .font(UVVAFont.sans(6)).tracking(1.8).opacity(0.55)
                .padding(.top, 10)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, style == .whatsApp ? 18 : 26)
        .frame(width: size.width, height: size.height)
        .foregroundStyle(ink)
        .background(Color(hex: 0xF3EDDF))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func courseView(_ course: TableShareCourseUIModel) -> some View {
        VStack(spacing: 3) {
            Text(course.courseText.uppercased()).font(UVVAFont.sans(6, .semibold)).tracking(1.8).opacity(0.55)
            if style == .guide {
                Text(course.askForText).font(UVVAFont.sans(9.5, .medium))
                Text(course.dishText).font(UVVAFont.sans(8)).opacity(0.7)
            } else {
                Text(course.wineText).font(UVVAFont.sans(style == .whatsApp ? 9 : 10.5))
                if style == .story {
                    Text(course.dishText).font(UVVAFont.sans(8)).italic().opacity(0.7)
                }
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
    }
}
