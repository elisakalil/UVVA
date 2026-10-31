import CloudKit
import Core
import Foundation

/// `CloudAccountStatus` from CloudKit.
public struct ICloudAccountStatus: CloudAccountStatus {
    private let containerIdentifier: String

    public init(containerIdentifier: String = PersonalStore.cloudKitContainer) {
        self.containerIdentifier = containerIdentifier
    }

    public func isAvailable() async -> Bool {
        (try? await CKContainer(identifier: containerIdentifier).accountStatus()) == .available
    }
}
