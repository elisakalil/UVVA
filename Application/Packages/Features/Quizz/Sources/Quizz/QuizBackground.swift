import DesignSystem
import SwiftUI

/// The softened vineyard behind the Quiz screens.
struct QuizBackground: View {
    /// Readings show the photo whole under a green shade; the Intro and the share sheet fade it to half.
    var photoOpacity: Double = 0.5
    var shade: [Double] = [0.16, 0.16]

    var body: some View {
        ZStack {
            PageBackground(photoOpacity: photoOpacity, blur: 7)
            LinearGradient(colors: shade.map { Color(hex: 0x181E12).opacity($0) }, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }
}
