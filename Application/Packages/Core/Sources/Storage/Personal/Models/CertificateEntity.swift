import Foundation
import SwiftData

/// A course finished, in the Personal store (ARCHITECTURE §2.1, `Certificate`: courseId, date).
@Model
public final class CertificateEntity {
    public var courseId = ""
    public var date = Date.distantPast

    init(courseId: String, date: Date) {
        self.courseId = courseId
        self.date = date
    }
}
