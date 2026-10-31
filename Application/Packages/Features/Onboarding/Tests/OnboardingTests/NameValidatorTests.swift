import Testing
@testable import Onboarding

struct NameValidatorTests {
    // MARK: ONB-R15, R16 · Nome

    @Test func ONB_R15_oneLetter_isInvalid() {
        #expect(!NameValidator.isValid("E"))
        #expect(!NameValidator.isValid("  E  "))
        #expect(!NameValidator.isValid(""))
    }

    @Test func ONB_R15_twoLetters_isValid() {
        #expect(NameValidator.isValid("Al"))
    }

    @Test func ONB_R16_savedWithoutTheSpacesAtTheEnds() {
        #expect(NameValidator.normalized("  Elisa ") == "Elisa")
    }
}
