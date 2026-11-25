import CryptoKit
import Core
import Foundation
import Testing
@testable import CatalogRobot
import Match

struct CatalogMergeTests {
    static let seedWine = CatalogWineData(Wine(
        id: "quinta-do-crasto-reserva-2019", name: "Reserva", producer: "Quinta do Crasto", vintage: 2019,
        type: "Red", origin: "Douro, Portugal", region: "Douro", country: "Portugal", grapes: ["Touriga Nacional"],
        classification: "Douro DOC", profile: PalateMap([.body: 7, .tannin: 6, .fruit: 7]), pairings: ["Lamb"]),
        findIt: "Quinta do Crasto Reserva")

    static func reading(_ user: String, name: String = "Tinto", producer: String = "Casa Nova", vintage: Int? = 2021,
                        type: String = "Red", grapes: [String] = ["Touriga Nacional"], alcohol: Double? = 13.5,
                        minutes: Double = 0) -> Contribution {
        let key = WineKey.make(producer: producer, name: name, vintage: vintage)
        let wine = Wine(id: key, name: name, producer: producer, vintage: vintage, type: type, origin: "Douro, Portugal",
                        region: "Douro", country: "Portugal", grapes: grapes, alcohol: alcohol,
                        profile: PalateMap([.body: 5]))
        let date = Date(timeIntervalSince1970: 1_800_000_000 + minutes * 60)
        return Contribution(wineKey: key, contributor: user, wine: CatalogWineData(wine), created: date, modified: date)
    }

