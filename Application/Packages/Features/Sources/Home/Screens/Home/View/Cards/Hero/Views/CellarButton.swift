import DesignSystem
import SwiftUI

/// "Add to cellar", or, once the wine is in the Cellar, a disabled "In your cellar" (CELLAR-R13c).
struct CellarButton: View {
    var resources = HomeResourcesUIModel()
    var isInCellar: Bool
    var onSave: () -> Void

    var body: some View {
        if isInCellar {
            PillButton(style: .outline, action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: resources.dailySuggestionCardSavedIcon).font(.system(size: 11, weight: .regular))
                    Text(resources.dailySuggestionCardSavedTitle)
                }
            }
            .disabled(true)
        } else {
            PillButton(action: onSave) { Text(resources.dailySuggestionCardAddTitle) }
        }
    }
}
