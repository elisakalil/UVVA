import Foundation

/// How far apart the table is on one axis (FRI-R19, "Reading by reading"), from the gap between the lowest and
/// the highest reading. The limits are in `TableMatch`.
public enum AxisSpread: String, CaseIterable, Sendable {
    case same, closest, someGive, widest
}
