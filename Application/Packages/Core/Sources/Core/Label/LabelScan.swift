import Foundation

/// The back label read frame after frame while the bottle turns in front of the camera (CELLAR-R17). A curved label
/// never shows a long line whole: each frame reads a different piece of it, cut at other words. The pieces are laid
/// on one another by the words they share, and each word of the line is voted on by every frame that read it. A
/// line read in several frames is one the camera surely saw, while noise, read differently each time, gathers no
/// votes. The votes become each line's confidence, which is what decides whether a line can back an award
/// (`AwardEvidence`).
public struct LabelScan: Equatable, Sendable {
    /// One word of a line, with each spelling the frames gave it and how often.
    struct Slot: Equatable, Sendable {
        var spellings: [String: Int] = [:]
        /// The folded spellings, to find the word again however a frame spelt it.
        var keys: Set<String> = []
        /// The commonest spelling (the longest of equals: a word cut at the frame's edge is shorter), folded.
        var best = ""
        var key = ""
        var votes = 0

        mutating func vote(_ word: String) {
            spellings[word, default: 0] += 1
            votes += 1
            let folded = LabelScan.fold(word)
            keys.insert(folded)
            best = spellings.max { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value < rhs.value }
                if lhs.key.count != rhs.key.count { return lhs.key.count < rhs.key.count }
                return lhs.key > rhs.key
            }?.key ?? word
            key = LabelScan.fold(best)
        }
    }

    /// A line of the label, put together from what the frames read of it.
    struct Group: Equatable, Sendable {
        var slots: [Slot]
        var frames: Set<Int>
        var reads = 0
        var height = 0.0
        var confidence = 0.0
        /// When it was first read, to keep the label's order: the frame, then the line in it.
        var firstFrame: Int
        var firstLine: Int
    }

    /// From this many frames on it is a scan, and a line read in only one of them is doubted.
    static let scanFrames = 3
    /// The votes a line needs, in a scan, to be confirmed.
    static let confirmingVotes = 2
    /// What is left of the recognizer's confidence in a line only one frame of a scan read: even a line it was sure
    /// of stays under what an award needs (`AwardEvidence.minimumConfidence`).
    static let doubt = 0.4
    /// How far two readings may differ and still be the same line: a share of the longer one.
    static let tolerance = 0.15
    /// Pieces are laid on one another by at least this many words in common, or this many letters.
    static let anchorWords = 3
    static let anchorLetters = 12
    /// The share of the words two pieces have over one another that must agree.
    static let agreement = 0.7

    private(set) var groups: [Group] = []
    /// Which groups have each word, folded: the pieces a new one may belong to.
    private var index: [String: Set<Int>] = [:]
    /// The frames read so far.
    public private(set) var frames = 0
    /// The video frames left out as blurred.
    public private(set) var skippedFrames = 0
    /// Every frame's lines as the recognizer gave them, to export a scan and replay it in a test.
    public private(set) var readings: [[LabelLine]] = []

    public init() {}

    /// A frame of the video: left out when it is blurred, which is when the recognizer is unsure of most of what it
    /// read. True when it was kept.
    @discardableResult
    public mutating func addFrame(_ lines: [LabelLine]) -> Bool {
        guard Self.isSharp(lines) else {
            skippedFrames += 1
            return false
        }
        add(lines)
        return true
    }

    /// A frame, or the photo, as it is.
    public mutating func add(_ lines: [LabelLine]) {
        let frame = frames
        frames += 1
        readings.append(lines)
        for (number, line) in lines.enumerated() {
            let words = line.text.split(whereSeparator: \.isWhitespace).map(String.init)
            let keys = words.map(Self.fold)
            guard keys.contains(where: { !$0.isEmpty }) else { continue }
            if let (group, offset) = place(keys, frame: frame) {
                merge(words, keys: keys, line: line, frame: frame, into: group, at: offset)
            } else {
                var group = Group(slots: [], frames: [frame], firstFrame: frame, firstLine: number)
                for word in words {
                    var slot = Slot()
                    slot.vote(word)
                    group.slots.append(slot)
                }
                group.reads = 1
                group.height = line.height
                group.confidence = line.confidence
                groups.append(group)
                indexWords(of: groups.count - 1)
            }
        }
    }

    /// The lines read in enough frames to be sure of.
    public var confirmedCount: Int {
        frames >= Self.scanFrames ? groups.filter { $0.frames.count >= Self.confirmingVotes }.count : 0
    }

    /// Every line, in the order first read, each word in its commonest spelling. A line confirmed by the scan is at
    /// least as sure as its votes make it (0.7 for two, 0.8 for three…); one read in a single frame of a scan is
    /// doubted (`doubt`). With fewer frames than a scan (a photo alone), the recognizer's word stands. In a scan, a
    /// word at either end of a line that a single frame read is a word the frame's edge cut, and goes.
    public func lines(side: LabelSide = .back) -> [LabelLine] {
        groups.sorted { ($0.firstFrame, $0.firstLine) < ($1.firstFrame, $1.firstLine) }.compactMap { group in
            var slots = group.slots[...]
            if frames >= Self.scanFrames, group.frames.count >= Self.confirmingVotes {
                while slots.count > 1, slots.first?.votes == 1 { slots.removeFirst() }
                while slots.count > 1, slots.last?.votes == 1 { slots.removeLast() }
            }
            let text = slots.map(\.best).joined(separator: " ")
            guard !text.isEmpty else { return nil }
            let reads = Double(max(group.reads, 1))
            let mean = group.confidence / reads
            let votes = group.frames.count
            let confidence = if frames < Self.scanFrames {
                mean
            } else if votes >= Self.confirmingVotes {
                max(mean, min(1, 0.5 + 0.1 * Double(votes)))
            } else {
                mean * Self.doubt
            }
            return LabelLine(text, side: side, height: group.height / reads, confidence: confidence)
        }
    }

    /// A frame the recognizer was sure of: at least a third of its lines read at 0.5 or more. A frame with only a
    /// line or two says too little to judge, and is kept.
    public static func isSharp(_ lines: [LabelLine]) -> Bool {
        guard lines.count >= 3 else { return true }
        return Double(lines.filter { $0.confidence >= 0.5 }.count) / Double(lines.count) >= 1.0 / 3
    }

    // MARK: Laying pieces on one another

    /// The group a piece belongs to, and where its first word falls in it; nil for a line not read before.
    private func place(_ keys: [String], frame: Int) -> (group: Int, offset: Int)? {
        var offsets: [Int: Set<Int>] = [:]
        for (position, key) in keys.enumerated() where key.count >= 3 {
            for group in index[key] ?? [] where !groups[group].frames.contains(frame) {
                // A group this frame already put a line in is another line of the label.
                for (slot, candidate) in groups[group].slots.enumerated() where candidate.keys.contains(key) {
                    offsets[group, default: []].insert(slot - position)
                }
            }
        }
        var best: (group: Int, offset: Int, matches: Int, agreement: Double)?
        for (group, candidates) in offsets {
            for offset in candidates {
                guard let fit = fit(keys, in: groups[group], at: offset) else { continue }
                if best == nil || (fit.matches, fit.agreement) > (best!.matches, best!.agreement) {
                    best = (group, offset, fit.matches, fit.agreement)
                }
            }
        }
        return best.map { ($0.group, $0.offset) }
    }

    /// How well a piece lies on a group at this offset; nil when it does not belong there. A line of one or two
    /// words must be the whole group, word for word; a longer one needs enough words in common, mostly agreeing. A
    /// word at either end of the piece that disagrees is one the frame's edge cut, not a disagreement.
    private func fit(_ keys: [String], in group: Group, at offset: Int) -> (matches: Int, agreement: Double)? {
        if keys.count <= 2 || group.slots.count <= 2 {
            guard offset == 0, keys.count == group.slots.count,
                  zip(keys, group.slots).allSatisfy({ Self.isSameWord($0, $1) }) else { return nil }
            return (keys.count, 1)
        }
        var matches = 0, letters = 0, overlap = 0
        for (position, key) in keys.enumerated() {
            let slot = position + offset
            guard group.slots.indices.contains(slot) else { continue }
            if Self.isSameWord(key, group.slots[slot]) {
                matches += 1
                letters += key.count
                overlap += 1
            } else if position != 0, position != keys.count - 1 {
                overlap += 1
            }
        }
        let agreement = Double(matches) / Double(max(overlap, 1))
        guard matches >= 2, matches >= Self.anchorWords || letters >= Self.anchorLetters,
              agreement >= Self.agreement else { return nil }
        return (matches, agreement)
    }

    private mutating func merge(_ words: [String], keys: [String], line: LabelLine, frame: Int, into number: Int,
                                at offset: Int) {
        var group = groups[number]
        var offset = offset
        if offset < 0 {
            group.slots.insert(contentsOf: Array(repeating: Slot(), count: -offset), at: 0)
            offset = 0
        }
        let end = offset + words.count
        if end > group.slots.count {
            group.slots.append(contentsOf: Array(repeating: Slot(), count: end - group.slots.count))
        }
        for (position, word) in words.enumerated() { group.slots[position + offset].vote(word) }
        group.frames.insert(frame)
        group.reads += 1
        group.height += line.height
        group.confidence += line.confidence
        groups[number] = group
        indexWords(of: number)
    }

    private mutating func indexWords(of group: Int) {
        for slot in groups[group].slots {
            for key in slot.keys where key.count >= 3 { index[key, default: []].insert(group) }
        }
    }

    // MARK: Words

    static func fold(_ word: String) -> String { WineText.tokens(word).joined() }

    /// The same word, allowing a letter the camera got wrong in a word of four or more, two in one of eight or more.
    static func isSameWord(_ key: String, _ slot: Slot) -> Bool {
        if slot.keys.contains(key) { return true }
        guard key.count >= 4, slot.key.count >= 4 else { return false }
        let allowed = max(key.count, slot.key.count) >= 8 ? 2 : 1
        guard abs(key.count - slot.key.count) <= allowed else { return false }
        return distance(Array(key.utf8), Array(slot.key.utf8), limit: allowed) <= allowed
    }

    /// The same line read twice, allowing for a letter or two the camera got wrong.
    static func isSameLine(_ lhs: String, _ rhs: String) -> Bool {
        if lhs == rhs { return true }
        let longer = max(lhs.count, rhs.count)
        let allowed = Int((Double(longer) * tolerance).rounded(.down))
        guard allowed > 0, abs(lhs.count - rhs.count) <= allowed else { return false }
        return distance(Array(lhs.utf8), Array(rhs.utf8), limit: allowed) <= allowed
    }

    /// The edit distance, given up once every path is past `limit`.
    static func distance(_ lhs: [UInt8], _ rhs: [UInt8], limit: Int) -> Int {
        guard !lhs.isEmpty else { return rhs.count }
        guard !rhs.isEmpty else { return lhs.count }
        var previous = Array(0...rhs.count)
        var current = [Int](repeating: 0, count: rhs.count + 1)
        for i in 1...lhs.count {
            current[0] = i
            var best = i
            for j in 1...rhs.count {
                let cost = lhs[i - 1] == rhs[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                best = min(best, current[j])
            }
            if best > limit { return best }
            swap(&previous, &current)
        }
        return previous[rhs.count]
    }
}
