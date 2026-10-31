import Foundation

/// The countries the phone picker offers (ONB-R04, D8). Lengths follow each country's numbering plan.
public enum PhoneCountries {
    public static let all: [PhoneCountry] = [
        PhoneCountry(region: "PT", callingCode: "351", nationalLength: 9...9),
        PhoneCountry(region: "BR", callingCode: "55", nationalLength: 10...11, trunkPrefix: "0"),
        PhoneCountry(region: "ES", callingCode: "34", nationalLength: 9...9),
        PhoneCountry(region: "FR", callingCode: "33", nationalLength: 9...9, trunkPrefix: "0"),
        PhoneCountry(region: "IT", callingCode: "39", nationalLength: 6...11),
        PhoneCountry(region: "GB", callingCode: "44", nationalLength: 9...10, trunkPrefix: "0"),
        PhoneCountry(region: "IE", callingCode: "353", nationalLength: 7...9, trunkPrefix: "0"),
        PhoneCountry(region: "DE", callingCode: "49", nationalLength: 6...13, trunkPrefix: "0"),
        PhoneCountry(region: "AT", callingCode: "43", nationalLength: 4...13, trunkPrefix: "0"),
        PhoneCountry(region: "CH", callingCode: "41", nationalLength: 9...9, trunkPrefix: "0"),
        PhoneCountry(region: "NL", callingCode: "31", nationalLength: 9...9, trunkPrefix: "0"),
        PhoneCountry(region: "BE", callingCode: "32", nationalLength: 8...9, trunkPrefix: "0"),
        PhoneCountry(region: "LU", callingCode: "352", nationalLength: 4...11),
        PhoneCountry(region: "DK", callingCode: "45", nationalLength: 8...8),
        PhoneCountry(region: "SE", callingCode: "46", nationalLength: 7...10, trunkPrefix: "0"),
        PhoneCountry(region: "NO", callingCode: "47", nationalLength: 8...8),
        PhoneCountry(region: "FI", callingCode: "358", nationalLength: 5...12, trunkPrefix: "0"),
        PhoneCountry(region: "PL", callingCode: "48", nationalLength: 9...9),
        PhoneCountry(region: "CZ", callingCode: "420", nationalLength: 9...9),
        PhoneCountry(region: "HU", callingCode: "36", nationalLength: 8...9, trunkPrefix: "06"),
        PhoneCountry(region: "RO", callingCode: "40", nationalLength: 9...9, trunkPrefix: "0"),
        PhoneCountry(region: "GR", callingCode: "30", nationalLength: 10...10),
        PhoneCountry(region: "GE", callingCode: "995", nationalLength: 9...9, trunkPrefix: "0"),
        PhoneCountry(region: "IL", callingCode: "972", nationalLength: 8...9, trunkPrefix: "0"),
        PhoneCountry(region: "AE", callingCode: "971", nationalLength: 8...9, trunkPrefix: "0"),
        PhoneCountry(region: "US", callingCode: "1", nationalLength: 10...10, trunkPrefix: "1"),
        PhoneCountry(region: "CA", callingCode: "1", nationalLength: 10...10, trunkPrefix: "1"),
        PhoneCountry(region: "MX", callingCode: "52", nationalLength: 10...10),
        PhoneCountry(region: "AR", callingCode: "54", nationalLength: 10...11, trunkPrefix: "0"),
        PhoneCountry(region: "CL", callingCode: "56", nationalLength: 9...9),
        PhoneCountry(region: "UY", callingCode: "598", nationalLength: 8...8, trunkPrefix: "0"),
        PhoneCountry(region: "CO", callingCode: "57", nationalLength: 10...10),
        PhoneCountry(region: "PE", callingCode: "51", nationalLength: 8...9, trunkPrefix: "0"),
        PhoneCountry(region: "ZA", callingCode: "27", nationalLength: 9...9, trunkPrefix: "0"),
        PhoneCountry(region: "AO", callingCode: "244", nationalLength: 9...9),
        PhoneCountry(region: "MZ", callingCode: "258", nationalLength: 8...9),
        PhoneCountry(region: "CV", callingCode: "238", nationalLength: 7...7),
        PhoneCountry(region: "AU", callingCode: "61", nationalLength: 9...9, trunkPrefix: "0"),
        PhoneCountry(region: "NZ", callingCode: "64", nationalLength: 8...10, trunkPrefix: "0"),
        PhoneCountry(region: "JP", callingCode: "81", nationalLength: 9...10, trunkPrefix: "0"),
        PhoneCountry(region: "CN", callingCode: "86", nationalLength: 10...11, trunkPrefix: "0"),
        PhoneCountry(region: "IN", callingCode: "91", nationalLength: 10...10, trunkPrefix: "0")
    ]

    public static func country(region: String?) -> PhoneCountry? {
        guard let region else { return nil }
        return all.first { $0.region == region.uppercased() }
    }

    /// The device's region when it is in the list; Portugal otherwise.
    public static func defaultCountry(for locale: Locale = .current) -> PhoneCountry {
        country(region: locale.region?.identifier) ?? all[0]
    }

    /// The country of an international number, by its longest matching calling code.
    /// "+1" numbers go to the United States.
    static func country(forInternationalDigits digits: String) -> PhoneCountry? {
        all.filter { digits.hasPrefix($0.callingCode) }.max { $0.callingCode.count < $1.callingCode.count }
    }
}
