import Foundation

public struct MapScreenUIModel {
    var content: MapUIModel?
    var name = ""
    var shareMessage = ""
    var yourReadingsText = String(localized: "Your readings", bundle: .module)
    var whereTheMapPointsText = String(localized: "Where the map points", bundle: .module)
    /// QUIZ-R04a to R04c: how the map came from the Quiz answers, in the sheet of "Where the map points".
    var howTheMapIsDrawnText = String(localized: "How your map is drawn", bundle: .module)
    var mapDrawnText = String(localized: "Your answers to the Quiz were the starting point. We read them in wine terms and settled them among real wines, so your map points to bottles that exist. What you lean toward stays: love floral, and your map leans to the more floral wines. Every wine you rate moves it from there.", bundle: .module)
    var shareMyMapText = String(localized: "Share my map", bundle: .module)
    var redoTheMapText = String(localized: "Redo the map", bundle: .module)
    var thisIsMyWinePalateText = String(localized: "This is my wine palate", bundle: .module)
    var palateText = String(localized: "Palate", bundle: .module)
}