    @Test func oneReader_doesNotMakeAWineKnown() throws {
        let entry = try #require(CatalogMerge.entry([Self.reading("a")], previous: nil))
        #expect(!entry.promoted)
        #expect(CatalogMerge.catalog(seed: [Self.seedWine], entries: [entry.wineKey: entry]).map(\.id)
            == [Self.seedWine.id])
    }

    @Test func twoReaders_makeAWineKnown_withAnEstimatedMap() throws {
        let entry = try #require(CatalogMerge.entry([Self.reading("a"), Self.reading("b", minutes: 5)], previous: nil))
        #expect(entry.promoted)
        let catalog = CatalogMerge.catalog(seed: [Self.seedWine], entries: [entry.wineKey: entry])
        let wine = try #require(catalog.first { $0.id == entry.wineKey })
        #expect(wine.grapes == ["Touriga Nacional"])
        #expect(wine.alcohol == 13.5)
        // Placed from the seed's Douro red, not the reader's guess.
        #expect(wine.map.body == Self.seedWine.map.body)
    }

    @Test func theSameReaderTwice_countsOnce() throws {
        let entry = try #require(CatalogMerge.entry([Self.reading("a"), Self.reading("a", minutes: 9)], previous: nil))
        #expect(entry.contributors == 1)
        #expect(!entry.promoted)
    }

    @Test func aPromotedWine_staysWhenItsReadersLeave() throws {
        let promoted = try #require(CatalogMerge.entry([Self.reading("a"), Self.reading("b")], previous: nil))
        let after = try #require(CatalogMerge.entry([Self.reading("a")], previous: promoted))
        #expect(after.promoted)
    }

    @Test func aSeedWine_gainsOnlyWhatTwoReadersSaw_andKeepsWhatItSays() throws {
        func read(_ user: String, grapes: [String], alcohol: Double) -> Contribution {
            var wine = Self.seedWine
            wine.grapes = grapes
            wine.alcohol = alcohol
            wine.findIt = nil
            return Contribution(wineKey: wine.id, contributor: user, wine: wine, created: .now, modified: .now)
        }
        let entry = try #require(CatalogMerge.entry([
            read("a", grapes: ["Touriga Nacional", "Touriga Franca"], alcohol: 14),
            read("b", grapes: ["touriga franca", "Tinta Roriz"], alcohol: 14)
        ], previous: nil))
        let wine = try #require(CatalogMerge.catalog(seed: [Self.seedWine], entries: [entry.wineKey: entry]).first)
        #expect(wine.grapes == ["Touriga Nacional", "Touriga Franca"])
        #expect(wine.alcohol == 14)
        #expect(wine.name == "Reserva")
        #expect(wine.findIt == "Quinta do Crasto Reserva")
        #expect(wine.map == Self.seedWine.map)
    }

    @Test func aNewWine_withNothingTheSeedKnows_waits() throws {
        // CELLAR-R23a: a made-up grape in a region the seed has no red of gives no map.
        let entry = try #require(CatalogMerge.entry([Self.reading("a", grapes: ["Cabudi"]),
                                                     Self.reading("b", grapes: ["Cabudi"])], previous: nil))
        let seed = [Self.seedWine].map { wine in
            var wine = wine
            wine.region = "Dão"
            return wine
        }
        #expect(CatalogMerge.catalog(seed: seed, entries: [entry.wineKey: entry]).count == 1)
    }

    @Test func theTimeInOak_twoReadersAgreeOn_isKept_andSetsTheMap() throws {
        func oaked(_ user: String, _ aging: OakAging, woods: [String], minutes: Double) -> Contribution {
            // Read at different times: the first reading writes the words.
            var reading = Self.reading(user, minutes: minutes)
            reading.wine.oakAging = aging.rawValue
            reading.wine.oakWoods = woods
            return reading
        }
        let entry = try #require(CatalogMerge.entry([
            oaked("a", .twelveToTwentyFour, woods: ["French oak", "American oak"], minutes: 0),
            oaked("b", .twelveToTwentyFour, woods: ["french oak"], minutes: 1)
        ], previous: nil))
        #expect(entry.facts.oakAging == "12to24")
        #expect(entry.facts.oakWoods == ["French oak"])
        let wine = try #require(CatalogMerge.catalog(seed: [Self.seedWine], entries: [entry.wineKey: entry])
            .first { $0.id == entry.wineKey })
        #expect(wine.map.oak == OakAging.twelveToTwentyFour.oakIntensity)
    }

    @Test func oneReadersUnknownGrapeAndRegion_waitForASecond() throws {
        // CELLAR-R18a: a grape and a region only one reader typed, which the seed does not know, stay out.
        var first = Self.reading("a", grapes: ["Touriga Nacional", "Cabudi"])
        first.wine.region = "Labubu"
        let second = Self.reading("b", grapes: ["Baga"], minutes: 1)
        let entry = try #require(CatalogMerge.entry([first, second], previous: nil))
        let wine = try #require(CatalogMerge.catalog(seed: [Self.seedWine], entries: [entry.wineKey: entry])
            .first { $0.id == entry.wineKey })
        #expect(wine.grapes == ["Touriga Nacional"])
        #expect(wine.region == nil)
    }

    @Test func aRegionTwoReadersType_entersTheWine() throws {
        let readings = [Self.reading("a"), Self.reading("b", minutes: 1)].map { reading in
            var reading = reading
            reading.wine.region = "Labubu"
            return reading
        }
        let entry = try #require(CatalogMerge.entry(readings, previous: nil))
        let wine = try #require(CatalogMerge.catalog(seed: [Self.seedWine], entries: [entry.wineKey: entry])
            .first { $0.id == entry.wineKey })
        #expect(wine.region == "Labubu")
    }

    @Test func aWineOfNoKnownType_waits() throws {
        let entry = try #require(CatalogMerge.entry([Self.reading("a", type: ""), Self.reading("b", type: "")],
                                                    previous: nil))
        #expect(CatalogMerge.catalog(seed: [Self.seedWine], entries: [entry.wineKey: entry]).count == 1)
    }
}

struct ContributionRulesTests {
    @Test func aLabelsFacts_count() {
        #expect(ContributionRules.isValid(CatalogMergeTests.reading("a")))
    }

    @Test func aKeyThatIsNotTheWines_aLinkOrAnAbsurdFact_doNot() {
        var wrongKey = CatalogMergeTests.reading("a")
        wrongKey.wineKey = "something-else"
        var link = CatalogMergeTests.reading("a")
        link.wine.pairings = ["buy at www.example.com"]
        #expect(!ContributionRules.isValid(wrongKey))
        #expect(!ContributionRules.isValid(link))
        #expect(!ContributionRules.isValid(CatalogMergeTests.reading("a", alcohol: 60)))
        #expect(!ContributionRules.isValid(CatalogMergeTests.reading("a", vintage: 1700)))
        #expect(!ContributionRules.isValid(CatalogMergeTests.reading("a", type: "Blue")))
        var oak = CatalogMergeTests.reading("a")
        oak.wine.oakAging = "forever"
        #expect(!ContributionRules.isValid(oak))
    }

    @Test func oneUsersDay_countsUpToTheLimit() {
        let flood = (0..<(ContributionRules.dailyLimit + 20)).map {
            CatalogMergeTests.reading("spammer", name: "Wine \($0)", minutes: Double($0))
        }
        #expect(ContributionRules.accepted(flood + [CatalogMergeTests.reading("other")]).count
            == ContributionRules.dailyLimit + 1)
    }
}

