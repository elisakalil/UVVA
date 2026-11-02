import Testing
@testable import Storage

struct ContactKeyTests {
    @Test func samePhone_sameKey_andTheKeyHidesThePhone() {
        let key = ContactKey.make(phone: "+351912345678")
        #expect(key == ContactKey.make(phone: "+351912345678"))
        #expect(key != ContactKey.make(phone: "+351912345679"))
        #expect(key.count == 64)
        #expect(!key.contains("912345678"))
    }
}
