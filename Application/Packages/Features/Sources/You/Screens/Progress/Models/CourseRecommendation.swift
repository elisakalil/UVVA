import Core

struct CourseRecommendation: Equatable {
    enum Reason: Equatable {
        case introduction
        case linkedRegion(grape: String)
        case linkedGrape(region: String)
        case nextPathModule
        case explore
    }

    let course: CourseSummary
    let reason: Reason
}
