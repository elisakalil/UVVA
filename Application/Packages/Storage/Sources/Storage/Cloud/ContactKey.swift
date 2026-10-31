import CryptoKit
import Foundation

/// The key that lets friends find a phone without the phone being published (ARCHITECTURE §3.2):
/// SHA-256 of the E.164 number and a salt, in hex.
public enum ContactKey {
    static let salt = "uvva.contact-key.v1"

    public static func make(phone: String) -> String {
        SHA256.hash(data: Data((phone + salt).utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
