import Foundation
import Testing
@testable import Twinskaraoke

@Suite("Security regressions")
struct SecurityRegressionTests {
    @Test("Safe song IDs keep their existing storage names")
    func safeSongStorageKeyIsBackwardCompatible() {
        #expect(SongStorageKey.component(for: "song_123-ABC") == "song_123-ABC")
    }

    @Test("Unsafe song IDs cannot become paths")
    func unsafeSongStorageKeysAreHashed() {
        let traversal = SongStorageKey.component(for: "../../Library/secret")
        let nested = SongStorageKey.component(for: "artist/song")

        #expect(traversal.hasPrefix("__nksha256_"))
        #expect(!traversal.contains("/"))
        #expect(!traversal.contains(".."))
        #expect(nested.hasPrefix("__nksha256_"))
        #expect(!nested.contains("/"))
        #expect(traversal != nested)
    }

    @Test("Unsafe song storage keys are stable and collision resistant")
    func unsafeSongStorageKeysAreStable() {
        let first = SongStorageKey.component(for: "a/b")
        #expect(first == SongStorageKey.component(for: "a/b"))
        #expect(first != SongStorageKey.component(for: "a_b"))
        #expect(first != SongStorageKey.component(for: "a?b"))
        #expect(first != SongStorageKey.component(for: first))
    }

    @Test("Cache maintenance exclusions use on-disk storage keys")
    func cacheMaintenanceUsesStorageKeys() {
        let unsafeID = "artist/song"
        let storageKeys = SongStorageKey.components(for: [unsafeID, "safe-song"])

        #expect(storageKeys.contains(SongStorageKey.component(for: unsafeID)))
        #expect(storageKeys.contains("safe-song"))
        #expect(!storageKeys.contains(unsafeID))
    }

    @Test("Token exchange accepts supported response shapes")
    func tokenExchangeParsesSupportedResponses() {
        let json = Data(#"{"token":"nk-token"}"#.utf8)
        let alternateJSON = Data(#"{"accessToken":"alternate-token"}"#.utf8)
        let raw = Data(#""raw-token""#.utf8)

        #expect(AuthManager.exchangedToken(from: json) == "nk-token")
        #expect(AuthManager.exchangedToken(from: alternateJSON) == "alternate-token")
        #expect(AuthManager.exchangedToken(from: raw) == "raw-token")
    }

    @Test("Token exchange rejects empty or malformed responses")
    func tokenExchangeRejectsInvalidResponses() {
        #expect(AuthManager.exchangedToken(from: Data()) == nil)
        #expect(AuthManager.exchangedToken(from: Data("{}".utf8)) == nil)
        #expect(AuthManager.exchangedToken(from: Data(#"{"token":""}"#.utf8)) == nil)
    }

    @Test("API path segments are encoded exactly once")
    func apiPathSegmentsAreEncodedExactlyOnce() throws {
        let request = try KaraokeAPIClient.request(
            pathSegments: ["api", "songs", "a b/c%?", "lyrics"]
        )

        #expect(request.url?.absoluteString.contains("/api/songs/a%20b%2Fc%25%3F/lyrics") == true)
        #expect(request.url?.absoluteString.contains("%2520") == false)
    }

    @Test("Only complete credential commits restore a session")
    func incompleteCredentialCommitsAreRejected() {
        #expect(AuthManager.persistedSessionIsComplete(
            token: "token", username: "user", commitMarker: true
        ))
        #expect(AuthManager.persistedSessionIsComplete(
            token: "token", username: "user", commitMarker: nil
        ))
        #expect(!AuthManager.persistedSessionIsComplete(
            token: "token", username: "user", commitMarker: false
        ))
        #expect(!AuthManager.persistedSessionIsComplete(
            token: "token", username: nil, commitMarker: true
        ))
    }

    @Test("Only staged download directories match startup cleanup")
    func pendingDownloadDeletionNamesAreScoped() {
        #expect(DownloadManager.isPendingDeletionDirectoryName(
            "Downloads.pending-delete-123"
        ))
        #expect(!DownloadManager.isPendingDeletionDirectoryName("Downloads"))
        #expect(!DownloadManager.isPendingDeletionDirectoryName("Downloads.backup"))
    }
}
