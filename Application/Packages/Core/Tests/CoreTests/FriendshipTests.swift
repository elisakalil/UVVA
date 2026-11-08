import Foundation
import Testing
@testable import Core

struct FriendshipTests {
    let me = "elisa"
    let t0 = Date(timeIntervalSince1970: 1_000)
    let t1 = Date(timeIntervalSince1970: 2_000)

    func request(_ from: String, _ to: String, at date: Date? = nil) -> FriendRequestRecord {
        FriendRequestRecord(from: from, to: to, createdAt: date ?? t0)
    }

    // MARK: FRI-R08 · Add envia um pedido

    @Test func FRI_R08_sentRequest_isRequestedAndNotAFriend() {
        let result = Friendship.resolve(user: me, sent: [request(me, "sofia")], received: [])
        #expect(result.outgoing == [request(me, "sofia")])
        #expect(result.friends.isEmpty)
        #expect(result.incoming.isEmpty)
    }

    // MARK: FRI-R08a · Receber um pedido

    @Test func FRI_R08a_receivedRequest_isIncoming() {
        let result = Friendship.resolve(user: me, sent: [], received: [request("marina", me)])
        #expect(result.incoming == [request("marina", me)])
        #expect(result.friends.isEmpty)
    }

    @Test func FRI_R08a_accepting_sendsTheRequestBack_andBothAreFriends() {
        let theirs = request("marina", me, at: t0)
        let mine = request(me, "marina", at: t1)
        let result = Friendship.resolve(user: me, sent: [mine], received: [theirs])
        #expect(result.friends == ["marina": t1])
        #expect(result.incoming.isEmpty)
        #expect(result.outgoing.isEmpty)
    }

    @Test func FRI_R08a_declined_isHiddenFromTheUser_only() {
        let result = Friendship.resolve(user: me, sent: [], received: [request("marina", me)], declined: ["marina"])
        #expect(result.incoming.isEmpty)
        #expect(result.friends.isEmpty)
        // Marina still sees "Requested": she is not told.
        let hers = Friendship.resolve(user: "marina", sent: [request("marina", me)], received: [])
        #expect(hers.outgoing.count == 1)
    }

    @Test func FRI_R08a_declinedThenAddedBack_areFriends() {
        let result = Friendship.resolve(user: me, sent: [request(me, "marina")], received: [request("marina", me)],
                                        declined: ["marina"])
        #expect(result.friends.keys.contains("marina"))
    }

    // MARK: FRI-R08b · Os dois enviaram

    @Test func FRI_R08b_crossedRequests_areFriendsWithoutAccepting() {
        let a = Friendship.resolve(user: "a", sent: [request("a", "b")], received: [request("b", "a")])
        let b = Friendship.resolve(user: "b", sent: [request("b", "a")], received: [request("a", "b")])
        #expect(a.friends.keys.contains("b"))
        #expect(b.friends.keys.contains("a"))
    }

    // MARK: D4 · Remover

    @Test func D4_friendTookTheirRequestBack_myRequestLapses() {
        let result = Friendship.resolve(user: me, sent: [request(me, "rui")], received: [], knownFriends: ["rui"])
        #expect(result.lapsed == [request(me, "rui")])
        #expect(result.outgoing.isEmpty)
        #expect(result.friends.isEmpty)
    }

    // MARK: Robustez

    @Test func ignoresRecordsThatAreNotTheUsers_andSelfRequests() {
        let result = Friendship.resolve(user: me, sent: [request("x", "y"), request(me, me)],
                                        received: [request("y", "x"), request(me, me)])
        #expect(result == Friendship())
    }

    @Test func incoming_newestFirst() {
        let result = Friendship.resolve(user: me, sent: [],
                                        received: [request("a", me, at: t0), request("b", me, at: t1)])
        #expect(result.incoming.map(\.from) == ["b", "a"])
    }
}
