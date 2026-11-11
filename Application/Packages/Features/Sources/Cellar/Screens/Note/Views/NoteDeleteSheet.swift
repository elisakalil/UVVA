import CoreUI
import SwiftUI

/// "Delete this note?" on the paper: Delete, or Cancel to keep it (CELLAR-R28).
struct NoteDeleteSheet: View {
    var resources: NoteResourcesUIModel
    var isWorking: Bool
    var onDelete: () -> Void
    var onCancel: () -> Void

    var body: some View {
        CellarPaperSheet(title: resources.deleteTitleText, message: resources.deleteBodyText,
                         primary: resources.deleteText, secondary: resources.cancelText, isWorking: isWorking,
                         onPrimary: onDelete, onSecondary: onCancel)
    }
}
