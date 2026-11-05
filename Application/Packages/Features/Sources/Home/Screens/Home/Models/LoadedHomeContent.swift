import Foundation

struct LoadedHomeContent: Sendable {
    let state: HomeState
    let inviteLink: URL?
    let cellarWineKeys: Set<String>
}
