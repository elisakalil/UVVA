import Foundation

/// A country of the phone picker: its calling code, how long its national numbers are,
/// and the trunk prefix people write in front of local numbers (the "0" of "0912…").
public struct PhoneCountry: Equatable, Hashable, Identifiable, Sendable {
    /// ISO 3166 region code ("PT").
    public var region: String
    /// Calling code without "+" ("351").
    public var callingCode: String
    /// Digits of a national number, without the trunk prefix.
    public var nationalLength: ClosedRange<Int>
    public var trunkPrefix: String?

    public var id: String { region }

    public init(region: String, callingCode: String, nationalLength: ClosedRange<Int>, trunkPrefix: String? = nil) {
        self.region = region
        self.callingCode = callingCode
        self.nationalLength = nationalLength
        self.trunkPrefix = trunkPrefix
    }

    /// The country's name in the given locale.
    public func name(in locale: Locale = .current) -> String {
        locale.localizedString(forRegionCode: region) ?? region
    }
}
