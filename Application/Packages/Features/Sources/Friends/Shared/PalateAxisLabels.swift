import Core

/// The axis names around a chart, in chart order.
enum PalateAxisLabels {
    static var all: [String] { PalateAxis.allCases.map(\.label) }
}
