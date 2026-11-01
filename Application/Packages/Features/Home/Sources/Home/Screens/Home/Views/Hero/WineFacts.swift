import Core
import DesignSystem
import SwiftUI

/// The facts of the day's wine, two to a row: origin, vintage, grapes, serving, then the notes across.
struct WineFacts: View {
    var wine: Wine
    var now = Date()

    private struct Fact: Identifiable {
        var label: String
        var value: String
        var wide = false
        var id: String { label }
    }

    private var facts: [Fact] {
        var facts: [Fact] = []
        if !wine.origin.isEmpty { facts.append(Fact(label: "Origin", value: wine.origin)) }
        if let vintage = wine.vintage { facts.append(Fact(label: "Vintage", value: vintageLine(vintage))) }
        if !wine.grapes.isEmpty { facts.append(Fact(label: "Grapes", value: wine.grapes.joined(separator: ", "))) }
        if let serving = wine.serving {
            facts.append(Fact(label: "Serve at", value: "\(serving.lowerBound)–\(serving.upperBound) °C"))
        }
        if !wine.classification.isEmpty {
            facts.append(Fact(label: "Appellation", value: wine.classification, wide: true))
        } else if let alcohol = wine.alcohol {
            facts.append(Fact(label: "Strength", value: "\(alcohol.formatted(.number.precision(.fractionLength(0...1))))% abv", wide: true))
        }
        if let note = wine.note, !note.isEmpty { facts.append(Fact(label: "Notes", value: note, wide: true)) }
        return facts
    }

    /// "2023 · 3 years"
    private func vintageLine(_ vintage: Int) -> String {
        let age = Calendar.current.component(.year, from: now) - vintage
        switch age {
        case ..<1: return "\(vintage)"
        case 1: return "\(vintage) · 1 year"
        default: return "\(vintage) · \(age) years"
        }
    }

    var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 24, verticalSpacing: 22) {
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                if row.count == 1, row[0].wide {
                    GridRow { cell(row[0]).gridCellColumns(2) }
                } else {
                    GridRow {
                        ForEach(row) { cell($0) }
                        if row.count == 1 { Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]) }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Short facts paired two by two; a wide one takes a row of its own.
    private var rows: [[Fact]] {
        var rows: [[Fact]] = []
        for fact in facts {
            if !fact.wide, let last = rows.last, last.count == 1, !last[0].wide {
                rows[rows.count - 1].append(fact)
            } else {
                rows.append([fact])
            }
        }
        return rows
    }

    private func cell(_ fact: Fact) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fact.label.uppercased())
                .font(UVVAFont.sans(8, .medium))
                .tracking(1.9)
                .foregroundStyle(UVVAColor.cream.opacity(0.7))
            Text(fact.value)
                .font(UVVAFont.sans(12.5, .regular))
                .lineSpacing(2)
                .foregroundStyle(UVVAColor.cream)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
