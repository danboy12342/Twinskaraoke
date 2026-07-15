import Combine
import Foundation
import SwiftUI

@MainActor
final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    @Published private(set) var favoriteIDs: Set<String> = []
    private var inFlight: Set<String> = []
    private var loaded = false
    private var isLoading = false
    private var lastLoadFailure: Date?
    private var stateGeneration = 0
    private let loadFailureRetryDelay: TimeInterval = 30

    func isFavorite(_ songID: String) -> Bool {
        favoriteIDs.contains(songID)
    }

    func loadIfNeeded() {
        guard !loaded, !isLoading else { return }
        if let lastLoadFailure, Date().timeIntervalSince(lastLoadFailure) < loadFailureRetryDelay {
            return
        }
        Task { @MainActor in await load() }
    }

    func reload() {
        guard !isLoading else { return }
        Task { @MainActor in await load() }
    }

    func clear() {
        stateGeneration += 1
        favoriteIDs = []
        inFlight = []
        loaded = false
        isLoading = false
        lastLoadFailure = nil
    }

    func toggle(songID: String) {
        guard !inFlight.contains(songID) else { return }
        let wasFavorite = favoriteIDs.contains(songID)
        if wasFavorite {
            favoriteIDs.remove(songID)
        } else {
            favoriteIDs.insert(songID)
        }
        inFlight.insert(songID)
        let generation = stateGeneration
        Task {
            let ok = await send(songID: songID)
            await MainActor.run {
                guard stateGeneration == generation else { return }
                inFlight.remove(songID)
                if !ok {
                    if wasFavorite {
                        favoriteIDs.insert(songID)
                    } else {
                        favoriteIDs.remove(songID)
                    }
                }
            }
        }
    }

    private func load() async {
        guard CredentialStore.isAuthenticated else { return }
        let generation = stateGeneration
        isLoading = true
        defer {
            if stateGeneration == generation {
                isLoading = false
            }
        }
        guard let req = try? KaraokeAPIClient.request(path: "/api/user/favorites"),
              let data = try? await KaraokeAPIClient.data(for: req)
        else {
            if stateGeneration == generation {
                lastLoadFailure = Date()
            }
            return
        }
        guard stateGeneration == generation else { return }
        let ids = Self.parseIDs(from: data)
        favoriteIDs = Set(ids)
        loaded = true
        lastLoadFailure = nil
    }

    private func send(songID: String) async -> Bool {
        guard var req = try? KaraokeAPIClient.request(
            pathSegments: ["api", "user", "favorites", songID]
        )
        else { return false }
        req.httpMethod = "PUT"
        return (try? await KaraokeAPIClient.data(for: req)) != nil
    }

    private static func parseIDs(from data: Data) -> [String] {
        if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return arr.compactMap { $0["id"] as? String ?? $0["songId"] as? String }
        }
        if let arr = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return arr
        }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let arr = (obj["favorites"] ?? obj["items"]) as? [[String: Any]]
        {
            return arr.compactMap { $0["id"] as? String ?? $0["songId"] as? String }
        }
        return []
    }
}
