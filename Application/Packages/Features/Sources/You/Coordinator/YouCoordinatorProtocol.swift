@MainActor
public protocol YouCoordinatorProtocol {
    func redoMap()
    func openLearn()
    func openCourse(_ id: String)
    func openCertificate(_ id: String)
    func signOut()
    func accountDeleted()
}
