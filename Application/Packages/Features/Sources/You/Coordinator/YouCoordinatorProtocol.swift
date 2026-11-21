@MainActor
public protocol YouCoordinatorProtocol {
    func redoMap()
    func openLearn()
    func openCourse(_ id: String)
    func openCertificate(_ id: String)
    /// A wine from the Progress map: its note in the Cellar.
    func openWine(_ id: String)
    func signOut()
    func accountDeleted()
}
