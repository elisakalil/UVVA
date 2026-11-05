import Foundation

public struct MapScreenUIModel {
    var content: MapUIModel?
    var name = ""
    var shareMessage = ""
    var yourReadingsText = String(localized: "Your readings", bundle: .module)
    var whereTheMapPointsText = String(localized: "Where the map points", bundle: .module)
    var shareMyMapText = String(localized: "Share my map", bundle: .module)
    var redoTheMapText = String(localized: "Redo the map", bundle: .module)
    var thisIsMyWinePalateText = String(localized: "This is my wine palate", bundle: .module)
    var palateText = String(localized: "Palate", bundle: .module)
}
