import Core
import Foundation

@MainActor
protocol ReadLabelUseCaseProtocol {
    /// "Reading your label" (CELLAR-R17): the two photos read on the phone and looked up in the catalog. `backScan`, the
    /// back label read frame after frame, decides how sure each of its lines is; the back photo is one more frame.
    /// `onStage` hears each step as it starts, for the camera to show.
    func execute(front: Data, back: Data, backScan: LabelScan?,
                 onStage: @MainActor (LabelReadStage) -> Void) async -> LabelReadResult
}

extension ReadLabelUseCaseProtocol {
    func execute(front: Data, back: Data, backScan: LabelScan?) async -> LabelReadResult {
        await execute(front: front, back: back, backScan: backScan, onStage: { _ in })
    }
}
