import Foundation

/// YOU-R01: name, photo and the palate's signature. No handle.
struct YouHeaderUIModel: Equatable {
    var name: String
    var signature: String
    var photo: Data?
}
