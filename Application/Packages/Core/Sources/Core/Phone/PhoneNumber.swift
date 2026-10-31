import Foundation

/// Phone numbers in E.164 ("+351912345678"), the form the contact key is made from (ARCHITECTURE §4.4).
public enum PhoneNumber {
    /// The number typed in the Phone step: digits only, the trunk prefix dropped,
    /// valid when its length fits the country (ONB-R05). Nil while it does not.
    public static func e164(national: String, country: PhoneCountry) -> String? {
        var digits = national.filter(\.isASCIIDigit)
        if let trunk = country.trunkPrefix, digits.hasPrefix(trunk),
           country.nationalLength.contains(digits.count - trunk.count) {
            digits.removeFirst(trunk.count)
        }
        guard country.nationalLength.contains(digits.count) else { return nil }
        return "+" + country.callingCode + digits
    }

    /// A number from the address book, written any way people write them ("+351 912…", "00351…", "912 345 678",
    /// "(415) 555-0100"). Numbers without a calling code are read as numbers of `home`.
    public static func e164(contact raw: String, home: PhoneCountry) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        var digits = trimmed.filter(\.isASCIIDigit)
        if trimmed.hasPrefix("+") || digits.hasPrefix("00") {
            if digits.hasPrefix("00") { digits.removeFirst(2) }
            guard let country = PhoneCountries.country(forInternationalDigits: digits) else {
                return (8...15).contains(digits.count) ? "+" + digits : nil
            }
            return e164(national: String(digits.dropFirst(country.callingCode.count)), country: country)
        }
        return e164(national: digits, country: home)
    }

    /// The national number in groups of three, as it is typed ("912 345 678").
    public static func grouped(_ digits: String) -> String {
        var result = ""
        for (index, digit) in digits.enumerated() {
            if index > 0, index % 3 == 0 { result.append(" ") }
            result.append(digit)
        }
        return result
    }
}

extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
