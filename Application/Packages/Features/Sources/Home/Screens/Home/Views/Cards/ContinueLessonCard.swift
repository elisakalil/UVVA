import Core
import DesignSystem
import SwiftUI

/// Half-width card: the lesson number large, the module, one segment per lesson.
struct ContinueLessonCard: View {
    var resources = HomeResourcesUIModel()
    var course: CourseProgress

    private var number: Int { course.current?.number ?? course.completedLessons + 1 }

    var body: some View {
        FrostedCard(padding: 18) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%02d", number)).font(UVVAFont.sans(38, .ultraLight))
                    Text(resources.lessonTotal(course.totalLessons)).font(UVVAFont.sans(10)).foregroundStyle(UVVAColor.cream84)
                }
                Spacer(minLength: 24)
                Text(course.title)
                    .font(UVVAFont.sans(15))
                    .lineLimit(2)
                HStack(spacing: 3) {
                    ForEach(0..<course.totalLessons, id: \.self) { index in
                        Capsule()
                            .fill(UVVAColor.cream.opacity(index < course.completedLessons ? 0.84
                                                          : index == number - 1 ? 0.5 : 0.2))
                            .frame(height: 2)
                    }
                }
                .padding(.top, 10)
                Text(resources.continueLessonCardContinueTitle)
                    .font(UVVAFont.sans(12))
                    .foregroundStyle(UVVAColor.cream84)
                    .padding(.top, 18)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
