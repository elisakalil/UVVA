import Foundation

/// The wines of a photo of a wine list (WINELIST-R04), without a network: the runs of text put back into rows, the
/// rows into sections, and each priced row into a wine with the lines that go with it.
///
/// Lists print the lines around a wine in one of two ways: the name with the price, then the grape and region under
/// it; or the name alone, then the grape and region with the price. Each section votes on which, by its first wine.
public enum WineListParser {
    /// A row that is mostly sentence is a description, kept only as a detail.
    static let longLine = 14

    public static func entries(in lines: [WineListLine]) -> [WineListEntry] {
        let rows = columns(lines).flatMap(rows)
        return rows.contains { $0.price != nil } ? priced(rows) : unpriced(rows)
    }

    public static func currency(in lines: [WineListLine]) -> String? {
        WineListPrice.currency(in: lines.map(\.text))
    }

    // MARK: Rows

    struct Row: Equatable {
        var text: String
        var price: Double?
        var height: Double
        var sectionType: String? { price == nil ? WineListSection.type(of: text) : nil }
        var hasLetters: Bool { text.filter(\.isLetter).count >= 3 }
        var isFiller: Bool { WineListSection.isFiller(text) }
    }

    /// Two columns are read one after the other: the left one, then the right. A list is in two columns when a good
    /// part of its words sit wholly on each side and almost none cross the middle.
    static func columns(_ lines: [WineListLine]) -> [[WineListLine]] {
        let worded = lines.filter { $0.text.filter(\.isLetter).count >= 3 }
        guard worded.count >= 6 else { return [lines] }
        let left = worded.filter { $0.maxX < 0.52 }.count
        let right = worded.filter { $0.minX > 0.48 }.count
        let crossing = worded.count - left - right
        let total = Double(worded.count)
        guard Double(left) / total >= 0.3, Double(right) / total >= 0.3, Double(crossing) / total < 0.15 else {
            return [lines]
        }
        let isLeft: (WineListLine) -> Bool = { $0.minX + $0.width / 2 < 0.5 }
        return [lines.filter(isLeft), lines.filter { !isLeft($0) }]
    }

    /// Runs of text whose middles are level make one row, read left to right.
    static func rows(_ lines: [WineListLine]) -> [Row] {
        let sorted = lines.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }.sorted { $0.midY < $1.midY }
        var groups: [[WineListLine]] = []
        for line in sorted {
            if let last = groups.last, let anchor = last.first,
               abs(line.midY - anchor.midY) < max(min(line.height, anchor.height) * 0.6, 0.004) {
                groups[groups.count - 1].append(line)
            } else {
                groups.append([line])
            }
        }
        var rows: [Row] = []
        for group in groups {
            let text = group.sorted { $0.minX < $1.minX }.map(\.text).joined(separator: " ")
            let split = WineListPrice.split(text)
            let height = group.map(\.height).max() ?? 0
            // A price read on a row of its own goes to the wine above it, when that one has none.
            if !split.text.contains(where: \.isLetter), let price = split.price {
                if let last = rows.last, last.price == nil, last.hasLetters, last.sectionType == nil {
                    rows[rows.count - 1].price = price
                }
                continue
            }
            rows.append(Row(text: split.text, price: split.price, height: height))
        }
        return rows
    }

    // MARK: Entries

    private struct Builder {
        var entries: [WineListEntry] = []
        var section: String?
        var sectionType: String?
        var position = 0

        mutating func heading(_ row: Row) {
            section = row.text
            sectionType = row.sectionType
            position = 0
        }

        mutating func add(name: String, details: [String], price: Double?) {
            guard name.filter(\.isLetter).count >= 3, !WineListSection.isFiller(name) else { return }
            position += 1
            entries.append(WineListEntry(name: name, details: details, price: price, section: section,
                                         sectionType: sectionType, position: position))
        }
    }

    private static func priced(_ rows: [Row]) -> [WineListEntry] {
        let detailsFollow = detailsFollowName(rows)
        var builder = Builder()
        var pending: [String] = []
        var current: (name: String, details: [String], price: Double?)?
        func close() {
            if let wine = current { builder.add(name: wine.name, details: wine.details, price: wine.price) }
            current = nil
        }
        for row in rows {
            if row.sectionType != nil {
                close()
                pending = []
                builder.heading(row)
                continue
            }
            guard row.hasLetters, !row.isFiller else { continue }
            if let price = row.price {
                close()
                if detailsFollow || pending.isEmpty {
                    current = (row.text, [], price)
                } else {
                    let name = pending.removeFirst()
                    current = (name, Array((pending + [row.text]).suffix(3)), price)
                    close()
                }
                pending = []
            } else if detailsFollow, current != nil {
                if current!.details.count < 3 { current!.details.append(row.text) }
            } else if !detailsFollow {
                // The lines before a price: the name, then what is said of it; a long run starts again.
                if isLong(row) { continue }
                pending.append(row.text)
                if pending.count > 3 { pending.removeFirst() }
            }
        }
        close()
        return builder.entries
    }

    /// Without prices, the rows in the larger type are the wines and the smaller ones say what each one is.
    private static func unpriced(_ rows: [Row]) -> [WineListEntry] {
        let worded = rows.filter { $0.hasLetters && !$0.isFiller && $0.sectionType == nil && !isLong($0) }
        let heights = worded.map(\.height).sorted()
        let median = heights.isEmpty ? 0 : heights[heights.count / 2]
        var builder = Builder()
        var current: (name: String, details: [String])?
        func close() {
            if let wine = current { builder.add(name: wine.name, details: wine.details, price: nil) }
            current = nil
        }
        for row in rows {
            if row.sectionType != nil {
                close()
                builder.heading(row)
                continue
            }
            guard row.hasLetters, !row.isFiller else { continue }
            if row.height >= median * 0.9, !isLong(row) {
                close()
                current = (row.text, [])
            } else if current != nil, current!.details.count < 3 {
                current!.details.append(row.text)
            }
        }
        close()
        return builder.entries
    }

    /// Each section's first wine row votes: priced first means the details follow the name. Ties follow the name.
    private static func detailsFollowName(_ rows: [Row]) -> Bool {
        var follow = 0
        var lead = 0
        var waitingForFirst = true
        for row in rows {
            if row.sectionType != nil {
                waitingForFirst = true
                continue
            }
            guard waitingForFirst, row.hasLetters, !row.isFiller, !isLong(row) else { continue }
            waitingForFirst = false
            if row.price != nil { follow += 1 } else { lead += 1 }
        }
        return follow >= lead
    }

    private static func isLong(_ row: Row) -> Bool {
        row.text.split(whereSeparator: \.isWhitespace).count > longLine
    }
}
