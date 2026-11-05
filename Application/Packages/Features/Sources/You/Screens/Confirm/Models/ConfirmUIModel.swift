import Foundation

struct ConfirmUIModel {
    let kind: ConfirmKind
    var eyebrow: String {
        kind == .signOut ? String(localized: "Sign out", bundle: .module) : String(localized: "Delete account", bundle: .module)
    }
    var title: String {
        kind == .signOut ? String(localized: "Sign out of UVVA?", bundle: .module)
                         : String(localized: "Delete your account?", bundle: .module)
    }
    var message: String {
        kind == .signOut
            ? String(localized: "Your palate map, cellar and certificates stay saved to your account.", bundle: .module)
            : String(localized: "This permanently removes your palate map, cellar, tables and certificates. It cannot be undone.", bundle: .module)
    }
    var confirm: String {
        kind == .signOut ? String(localized: "Sign out", bundle: .module) : String(localized: "Delete my account", bundle: .module)
    }
    var cancel: String {
        kind == .signOut ? String(localized: "Cancel", bundle: .module) : String(localized: "Keep my account", bundle: .module)
    }

}
