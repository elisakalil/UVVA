import DesignSystem
import SwiftUI

/// By region: the chosen country drawn from real geometry, the land around it fading out, and its regions pinned at
/// their true places. The open region's dot is larger, with a ring; tapping a dot or a name opens it (LEARN-R06).
struct RegionMapView: View {
    var resources = LearnResourcesUIModel()
    var model: RegionMapUIModel
    var onPick: (String) -> Void

    private let ink = UVVAColor.creamFill

    var body: some View {
        Color.clear
            .aspectRatio(MapProjection.aspectRatio(box: model.country.box), contentMode: .fit)
            .overlay {
                GeometryReader { geometry in
                    map(in: geometry.size)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(resources.mapAccessibility(model.country.name)))
    }

    private func map(in size: CGSize) -> some View {
        let projection = MapProjection(box: model.country.box, size: size)
        let mainland = model.pins.filter { !$0.isInset }
        let points = Dictionary(uniqueKeysWithValues: mainland.map { ($0.id, projection.point(lon: $0.lon, lat: $0.lat)) })
        let box = model.country.box
        let labels = RegionLabelLayout.place(
            mainland.map { (id: $0.id, name: $0.name, point: points[$0.id] ?? .zero, isSelected: $0.isSelected, lon: $0.lon) },
            midLon: (box[0] + box[2]) / 2, width: size.width)
        return ZStack(alignment: .topLeading) {
            land(projection, size: size)
            ForEach(mainland) { pin in
                if let point = points[pin.id], let label = labels[pin.id] {
                    self.pin(pin, at: point, label: label)
                }
            }
            insets(size: size)
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: Land

    private func land(_ projection: MapProjection, size: CGSize) -> some View {
        ZStack {
            // The neighbours run past the frame; they fade out from the middle, so no edge looks cut.
            Canvas { context, _ in
                for ring in model.country.near {
                    let path = Path(projection.path(ring))
                    context.fill(path, with: .color(ink.opacity(0.05)))
                    context.stroke(path, with: .color(ink.opacity(0.3)), lineWidth: 0.5)
                }
            }
            .mask {
                RadialGradient(stops: [.init(color: .white, location: 0),
                                       .init(color: .white.opacity(0.55), location: 0.58),
                                       .init(color: .white.opacity(0), location: 1)],
                               center: .center, startRadius: 0, endRadius: max(size.width, size.height) * 0.52)
            }
            Canvas { context, _ in
                for ring in model.country.land {
                    let path = Path(projection.path(ring))
                    context.fill(path, with: .color(ink.opacity(0.08)))
                    context.stroke(path, with: .color(ink.opacity(0.55)), lineWidth: 0.8)
                }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }

    // MARK: Pins

    @ViewBuilder
    private func pin(_ pin: RegionPinUIModel, at point: CGPoint, label: RegionLabelLayout.Placement) -> some View {
        let side: CGFloat = label.isRight ? 1 : -1
        if label.hasLeader {
            Path { path in
                path.move(to: CGPoint(x: point.x + side * 6, y: point.y))
                path.addLine(to: CGPoint(x: point.x + side * (RegionLabelLayout.gap(isSelected: pin.isSelected) - 1), y: label.y))
            }
            .stroke(ink.opacity(0.35), lineWidth: 0.5)
            .accessibilityHidden(true)
        }
        name(pin)
            .frame(width: 200, alignment: label.isRight ? .leading : .trailing)
            .position(x: point.x + side * (RegionLabelLayout.gap(isSelected: pin.isSelected) + 100), y: label.y)
        dot(pin)
            .position(point)
    }

    private func dot(_ pin: RegionPinUIModel) -> some View {
        Button { onPick(pin.id) } label: {
            ZStack {
                Circle()
                    .stroke(ink.opacity(0.4), lineWidth: 0.6)
                    .frame(width: 26, height: 26)
                    .scaleEffect(pin.isSelected ? 1 : 0.3)
                    .opacity(pin.isSelected ? 1 : 0)
                Circle()
                    .fill(ink.opacity(pin.isSelected ? 1 : 0.55))
                    .frame(width: pin.isSelected ? 11 : 6, height: pin.isSelected ? 11 : 6)
            }
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pin.name)
        .accessibilityAddTraits(pin.isSelected ? .isSelected : [])
    }

    private func name(_ pin: RegionPinUIModel) -> some View {
        let size = RegionLabelLayout.fontSize(isSelected: pin.isSelected)
        return Text(pin.name)
            .font(UVVAFont.sans(size))
            .tracking(size * 0.06)
            .foregroundStyle(ink.opacity(pin.isSelected ? 1 : 0.6))
            .lineLimit(1)
            .fixedSize()
            .contentShape(Rectangle())
            .onTapGesture { onPick(pin.id) }
            .accessibilityHidden(true)
    }

    // MARK: Insets

    /// Regions far off the mainland (Madeira), each in a small frame in the lower left corner.
    private func insets(size: CGSize) -> some View {
        HStack(spacing: 8) {
            ForEach(model.pins.filter(\.isInset)) { pin in
                VStack(spacing: 4) {
                    dot(pin)
                    name(pin)
                }
                .frame(width: 76, height: 64)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(ink.opacity(0.2), lineWidth: 0.5))
            }
        }
        .padding(14)
        .frame(width: size.width, height: size.height, alignment: .bottomLeading)
    }
}
