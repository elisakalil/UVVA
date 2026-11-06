import Foundation

struct HomeLoadResultModel: Sendable {
    let model: HomeContentModel
    let inviteLink: URL?
    let cellarWineKeys: Set<String>
}
