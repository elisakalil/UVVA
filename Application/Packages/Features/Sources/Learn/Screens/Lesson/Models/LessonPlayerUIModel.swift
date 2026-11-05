import DesignSystem

public struct LessonPlayerUIModel {
    var cover = LessonCoverUIModel(eyebrow: "", number: "", title: "", subtitle: "", minutes: "", xp: "", steps: "",
                                    objectives: [], showsReviewPrevious: false)
    var header = StepHeaderUIModel(brand: "", title: "", current: nil, total: 0, counter: "", backLeaves: true)
    var stepModel: StepUIModel?
    var footer: PlayerFooterUIModel = .button(title: "", isEnabled: false)
    var certificate: CertificateUIModel?
    var stepIndex: Int?
    var isTip = false
    var isSummary = false
    var isCover = true
    var resources = LearnResourcesUIModel()
}
