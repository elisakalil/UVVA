import Foundation

/// A band of search results: Regions, Grapes, The path or Lessons.
struct SearchGroupUIModel: Identifiable, Equatable {
    var id: String
    var title: String
    var results: [SearchResultUIModel]
}
