import Foundation

/// How a person signs in (ONB-R29): Sign in with Apple now, Google later.
public enum AuthProvider: String, Codable, Sendable {
    case apple, google
}
