import Foundation

@MainActor
protocol ReadLabelUseCaseProtocol {
    /// "Reading your label" (CELLAR-R17): the two photos read on the phone and looked up in the catalog.
    func execute(front: Data, back: Data) async -> LabelReadResult
}
