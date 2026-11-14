import Foundation

/// A serving temperature the model on the phone gives is kept only when the label prints it (CELLAR-R17): its
/// degrees on a line that speaks of temperature. The model may sort the text, not add a temperature it guessed.
public enum ServingEvidence {
    /// The words of a line about temperature, folded; "°" and "º" count too.
    static let markers: Set<String> = ["c", "graus", "temperatura", "temperature", "serve", "servir", "servire",
                                       "servieren", "served", "serving"]

    public static func isRead(_ serving: ClosedRange<Int>, in lines: [LabelLine]) -> Bool {
        lines.contains { line in
            let words = WineText.tokens(line.text)
            let isAboutTemperature = line.text.contains("°") || line.text.contains("º")
                || words.contains(where: markers.contains)
            guard isAboutTemperature else { return false }
            let numbers = Set(words.compactMap(Int.init))
            return numbers.contains(serving.lowerBound) && numbers.contains(serving.upperBound)
        }
    }
}
