import DesignSystem
import SwiftUI

/// Share for a table (FRI-R21): the three ways of every share of the app (SHARED-R20); Save image keeps the
/// shopping guide.
struct TableShareView: View {
    var model: TableShareUIModel
    var onFinish: () -> Void

    var body: some View {
        ShareScreen(title: model.title, message: model.message,
                    savedCard: { [model] in AnyView(TableShareCard(model: model, style: .guide)) }) { format in
            TableShareCard(model: model, style: format == .story ? .story : .whatsApp)
        } onFinish: {
            onFinish()
        }
    }
}

#if DEBUG
#Preview {
    TableShareView(model: TableShareUIModel(
        title: "Share this table", namesText: "Marina & Elisa",
        message: "You're invited to dinner", link: URL(string: "https://uvva.app/t/marina-elisa")!,
        courses: [
            TableShareCourseUIModel(courseText: "Starter", wineText: "Alvarinho, Soalheiro",
                                    askForText: "Ask for: Soalheiro Alvarinho 2022", dishText: "Grilled sardines"),
            TableShareCourseUIModel(courseText: "Main", wineText: "Chianti Classico, Isole e Olena",
                                    askForText: "Ask for: Isole e Olena Chianti Classico 2019", dishText: "Mushroom risotto"),
            TableShareCourseUIModel(courseText: "Dessert", wineText: "10 Year Tawny, Graham's",
                                    askForText: "Ask for: Graham's 10 Year Tawny", dishText: "Pastel de nata")
        ],
        invitedText: "You're invited to dinner", tonightText: "Tonight's table", guideText: "What to buy",
        footerText: "Open the menu on UVVA · uvva.app")) {}
}
#endif
