import Foundation

/// A wine a friend sent (FRI-R11c), in "Sent to you": "Marina sent you a wine" over the wine's name, and `›`.
struct ReceivedWineRowUIModel: Identifiable, Equatable {
    var id: String
    var title: String
    var wineName: String
}
