import Combine
import Foundation

@MainActor
final class UploadedSongsViewModel: ObservableObject {
    @Published private(set) var songs: [Song] = []
    @Published private(set) var displayedSongs: [Song] = []
    @Published private(set) var isLoading = false
    @Published private(set) var requiresSignIn = false
    @Published private(set) var loadFailed = false
    @Published var sort: LibrarySongSort = .recentlyAdded {
        didSet { rebuildDisplayedSongs() }
    }
    @Published var searchText = "" {
        didSet { rebuildDisplayedSongs() }
    }

    private var hasLoaded = false
    private var loadTask: Task<Void, Never>?

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        load()
    }

    func refresh() {
        load()
    }

    private func load() {
        loadTask?.cancel()
        loadTask = nil
        loadFailed = false

        guard CredentialStore.token != nil else {
            requiresSignIn = true
            isLoading = false
            hasLoaded = true
            songs = []
            rebuildDisplayedSongs()
            return
        }

        requiresSignIn = false
        isLoading = songs.isEmpty
        loadTask = Task { [weak self] in
            do {
                let loadedSongs = try await KaraokeAPIClient.uploadedSongs()
                try Task.checkCancellation()
                guard let self else { return }

                songs = Self.removingDuplicateSongs(loadedSongs)
                hasLoaded = true
                isLoading = false
                loadTask = nil
                rebuildDisplayedSongs()
            } catch is CancellationError {
                // A newer refresh owns the loading state.
            } catch {
                guard let self else { return }
                DebugLogger.log(
                    "Uploaded songs fetch failed: \(error.localizedDescription)",
                    category: .network
                )
                hasLoaded = true
                isLoading = false
                loadFailed = true
                loadTask = nil
            }
        }
    }

    private func rebuildDisplayedSongs() {
        let sorted: [Song] = switch sort {
        case .recentlyAdded:
            songs
        case .title:
            songs.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .artist:
            songs.sorted {
                $0.displayArtist.localizedStandardCompare($1.displayArtist) == .orderedAscending
            }
        case .duration:
            songs.sorted { $0.duration < $1.duration }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            displayedSongs = sorted
            return
        }
        displayedSongs = sorted.filter { song in
            song.title.localizedCaseInsensitiveContains(query)
                || song.displayArtist.localizedCaseInsensitiveContains(query)
                || song.displayTitle.localizedCaseInsensitiveContains(query)
        }
    }

    nonisolated static func removingDuplicateSongs(_ songs: [Song]) -> [Song] {
        var seenIDs = Set<String>()
        return songs.filter { seenIDs.insert($0.id).inserted }
    }

    deinit {
        loadTask?.cancel()
    }
}
