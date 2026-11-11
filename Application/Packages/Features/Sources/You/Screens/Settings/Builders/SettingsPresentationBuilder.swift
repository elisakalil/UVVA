import Core
import Foundation

struct SettingsPresentationBuilder {
    func build(from content: YouContentModel) -> SettingsUIModel {
        let profile = content.profile
        let reminder = content.reminder
        let certificates = content.certificates
        let isPublic = profile?.mapIsPublic ?? true
        return SettingsUIModel(
            name: profile?.firstName ?? "",
            signedInWith: profile?.authProvider == .google ? "Google" : "Apple",
            phone: profile?.phone.map(Self.displayPhone) ?? String(localized: "Add", bundle: .module),
            photo: profile?.photo,
            reminder: reminder?.time ?? String(localized: "Set a time", bundle: .module),
            mapVisibility: isPublic ? String(localized: "Public", bundle: .module) : String(localized: "Friends", bundle: .module),
            tables: "0",
            certificates: "\(certificates.count)",
            canOpenCertificates: !certificates.isEmpty,
            mapIsPublic: isPublic,
            mapPublicNote: isPublic
                ? String(localized: "Anyone with your link can see your palate map.", bundle: .module)
                : String(localized: "Only friends you share a table with can see your map.", bundle: .module)
        )
    }

    /// "+351 912 345 678"
    static func displayPhone(_ e164: String) -> String {
        let digits = String(e164.dropFirst())
        guard let country = PhoneCountries.all.filter({ digits.hasPrefix($0.callingCode) })
            .max(by: { $0.callingCode.count < $1.callingCode.count }) else { return e164 }
        return "+\(country.callingCode) " + PhoneNumber.grouped(String(digits.dropFirst(country.callingCode.count)))
    }

}
