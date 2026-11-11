import SwiftUI

/// Two radars side by side, swiped or tapped between: the wine's own map, then the wine over the user's map.
///
/// A paging scroll view rather than a paged `TabView`: the `TabView` hosts each slide in a UIKit page of its own,
/// and inside the Home's scroll those pages were laid out again on every frame, so the scroll dragged
/// whenever the open card was on screen.
public struct WineMapCarousel: View {
    public struct Copy {
        let wineTitle: String
        let comparisonTitle: String
        let wineLegend: String
        let palateLegend: String
        let overlapLegend: String?

        public init(wineTitle: String, comparisonTitle: String, wineLegend: String, palateLegend: String,
                    overlapLegend: String? = nil) {
            self.wineTitle = wineTitle
            self.comparisonTitle = comparisonTitle
            self.wineLegend = wineLegend
            self.palateLegend = palateLegend
            self.overlapLegend = overlapLegend
        }
    }

    private let copy: Copy
    private let labels: [String]
    private let wine: [Double]
    private let palate: [Double]?
    private let active: Bool
    private let tint: Color

    public init(copy: Copy, labels: [String], wine: [Double], palate: [Double]?, active: Bool = true,
                tint: Color = UVVAColor.cream) {
        self.copy = copy
        self.labels = labels
        self.wine = wine
        self.palate = palate
        self.active = active
        self.tint = tint
    }

    @State private var shown: Int? = 0
    /// Once the maps come into view, the pager slides on to the second map by itself, so the user sees there is one.
    /// Done once each time the card opens; leaving before it plays cancels it.
    @State private var hinted = false
    @State private var hint: Task<Void, Never>?
    @State private var visible = false

    private var page: Int { shown ?? 0 }

    public var body: some View {
        VStack(spacing: 14) {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    slide(title: copy.wineTitle) {
                        chart()
                    }
                    .containerRelativeFrame(.horizontal)
                    .id(0)
                    if let palate {
                        slide(title: copy.comparisonTitle) {
                            chart(palate: palate)
                        } legend: {
                            HStack(spacing: 18) {
                                legendItem(copy.wineLegend, dashed: false)
                                legendItem(copy.palateLegend, dashed: true)
                                if let overlapLegend = copy.overlapLegend {
                                    HStack(spacing: 7) {
                                        RoundedRectangle(cornerRadius: 2).fill(tint.opacity(0.3)).frame(width: 9, height: 9)
                                        Text(overlapLegend.uppercased())
                                            .font(UVVAFont.sans(9, .regular))
                                            .tracking(1.8)
                                    }
                                }
                            }
                        }
                        .containerRelativeFrame(.horizontal)
                        .id(1)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $shown)
            .frame(height: 274)
            .contentShape(Rectangle())
            .onTapGesture {
                guard palate != nil else { return }
                withAnimation(.smooth) { shown = page == 0 ? 1 : 0 }
            }
            .onScrollVisibilityChange(threshold: 0.9) { visible = $0; playHint() }
            .onDisappear { hint?.cancel() }
            .onChange(of: active) { _, active in
                if !active {
                    hinted = false
                    shown = 0
                }
                playHint()
            }

            if palate != nil {
                HStack(spacing: 6) {
                    ForEach(0..<2, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? tint : tint.opacity(0.35))
                            .frame(width: index == page ? 18 : 4, height: 4)
                    }
                }
                .animation(.smooth(duration: 0.25), value: page)
                .accessibilityHidden(true)
            }
        }
    }

    private func chart(palate: [Double]? = nil) -> some View {
        WineMapChart(labels: labels, wine: wine, palate: palate, tint: tint)
    }

    private func playHint() {
        hint?.cancel()
        guard palate != nil, visible, active, !hinted, page == 0 else { return }
        hint = Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled, page == 0 else { return }
            hinted = true
            withAnimation(.smooth(duration: 0.7)) { shown = 1 }
        }
    }

    private func slide<Chart: View>(title: String, @ViewBuilder chart: () -> Chart) -> some View {
        slide(title: title, chart: chart) { EmptyView() }
    }

    private func slide<Chart: View, Legend: View>(title: String, @ViewBuilder chart: () -> Chart,
                                                  @ViewBuilder legend: () -> Legend) -> some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(UVVAFont.sans(8.5, .medium))
                .tracking(2.2)
            chart()
                .frame(maxWidth: .infinity)
                .frame(height: 206)
                .padding(.top, 12)
            legend()
            Spacer(minLength: 0)
        }
        .foregroundStyle(tint)
    }

    private func legendItem(_ label: String, dashed: Bool) -> some View {
        HStack(spacing: 8) {
            Path { $0.move(to: .zero); $0.addLine(to: CGPoint(x: 16, y: 0)) }
                .stroke(tint, style: StrokeStyle(lineWidth: 1.2, dash: dashed ? [3, 2] : []))
                .frame(width: 16, height: 1)
            Text(label.uppercased())
                .font(UVVAFont.sans(9, .regular))
                .tracking(1.8)
        }
    }
}
