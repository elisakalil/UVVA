import CoreImage

/// A two-colour ramp of the wash: the shadows of the photo take `shadow`, the lights take `light` (YOU-R14a).
struct PhotoWashTone {
    var shadow: CIColor
    var light: CIColor
}
