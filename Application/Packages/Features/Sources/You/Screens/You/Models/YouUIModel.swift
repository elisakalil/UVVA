import Core
import Foundation
import DesignSystem
import SwiftUI

public struct YouUIModel {
    var tab: YouTab = .progress
    var header = YouHeaderUIModel(name: "", signature: "", photo: nil)
    var backgroundPhoto: Image { UVVAPhoto.hills }
}
