// Written by Scripts/pack_content.py from 10000 catalog wines. Do not edit: run the script.

public extension QualityPrevalence {
    /// The share of the world's wines at each level or above (CELLAR-R30): appellation and legal term measured on the
    /// catalog, recognition assumed.
    static let packed = QualityPrevalence(
        appellation: ["regional": 0.9999, "protected": 0.9002, "top": 0.2038],
        designation: ["weak": 0.1533, "aged": 0.068, "strong": 0.0218],
        recognition: ["4": 0.005, "3": 0.02, "2": 0.05, "1": 0.1])
}
