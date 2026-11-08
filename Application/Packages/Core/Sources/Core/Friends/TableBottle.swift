import Foundation

/// One bottle of a table (FRI-R14, R15): the course, the wine, the dish it goes with, and the axis it was picked for.
public struct TableBottle: Equatable, Sendable {
    public var course: TableCourse
    public var wine: Wine
    public var recipe: Recipe
    public var axis: PalateAxis

    public init(course: TableCourse, wine: Wine, recipe: Recipe, axis: PalateAxis) {
        self.course = course
        self.wine = wine
        self.recipe = recipe
        self.axis = axis
    }
}
