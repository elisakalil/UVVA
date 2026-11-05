import Core

struct DiscoveredContacts {
    var onUVVA: [(contact: DeviceContact, account: PublicProfile)] = []
    var toInvite: [DeviceContact] = []
}
