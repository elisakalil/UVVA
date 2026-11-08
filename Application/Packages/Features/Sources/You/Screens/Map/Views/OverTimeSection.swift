import Core
import DesignSystem
import SwiftUI

/// The six most recent map changes since the Quiz (YOU-R10).
struct OverTimeSection: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedIndex: Int?
    @State private var transition: HistoryMapTransition?

    var model: MapUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: model.historyTitle)
            if let lastChange = model.lastChange {
                Text(lastChange)
                    .font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.84)
                    .padding(.top, 12)
            }

            let selected = min(selectedIndex ?? model.snapshots.count - 1, model.snapshots.count - 1)
            let coordinates = model.historyChartValues
            let values = coordinates[selected]
            TimelineView(.animation(paused: transition == nil || reduceMotion)) { context in
                PalateMapChart(values: reduceMotion ? values : transition?.values(at: context.date) ?? values,
                               labels: PalateAxis.allCases.map(\.label))
            }
            .scaleEffect(0.84)
            .frame(width: PalateMapChart.size.width * 0.84, height: PalateMapChart.size.height * 0.84)
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .task(id: transition) {
                guard transition != nil else { return }
                try? await Task.sleep(for: .seconds(HistoryMapTransition.duration))
                guard !Task.isCancelled else { return }
                transition = nil
            }

            HStack(spacing: 0) {
                ForEach(model.snapshots.indices, id: \.self) { index in
                    let date = model.snapshots[index].date
                    let isSelected = index == selected
                    Button {
                        guard !isSelected else { return }
                        let target = coordinates[index]
                        let now = Date.now
                        let displayed = transition?.values(at: now) ?? values
                        transition = reduceMotion || displayed == target ? nil
                            : HistoryMapTransition(from: displayed, to: target, startedAt: now)
                        selectedIndex = index
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(UVVAColor.creamFill.opacity(isSelected ? 1 : 0.4))
                                .frame(width: isSelected ? 10 : 6, height: isSelected ? 10 : 6)
                                .frame(width: 10, height: 10)
                            VStack(spacing: 3) {
                                Text(date.formatted(.dateTime.day().month(.defaultDigits)))
                                    .font(UVVAFont.sans(9, isSelected ? .semibold : .regular))
                                if model.snapshots.indices.contains(where: { other in
                                    other != index && Calendar.current.isDate(model.snapshots[other].date, inSameDayAs: date)
                                }) {
                                    Text(date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute().second()))
                                        .font(UVVAFont.sans(8))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                }
                            }
                            .opacity(isSelected ? 1 : 0.6)
                        }
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .top)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(date.formatted(.dateTime.day().month(.wide).year().hour().minute().second()))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .background(alignment: .top) {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(UVVAColor.creamFill.opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.horizontal, geometry.size.width / (2 * CGFloat(model.snapshots.count)))
                        .padding(.top, 12.75)
                }
            }
            .padding(.top, 16)

            VStack(spacing: 0) {
                ForEach(model.historyDeltas) { row in
                    HStack {
                        Text(row.axis.label.uppercased()).font(UVVAFont.sans(9.5, .regular)).tracking(1.5)
                        Spacer()
                        Text(row.delta).font(UVVAFont.sans(12, .regular))
                    }
                    .padding(.vertical, 10)
                }
            }
            .padding(.top, 16)
        }
        .onChange(of: model.snapshots) {
            selectedIndex = nil
            transition = nil
        }
    }
}
