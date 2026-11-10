import Core
import Foundation
import DesignSystem
import SwiftUI

public struct YouUIModel {
    var tab: YouTab = .progress
    /// YOU-R03: the Map tab is to open at "Over time"; cleared once the page is there.
    var focusesMapHistory = false
    /// False until the first read: the header and the panels stay hidden, so blank values never flash before the real ones.
    var isLoaded = false
    var header = YouHeaderUIModel(name: "", signature: "", photo: nil)
    var backgroundPhoto: Image { UVVAPhoto.hills }
}
