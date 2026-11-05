import Foundation

struct ContactButtonUIModel {
    let state: ContactRowState
    var title: String {
        switch state {
        case .add: String(localized: "Add", bundle: .module)
        case .requested: String(localized: "Requested", bundle: .module)
        case .invite: String(localized: "Invite", bundle: .module)
        case .invited: String(localized: "Invited", bundle: .module)
        }
    }

    var isDone: Bool { state == .requested || state == .invited }

}
