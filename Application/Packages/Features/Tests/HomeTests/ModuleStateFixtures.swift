import Core

// Fixture migration for repository doubles. Production uses the persisted ModuleProgressEntity.
func testSnapshot(_ courses: [Course], lessons: [String: LessonProgress]) -> LearningSnapshot {
    var modules: [String: ModuleProgress] = [:]
    for course in courses {
        let state = course.lessons.prefix { lessons[$0.id]?.isCompleted == true }.count
        let opened = course.lessons.compactMap { lessons[$0.id] }
        modules[course.id] = ModuleProgress(courseID: course.id, state: state,
            lastOpenedAt: opened.map(\.lastOpenedAt).max())
    }
    return LearningSnapshot(lessons: lessons, modules: modules)
}
