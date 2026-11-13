import Core
import Foundation
@testable import CoreUI

actor CameraStub: CameraAuthorizing {
    var current: CameraAccess
    var allows: Bool
    private(set) var requests = 0

    init(_ current: CameraAccess, allows: Bool = true) {
        self.current = current
        self.allows = allows
    }

    func access() async -> CameraAccess { current }
    func requestAccess() async -> Bool {
        requests += 1
        current = allows ? .authorized : .denied
        return allows
    }
}

struct ReaderStub: LabelReading {
    enum Failure: Error { case offline }
    var text: LabelText?

    func read(front: Data, back: Data) async throws -> LabelText {
        guard let text else { throw Failure.offline }
        return text
    }
}

struct StructurerStub: LabelStructuring {
    var facts: LabelFacts?
    var failure: String? = "Apple Intelligence is off in Settings (appleIntelligenceNotEnabled)."
    func structure(_ text: LabelText) async -> LabelStructuringResult {
        LabelStructuringResult(facts: facts, failure: facts == nil ? failure : nil, context: "iOS 26.1 · pt-PT · language supported")
    }
}

actor LabelCatalogStub: LabelCatalogRepository {
    var wines: [Wine]
    private(set) var scanned: [Wine] = []
    private(set) var loads = 0

    init(_ wines: [Wine]) { self.wines = wines }

    func allWines() async throws -> [Wine] {
        loads += 1
        return wines
    }

    func addScanned(_ wine: Wine) async throws { scanned.append(wine) }
}

enum Labels {
    static let pontoForte = Wine(id: "ravasqueira-ponto-forte-2024", name: "Ponto Forte", producer: "Ravasqueira",
                                 vintage: 2024, type: "Red", origin: "Vinho Regional Alentejano, Portugal",
                                 region: "Alentejo", country: "Portugal", grapes: ["Syrah"],
                                 profile: Maps.flat(8))
    static let alentejoSyrah = Wine(id: "herdade-syrah-2020", name: "Syrah", producer: "Herdade", vintage: 2020,
                                    type: "Red", origin: "Vinho Regional Alentejano, Portugal", region: "Alentejo",
                                    country: "Portugal", grapes: ["Syrah"], profile: Maps.flat(6))
    static let dao = Wine(id: "quinta-dao-2019", name: "Encruzado", producer: "Quinta", vintage: 2019, type: "White",
                          origin: "Dão, Portugal", region: "Dão", country: "Portugal", grapes: ["Encruzado"],
                          profile: Maps.flat(2))
    static let catalog = [pontoForte, alentejoSyrah, dao]

    static let pontoForteLabel = LabelText([
        LabelLine("Ponto Forte", height: 0.12),
        LabelLine("RAVASQUEIRA", height: 0.06),
        LabelLine("2024", height: 0.04),
        LabelLine("Syrah", side: .back),
        LabelLine("14% vol", side: .back)
    ])
}
