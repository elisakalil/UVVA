import SwiftUI

/// The magazine grid: three covers to a row, ruled like a contact sheet (CELLAR-R06).
struct CellarGrid: View {
    var items: [CellarItemUIModel]
    var photos: [String: UIImage]
    var onApproachEnd: () -> Void
    var onOpen: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)

    var body: some View {
        let prefetchID = items.dropLast(6).last?.id
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(items) { item in
                Button { onOpen(item.id) } label: { CellarCover(model: item, photo: photos[item.id]) }
                    .buttonStyle(.plain)
                    .onAppear {
                        if item.id == prefetchID { onApproachEnd() }
                    }
            }
        }
        // The last column's rule falls just outside the screen, as in the artboard.
        .padding(.trailing, -1)
        .scrollTargetLayout()
        .overlay(alignment: .top) { CellarPalette.rule.frame(height: 1) }
    }
}
