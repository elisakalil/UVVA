import Core

extension LearnViewModel {
    var listBuilder: LearnListPresentationBuilder {
        LearnListPresentationBuilder(courses: courses, progress: progress, modules: contentModel.modules, certificates: certificates,
                                     openCourses: openCourses, grapeFilter: grapeFilter, pathLevel: pathLevel,
                                     country: country, pickedRegion: pickedRegion)
    }

    var pathFilters: [FilterUIModel] { listBuilder.pathFilters }
    var pathGroups: [CourseGroupUIModel] { listBuilder.pathGroups }
    var grapeFilters: [FilterUIModel] { listBuilder.grapeFilters }
    var grapeGroups: [CourseGroupUIModel] { listBuilder.grapeGroups }
    var countryFilters: [FilterUIModel] { listBuilder.countryFilters }
    var regionGroups: [CourseGroupUIModel] { listBuilder.regionGroups }
    var regionMap: RegionMapUIModel? { listBuilder.regionMap }

    public func selectGrapeFilter(id: String) {
        switch id {
        case "all": selectGrapeFilter(.all)
        case "red": selectGrapeFilter(.red)
        case "white": selectGrapeFilter(.white)
        default: selectGrapeFilter(.country(String(id.dropFirst("country-".count))))
        }
    }

}
