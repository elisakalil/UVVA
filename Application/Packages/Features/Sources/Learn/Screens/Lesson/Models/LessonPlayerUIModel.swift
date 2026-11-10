import DesignSystem

public struct LessonPlayerUIModel {
    var cover = LessonCoverUIModel(eyebrow: "", number: "", title: "", subtitle: "", minutes: "", xp: "", steps: "",
                                    objectives: [])
    var header = StepHeaderUIModel(brand: "", title: "", current: nil, total: 0, counter: "", backLeaves: true)
    var stepModel: StepUIModel?
    var footer: PlayerFooterUIModel = .button(title: "", isEnabled: false)
    var certificate: CertificateUIModel?
    var stepIndex: Int?
    var isTip = false
    var isSummary = false
    var isCover = true
    /// The last moment to feel, by haptics (SensoryCue).
    var sensory: SensoryEvent?
    var resources = LearnResourcesUIModel()
}
