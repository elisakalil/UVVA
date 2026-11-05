import Core
import Foundation

enum PhonePresentation {
    static func parts(_ phone: String?) -> (country: PhoneCountry, national: String) {
        guard let phone else { return (PhoneCountries.defaultCountry(), "") }
        let digits = String(phone.dropFirst())
        let country = PhoneCountries.all.filter { digits.hasPrefix($0.callingCode) }
            .max { $0.callingCode.count < $1.callingCode.count } ?? PhoneCountries.defaultCountry()
        return (country, String(digits.dropFirst(country.callingCode.count)))
    }

}
