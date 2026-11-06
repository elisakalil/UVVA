import Core

struct GlossaryUIModel {
    var query = ""
    var terms: [GlossaryTermUIModel] = []
    var selectedTerm: GlossaryTerm?
    var resources = GlossaryResourcesUIModel()
}

struct GlossaryTermUIModel: Identifiable {
    var term: GlossaryTerm
    var isMatch: Bool
    var id: String { term.term }
}
