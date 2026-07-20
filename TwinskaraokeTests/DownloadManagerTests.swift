import Foundation
import Testing
@testable import Twinskaraoke

@Suite("Download validation")
struct DownloadManagerTests {
    @Test("Fallback artwork selection is stable and bounded")
    func fallbackArtworkSelectionIsDeterministic() {
        let first = FallbackArtProvider.fallbackIndex(for: "song-without-art", count: 12)
        let second = FallbackArtProvider.fallbackIndex(for: "song-without-art", count: 12)
        #expect(first == second)
        #expect((0 ..< 12).contains(first))
        #expect(FallbackArtProvider.fallbackIndex(for: "song", count: 0) == 0)
    }

    @Test("Startup cleanup only removes partial files from before launch")
    func startupCleanupPreservesCurrentPartialFiles() {
        let cutoff = Date()
        #expect(
            AudioCacheStore.shouldRemovePartialFile(
                named: "main.mp3.partial",
                modifiedAt: cutoff.addingTimeInterval(-1),
                createdBefore: cutoff
            )
        )
        #expect(
            !AudioCacheStore.shouldRemovePartialFile(
                named: "main.mp3.partial",
                modifiedAt: cutoff.addingTimeInterval(1),
                createdBefore: cutoff
            )
        )
        #expect(
            !AudioCacheStore.shouldRemovePartialFile(
                named: "main.mp3",
                modifiedAt: cutoff.addingTimeInterval(-1),
                createdBefore: cutoff
            )
        )
    }

    @Test("Only uncompressed stem formats are selected for compression")
    func cacheCompressionSkipsAlreadyCompressedAudio() {
        #expect(AudioCacheStore.shouldCompressPlayableFile(at: URL(fileURLWithPath: "/tmp/vocals.wav")))
        #expect(!AudioCacheStore.shouldCompressPlayableFile(at: URL(fileURLWithPath: "/tmp/main.mp3")))
        #expect(!AudioCacheStore.shouldCompressPlayableFile(at: URL(fileURLWithPath: "/tmp/main.m4a")))
        #expect(!AudioCacheStore.shouldCompressPlayableFile(at: URL(fileURLWithPath: "/tmp/vocals.wav.nkz")))
    }

    @Test("Catalog rounding and longer files are accepted")
    func durationAcceptsHealthyFiles() {
        #expect(
            DownloadManager.durationAppearsComplete(
                actualDuration: 198,
                expectedDuration: 200
            )
        )
        #expect(
            DownloadManager.durationAppearsComplete(
                actualDuration: 205,
                expectedDuration: 200
            )
        )
        #expect(
            DownloadManager.durationAppearsComplete(
                actualDuration: 180,
                expectedDuration: nil
            )
        )
    }

    @Test("Truncated and unreadable files are rejected")
    func durationRejectsBrokenFiles() {
        #expect(
            !DownloadManager.durationAppearsComplete(
                actualDuration: 120,
                expectedDuration: 200
            )
        )
        #expect(
            !DownloadManager.durationAppearsComplete(
                actualDuration: 0,
                expectedDuration: 200
            )
        )
    }

    @Test("Audio cache access does not mutate persistent download files")
    func cacheTouchLeavesExternalFilesUnchanged() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("main.mp3")
        #expect(FileManager.default.createFile(atPath: fileURL.path, contents: Data([0])))

        let originalDate = Date(timeIntervalSince1970: 946_684_800)
        try FileManager.default.setAttributes(
            [.modificationDate: originalDate],
            ofItemAtPath: fileURL.path
        )

        AudioCacheStore.touch(fileURL)

        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        #expect(attributes[.modificationDate] as? Date == originalDate)
    }
}
