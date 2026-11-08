import SwiftUI

/// The list view: one row per wine, under a rule (CELLAR-R06).
struct CellarList: View {
    var items: [CellarItemUIModel]
    var onOpen: (String) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(items) { item in
                Button { onOpen(item.id) } label: { CellarRow(model: item).contentShape(Rectangle()) }
                    .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .top) { CellarPalette.rule.frame(height: 1) }
    }
}
