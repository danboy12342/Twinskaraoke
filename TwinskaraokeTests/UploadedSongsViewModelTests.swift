import Foundation
import Testing
@testable import Twinskaraoke

@Suite("Uploaded songs")
struct UploadedSongsViewModelTests {
    @Test("Duplicate uploaded songs retain API order")
    func duplicateSongsRetainAPIOrder() {
        let first = song(id: "first", title: "First")
        let duplicate = song(id: "first", title: "Duplicate")
        let second = song(id: "second", title: "Second")

        let songs = UploadedSongsViewModel.removingDuplicateSongs([first, duplicate, second])

        #expect(songs.map(\.id) == ["first", "second"])
        #expect(songs.first?.title == "First")
    }

    @Test("Task and URL cancellations use the cancellation path")
    func cancellationErrorsUseCancellationPath() {
        #expect(UploadedSongsViewModel.isCancellationError(CancellationError()))
        #expect(UploadedSongsViewModel.isCancellationError(URLError(.cancelled)))
        #expect(!UploadedSongsViewModel.isCancellationError(URLError(.timedOut)))
    }

    private func song(id: String, title: String) -> Song {
        Song(
            id: id,
            title: title,
            duration: 120,
            absolutePath: "uploads/\(id).m4a",
            cloudflareID: nil,
            coverArt: nil,
            originalArtists: nil,
            coverArtists: nil,
            userUploaded: true
        )
    }
}