struct CloudKitWebTests {
    static let pem = P256.Signing.PrivateKey().pemRepresentation

    @Test func signature_isOfDateBodyHashAndPath() throws {
        let cloud = try CloudKitWeb(container: "iCloud.app.uvva", environment: "development", keyID: "key",
                                    privateKeyPEM: Self.pem)
        let body = Data(#"{"a":1}"#.utf8)
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let headers = try cloud.signature(for: body, path: "/database/1/x/development/public/records/query", date: date)
        let stamp = try #require(headers["X-Apple-CloudKit-Request-ISO8601Date"])
        #expect(stamp == "2027-01-15T08:00:00Z")
        let message = "\(stamp):\(Data(SHA256.hash(data: body)).base64EncodedString()):/database/1/x/development/public/records/query"
        let encoded = try #require(headers["X-Apple-CloudKit-Request-SignatureV1"])
        let der = try #require(Data(base64Encoded: encoded))
        #expect(cloud.publicKey.isValidSignature(try P256.Signing.ECDSASignature(derRepresentation: der),
                                                 for: Data(message.utf8)))
        #expect(headers["X-Apple-CloudKit-Request-KeyID"] == "key")
    }

    @Test func theKey_isReadHoweverItWasPasted() throws {
        let key = P256.Signing.PrivateKey()
        let pem = key.pemRepresentation
        let lines = pem.components(separatedBy: "\n")
        let body = lines.filter { !$0.hasPrefix("-----") }.joined(separator: "\n")
        for pasted in ["  \(pem)\n", pem.replacingOccurrences(of: "\n", with: " "), body,
                       pem.replacingOccurrences(of: "\n", with: "\r\n")] {
            #expect(CloudKitWeb.privateKey(pasted)?.publicKey.rawRepresentation == key.publicKey.rawRepresentation)
        }
        #expect(CloudKitWeb.describe(key.publicKey.pemRepresentation).contains("public key"))
    }

    @Test func aKeyThatIsNotPEM_isRefusedAtOnce() {
        #expect(throws: CloudKitWebError.self) {
            try CloudKitWeb(container: "c", environment: "development", keyID: "k", privateKeyPEM: "nope")
        }
    }

    @Test func aRecord_readsItsCreatorAndDates() throws {
        let json = try JSONDecoder().decode(JSON.self, from: Data("""
        {"recordName": "abc", "fields": {"wineKey": {"value": "a-wine", "type": "STRING"}},
         "created": {"timestamp": 1800000000000, "userRecordName": "_user"}, "modified": {"timestamp": 1800000060000}}
        """.utf8))
        let record = try #require(WebRecord(json))
        #expect(record.fields["wineKey"]?.string == "a-wine")
        #expect(record.creator == "_user")
        #expect(record.modified == Date(timeIntervalSince1970: 1_800_000_060))
    }
}

struct SnapshotFileTests {
    @Test func theSnapshot_comesBackAsTheAppReadsIt() throws {
        let file = CatalogWinesFile(wines: [CatalogMergeTests.seedWine])
        let compressed = try CatalogRobot.compress(JSONEncoder().encode(file))
        // What `CloudKitCatalogService.decodeWines` does on the phone.
        let json = try (compressed as NSData).decompressed(using: .zlib) as Data
        #expect(try JSONDecoder().decode(CatalogWinesFile.self, from: json).wines == file.wines)
    }
}

/// With `CATALOG_SEED` set (the file `pack_content.py --seed` writes): the robot's catalog of the real seed, and its
/// "Top X%" shares the same as the script's.
struct SeedTests {
    static let seed = ProcessInfo.processInfo.environment["CATALOG_SEED"]

    @Test(.enabled(if: seed != nil))
    func theRealSeed_measuresAsPackContentDoes() throws {
        let wines = try JSONDecoder().decode(CatalogWinesFile.self,
                                             from: Data(contentsOf: URL(fileURLWithPath: Self.seed!))).wines
        let catalog = CatalogMerge.catalog(seed: wines, entries: [:])
        #expect(catalog.count == wines.count)
        let measured = try #require(QualityPrevalence.measure(catalog.map(\.wine)))
        for (name, share) in QualityPrevalence.packed.appellation {
            #expect(abs((measured.appellation[name] ?? 0) - share) < 0.0002, "appellation \(name)")
        }
        for (name, share) in QualityPrevalence.packed.designation {
            #expect(abs((measured.designation[name] ?? 0) - share) < 0.0002, "designation \(name)")
        }
    }
}
