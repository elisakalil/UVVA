import CoreHaptics
import SwiftUI
import UIKit

/// How each moment of the lesson feels, tuned in one place, like `LessonPalette` for colour. Quiet by design: a right
/// answer is a soft tap, a wrong one softer still, and only the toast at the end has a pattern of its own.
enum LessonSensory {
    /// The system feedback for a cue; nil for the toast, which `ToastClink` plays as "Lesson complete" lands.
    static func feedback(_ cue: SensoryCue) -> SensoryFeedback? {
        switch cue {
        case .select: .selection
        case .swap: .impact(flexibility: .soft, intensity: 0.35)
        case .pair: .impact(flexibility: .soft, intensity: 0.4)
        case .miss: .impact(flexibility: .solid, intensity: 0.2)
        case .correct: .impact(flexibility: .soft, intensity: 0.55)
        case .wrong: .impact(flexibility: .solid, intensity: 0.25)
        case .toast: nil
        }
    }
}

/// The toast at the Summary, felt: two light glasses touching, then the ring of the crystal fading.
@MainActor
final class ToastClink {
    private var engine: CHHapticEngine?

    func play() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }
        do {
            let engine = try self.engine ?? makeEngine()
            try engine.start()
            let player = try engine.makePlayer(with: Self.pattern())
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            engine = nil
        }
    }

    private func makeEngine() throws -> CHHapticEngine {
        let engine = try CHHapticEngine()
        engine.playsHapticsOnly = true
        engine.isAutoShutdownEnabled = true
        engine.resetHandler = { [weak self] in Task { @MainActor in self?.engine = nil } }
        self.engine = engine
        return engine
    }

    /// Two crisp, light taps ~90 ms apart, then a faint continuous ring that decays over ~0.4 s. The player calls it
    /// as "Lesson complete" comes down; the short lead lands the taps as the note settles.
    private static func pattern() throws -> CHHapticPattern {
        let start = 0.12
        func tap(_ time: TimeInterval, _ intensity: Float) -> CHHapticEvent {
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ], relativeTime: time)
        }
        let ring = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.22),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.75)
        ], relativeTime: start + 0.1, duration: 0.42)
        let fade = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            .init(relativeTime: 0, value: 1),
            .init(relativeTime: 0.12, value: 0.6),
            .init(relativeTime: 0.42, value: 0)
        ], relativeTime: start + 0.1)
        return try CHHapticPattern(events: [tap(start, 0.45), tap(start + 0.09, 0.6), ring], parameterCurves: [fade])
    }
}

extension View {
    /// Plays the lesson's haptics as cues arrive. The toast is not played here: the Summary is saved behind a
    /// loading screen first, so the player plays it with "Lesson complete" instead.
    func lessonSensory(_ event: SensoryEvent?) -> some View {
        sensoryFeedback(trigger: event) { _, event in event.flatMap { LessonSensory.feedback($0.cue) } }
    }
}
