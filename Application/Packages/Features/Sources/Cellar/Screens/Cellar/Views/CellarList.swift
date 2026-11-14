import SwiftUI

/// The list view: one row per wine, under a rule (CELLAR-R06).
struct CellarList: View {
    var items: [CellarItemUIModel]
    var photos: [String: UIImage]
    var onApproachEnd: () -> Void
    var onOpen: (String) -> Void

    var body: some View {
        let prefetchID = items.dropLast(4).last?.id
        LazyVStack(spacing: 0) {
            ForEach(items) { item in
                Button { onOpen(item.id) } label: { CellarRow(model: item, photo: photos[item.id]).contentShape(Rectangle()) }
                    .buttonStyle(.plain)
                    .onAppear {
                        if item.id == prefetchID { onApproachEnd() }
                    }
            }
        }
        .scrollTargetLayout()
        .overlay(alignment: .top) { CellarPalette.rule.frame(height: 1) }
    }
}
