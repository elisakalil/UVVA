import SwiftUI

/// The picture of a certificate (LEARN-R23, R24): the wordmark and date, who now knows what, the three things
/// they can do now and the course XP, on the wine-dark ground of the lessons.
public struct CertificateCard: View {
    var model: CertificateUIModel
    var format: ShareFormat
    var cornerRadius: CGFloat

    static let ground = Color(hex: 0x3A1F2C)

    public init(model: CertificateUIModel, format: ShareFormat, cornerRadius: CGFloat = 14) {
        self.model = model
        self.format = format
        self.cornerRadius = cornerRadius
    }

    private var isStory: Bool { format == .story }

    public var body: some View {
        let size = format.cardSize
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("UVVA").font(UVVAFont.whiteGrape(14)).tracking(2)
                Spacer()
                Text(model.date.uppercased())
                    .font(UVVAFont.sans(7))
                    .tracking(1.8)
                    .opacity(0.7)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(model.lead.uppercased())
                    .font(UVVAFont.sans(8))
                    .tracking(2.4)
                    .opacity(0.8)
                Text(model.title)
                    .font(UVVAFont.redGrapes(isStory ? 32 : 28))
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text(model.about)
                    .font(UVVAFont.sans(11))
                    .lineSpacing(3)
                    .opacity(0.9)
                    .lineLimit(isStory ? 4 : 2)
            }
            .padding(.top, isStory ? 56 : 24)

            if let country = model.country, let courseID = model.courseID {
                RegionMapPreview(country: country, courseID: courseID)
                    .frame(width: 82, height: isStory ? 94 : 56)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }

            Spacer(minLength: 12)

            Text(String(localized: "What I can do now", bundle: .module).uppercased())
                .font(UVVAFont.sans(7))
                .tracking(2.1)
                .opacity(0.65)
                .padding(.bottom, 8)
            ForEach(Array(model.skills.prefix(3).enumerated()), id: \.offset) { index, skill in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(String(format: "%02d", index + 1))
                        .font(UVVAFont.whiteGrape(14))
                        .opacity(0.7)
                        .frame(width: 18, alignment: .leading)
                    Text(skill)
                        .font(UVVAFont.sans(10.5))
                        .lineLimit(2)
                        .opacity(0.94)
                }
                .padding(.vertical, isStory ? 8 : 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    if index > 0 { Rectangle().fill(UVVAColor.creamFill.opacity(0.22)).frame(height: 0.5) }
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text(model.xp).font(UVVAFont.whiteGrape(12)).tracking(0.7)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(localized: "Learn with ·", bundle: .module).uppercased()).font(UVVAFont.sans(8))
                    Text("UVVA").font(UVVAFont.whiteGrape(10))
                    Text(verbatim: "APP").font(UVVAFont.sans(8))
                }
                .tracking(1.9)
                .opacity(0.6)
            }
            .padding(.top, 12)
            .overlay(alignment: .top) { Rectangle().fill(UVVAColor.creamFill.opacity(0.22)).frame(height: 0.5) }
            .padding(.top, 14)
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .padding(.bottom, 20)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .foregroundStyle(UVVAColor.creamFill)
        .background(CertificateBackground())
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
