import Foundation

/// How an option, a word, a row or a term reads: by colour and a word, never a tick or a cross (D7).
enum OptionState: Equatable {
    case idle, selected, correct, wrong
}
