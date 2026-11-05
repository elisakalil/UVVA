import Core

extension LearnViewModel {
    var isSearching: Bool { !LearnSearchPresentationBuilder.words(query).isEmpty }
    var searchResults: [SearchGroupUIModel] {
        LearnSearchPresentationBuilder(courses: courses, query: query).searchResults
    }

    /// A course opens in its tab, open; a lesson opens where it was left (LEARN-R11).
    func openResult(_ result: SearchResultUIModel) async {
        query = ""
        switch result.target {
        case let .course(id):
            guard let course = course(id: id) else { return }
            reveal(course)
            // A region opens as if tapped on the map: selected there, and first in the list.
            if course.kind == .region { selectRegion(course.id) }
        case let .lesson(courseID, lessonID):
            guard let course = course(id: courseID) else { return }
            await openLesson(course, lessonID: lessonID)
        }
    }

}
