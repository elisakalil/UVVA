import Testing
@testable import Core

struct PhoneNumberTests {
    let portugal = PhoneCountries.country(region: "PT")!
    let uk = PhoneCountries.country(region: "GB")!
    let brazil = PhoneCountries.country(region: "BR")!

    // MARK: ONB-R05, ONB-R07 · Telefone digitado

    @Test func ONB_R07_portugueseNumber_becomesE164() {
        #expect(PhoneNumber.e164(national: "912345678", country: portugal) == "+351912345678")
    }

    @Test func ONB_R05_tooShortOrTooLong_isInvalid() {
        #expect(PhoneNumber.e164(national: "91234567", country: portugal) == nil)
        #expect(PhoneNumber.e164(national: "9123456789", country: portugal) == nil)
    }

    @Test func D8_trunkPrefix_isDropped() {
        #expect(PhoneNumber.e164(national: "07911123456", country: uk) == "+447911123456")
        #expect(PhoneNumber.e164(national: "7911123456", country: uk) == "+447911123456")
    }

    @Test func D8_brazil_acceptsTenAndElevenDigits() {
        #expect(PhoneNumber.e164(national: "11987654321", country: brazil) == "+5511987654321")
        #expect(PhoneNumber.e164(national: "1133334444", country: brazil) == "+551133334444")
    }

    // MARK: ARCHITECTURE §4.4 · Números da agenda

    @Test func contacts_writtenEveryWay_reachTheSameKey() {
        let expected = "+351912345678"
        for raw in ["+351 912 345 678", "00351912345678", "912 345 678", "+351-912-345-678"] {
            #expect(PhoneNumber.e164(contact: raw, home: portugal) == expected, "\(raw)")
        }
    }

    @Test func contacts_foreignNumbers_keepTheirCountry() {
        #expect(PhoneNumber.e164(contact: "+44 7911 123456", home: portugal) == "+447911123456")
        #expect(PhoneNumber.e164(contact: "+1 (415) 555-0100", home: portugal) == "+14155550100")
    }

    @Test func contacts_localNumberAbroad_usesTheHomeCountry() {
        #expect(PhoneNumber.e164(contact: "07911 123456", home: uk) == "+447911123456")
    }

    @Test func grouped_inThrees() {
        #expect(PhoneNumber.grouped("912345678") == "912 345 678")
        #expect(PhoneNumber.grouped("9123") == "912 3")
    }
}
