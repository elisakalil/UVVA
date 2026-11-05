import Core
import DesignSystem
import SwiftUI

/// "Over time" (YOU-R10): the map of a chosen moment under today's, and how each axis moved since.
struct OverTimeSection: View {
    var model: MapUIModel
    var onSelect: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: model.historyTitle)
            Text(model.historyDescription)
                .font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.84)
                .padding(.top, 12)

            if let lastChange = model.lastChange {
                Text(lastChange)
                    .font(UVVAFont.sans(13, .regular))
                    .foregroundStyle(UVVAColor.mossDeep)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 20).fill(UVVAColor.creamFill))
                    .padding(.top, 16)
            }

            if model.snapshots.count >= 2 {
                PalateMapChart(values: model.map.chartValues, labels: PalateAxis.allCases.map(\.label),
                               comparison: model.comparison?.chartValues)
                    .scaleEffect(0.84)
                    .frame(width: PalateMapChart.size.width * 0.84, height: PalateMapChart.size.height * 0.84)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)

                ZStack(alignment: .top) {
                    Rectangle().opacity(0.3).frame(height: 0.5).padding(.horizontal, 22).padding(.top, 22)
                    HStack {
                        ForEach(model.snapshots) { snapshot in
                            Button { onSelect(snapshot.id) } label: {
                                VStack(spacing: 10) {
                                    Text(snapshot.isNew ? model.newSnapshotTitle.uppercased() : " ")
                                        .font(UVVAFont.sans(7, .semibold)).tracking(1.4)
                                    Circle()
                                        .fill(UVVAColor.creamFill.opacity(snapshot.id == model.selected ? 1 : 0.4))
                                        .frame(width: snapshot.id == model.selected ? 10 : 6,
                                               height: snapshot.id == model.selected ? 10 : 6)
                                        .frame(width: 10, height: 10)
                                    Text(snapshot.label.uppercased())
                                        .font(UVVAFont.sans(8.5)).tracking(1.2)
                                        .opacity(snapshot.id == model.selected ? 1 : 0.6)
                                }
                                .frame(width: 56)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(snapshot.detail)
                            if snapshot.id != model.snapshots.last?.id { Spacer(minLength: 0) }
                        }
                    }
                }
                .padding(.top, 16)

                Text(model.snapshots[model.selected].detail)
                    .font(UVVAFont.sans(12)).opacity(0.7)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                VStack(spacing: 0) {
                    ForEach(model.deltas) { row in
                        HStack {
                            Text(row.name.uppercased()).font(UVVAFont.sans(9.5, .regular)).tracking(1.5)
                            Spacer()
                            Text(row.delta).font(UVVAFont.sans(12, .regular))
                        }
                        .padding(.vertical, 10)
                    }
                }
                .padding(.top, 16)
            }
        }
    }
}
