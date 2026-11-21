import Foundation

/// "Find the wine" (Home) and "Find it" (Cellar, CELLAR-R18) search the web for the bottle: producer and name only.
/// The vintage is left out: a shop or page for another year of the same wine is still the one to find.
public enum WineSearch {
    public static func query(for wine: Wine) -> String {
        // Some names already start with the producer; it is not repeated.
        let producer = wine.name.localizedCaseInsensitiveContains(wine.producer) ? "" : wine.producer
        return [producer, wine.name]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    public static func url(for wine: Wine) -> URL? {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query(for: wine))]
        return components?.url
    }
}
