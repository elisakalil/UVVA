import CoreGraphics
import Foundation

/// The part of a video frame the scan reads (CELLAR-R17): the label frame drawn on screen, so the hand, the table and
/// the laptop behind the bottle are not read with it.
public enum LabelScanRegion {
    /// A little more than the frame on each side, so a line that touches its edge is not cut.
    static let margin = 0.06

    /// The label frame as a share of the upright video frame, with the origin at the bottom left as Vision takes it.
    /// `label` and `preview` are on-screen rects in the same space; the preview shows the frame filling it, cropped
    /// to its shape. Nil when the frame or the preview has no size.
    public static func normalized(label: CGRect, preview: CGRect, frame: CGSize) -> CGRect? {
        guard label.width > 0, label.height > 0, preview.width > 0, preview.height > 0, frame.width > 0,
              frame.height > 0 else { return nil }
        let scale = max(preview.width / frame.width, preview.height / frame.height)
        let shown = CGSize(width: frame.width * scale, height: frame.height * scale)
        let origin = CGPoint(x: preview.midX - shown.width / 2, y: preview.midY - shown.height / 2)
        var x = (label.minX - origin.x) / shown.width
        var top = (label.minY - origin.y) / shown.height
        var width = label.width / shown.width
        var height = label.height / shown.height
        x -= margin * width
        top -= margin * height
        width *= 1 + 2 * margin
        height *= 1 + 2 * margin
        let clipped = CGRect(x: x, y: 1 - top - height, width: width, height: height)
            .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        return clipped.isNull || clipped.isEmpty ? nil : clipped
    }
}
