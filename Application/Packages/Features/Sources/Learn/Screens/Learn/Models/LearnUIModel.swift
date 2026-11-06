import Core
import DesignSystem

public struct LearnUIModel {
    var tab: CourseKind = .region
    var focusedCourseID: String?
    var query = ""
    var isSearching = false
    var pathFilters: [FilterUIModel] = []
    var pathGroups: [CourseGroupUIModel] = []
    var grapeFilters: [FilterUIModel] = []
    var grapeGroups: [CourseGroupUIModel] = []
    var countryFilters: [FilterUIModel] = []
    var regionGroups: [CourseGroupUIModel] = []
    var regionMap: RegionMapUIModel?
    var searchResults: [SearchGroupUIModel] = []
    var isPresentingPlayer = false
    var isLoadingLesson = false
    var lessonError: String?
    var sharedCertificate: CertificateUIModel?
    var resources = LearnResourcesUIModel()
}
