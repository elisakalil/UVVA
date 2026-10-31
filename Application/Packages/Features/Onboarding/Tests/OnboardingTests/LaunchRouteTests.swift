import Core
import Testing
@testable import Onboarding

struct LaunchRouteTests {
    let profile = Profile(id: "u1", authProvider: .apple, authUserID: "a1", firstName: "Elisa", phone: nil)

    // MARK: ONB-R02 · Depois do Splash

    @Test func ONB_R02_noSession_opensTheWelcome() {
        #expect(LaunchRoute.resolve(profile: nil, hasMap: false) == .welcome)
    }

    @Test func ONB_R02_sessionWithoutMap_opensTheQuiz() {
        #expect(LaunchRoute.resolve(profile: profile, hasMap: false) == .quiz(firstName: "Elisa"))
    }

    @Test func ONB_R02_sessionWithMap_opensHome() {
        #expect(LaunchRoute.resolve(profile: profile, hasMap: true) == .home)
    }
}
