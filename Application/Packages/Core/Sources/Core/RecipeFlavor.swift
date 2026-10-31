import Foundation

/// How a dish tastes, each 0...9.
public struct RecipeFlavor: Codable, Equatable, Sendable {
    public var salt: Double
    public var fat: Double
    public var acid: Double
    public var sweet: Double
    public var umami: Double
    public var heat: Double
    public var bitter: Double
    public var weight: Double

    public init(salt: Double, fat: Double, acid: Double, sweet: Double,
                umami: Double, heat: Double, bitter: Double, weight: Double) {
        self.salt = salt
        self.fat = fat
        self.acid = acid
        self.sweet = sweet
        self.umami = umami
        self.heat = heat
        self.bitter = bitter
        self.weight = weight
    }
}
