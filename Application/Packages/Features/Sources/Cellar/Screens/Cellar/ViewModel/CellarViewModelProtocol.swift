import Combine
import Foundation
import UIKit

@MainActor
public protocol CellarViewModelProtocol: ObservableObject {
    associatedtype NoteModel: NoteViewModelProtocol
    var uiModel: CellarUIModel { get }
    /// The saved note open over the Cellar (CELLAR-R13).
    var note: NoteModel? { get }
    func openNote(_ wineKey: String)
    func closeNote()
    /// The note's sheet has gone; Edit opens the new note then (CELLAR-R27).
    func noteDismissed()
    /// The `+` (CELLAR-R14).
    func add()
    func preparePhotos(for items: [CellarItemUIModel], mode: CellarViewMode) async throws -> [String: UIImage]
    func frontPhotos(for wineKeys: [String]) async throws -> [String: Data]
    func load() async
    func selectViewMode(_ mode: CellarViewMode)
    func openFilter(_ facet: CellarFacet)
    func closeFilter()
    func pick(_ value: String)
    func clearOpenFilter()
    func clearFilters()
    func updateQuery(_ query: String)
}

extension CellarViewModelProtocol {
    public func frontPhotos(for wineKeys: [String]) async throws -> [String: Data] { [:] }

    public func preparePhotos(for items: [CellarItemUIModel], mode: CellarViewMode) async throws -> [String: UIImage] {
        try await loadPhotos(for: items, mode: mode)
    }

    func loadPhotos(for items: [CellarItemUIModel], mode: CellarViewMode) async throws -> [String: UIImage] {
        guard !items.isEmpty else { return [:] }
        let stored = try await frontPhotos(for: items.filter { $0.photo == nil }.map(\.id))
        var images: [String: UIImage] = [:]
        for item in items {
            try Task.checkCancellation()
            if let data = item.photo ?? stored[item.id],
               let image = await CellarPhotoCache.load(data, maxPixel: mode.thumbnailPixels) {
                images[item.id] = image
            }
        }
        try Task.checkCancellation()
        return images
    }
}
