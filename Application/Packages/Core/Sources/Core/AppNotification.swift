import Foundation

public struct AppNotification: Identifiable, Equatable, Sendable {
    public var id: String
    public var text: String
    public var isRead: Bool

    public init(id: String, text: String, isRead: Bool) {
        self.id = id
        self.text = text
        self.isRead = isRead
    }
}
