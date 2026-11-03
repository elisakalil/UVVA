import Foundation

/// The map of the chosen country in By region, with its regions pinned (LEARN-R06).
struct RegionMapUIModel: Equatable {
    var country: CountryShape
    var pins: [RegionPinUIModel]
}
