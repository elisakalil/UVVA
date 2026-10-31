import Foundation

/// Sign out (YOU-R26) or delete the account (YOU-R27).
enum ConfirmKind: String, Identifiable {
    case signOut, delete
    var id: String { rawValue }
}
