import SwiftUI

/// The magazine grid: three covers to a row, ruled like a contact sheet (CELLAR-R06).
struct CellarGrid: View {
    var items: [CellarItemUIModel]
    var onOpen: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(items) { item in
                Button { onOpen(item.id) } label: { CellarCover(model: item) }
                    .buttonStyle(.plain)
            }
        }
        // The last column's rule falls just outside the screen, as in the artboard.
        .padding(.trailing, -1)
        .overlay(alignment: .top) { CellarPalette.rule.frame(height: 1) }
    }
}
