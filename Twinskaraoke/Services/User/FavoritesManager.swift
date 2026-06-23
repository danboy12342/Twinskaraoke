import Combine
import Foundation
import SwiftUI

@MainActor
final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    @Published private(set) var favoriteIDs: Set<String> = []
    private var inFlight: Set<String> = []
    private var loaded = false

    func isFavorite(_ songID: String) -> Bool {
        favoriteIDs.contains(songID)
    }

    func loadIfNeeded() {
        reload()
    }

    func reload() {
        Task { await load() }
    }

    func clear() {
        favoriteIDs = []
        loaded = false
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
        Task {
            let ok = await send(songID: songID)
            await MainActor.run {
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
        guard UserDefaults.standard.string(forKey: "nk.token") != nil else { return }
        guard let req = try? KaraokeAPIClient.request(path: "/api/user/favorites"),
              let data = try? await KaraokeAPIClient.data(for: req)
        else { return }
        let ids = Self.parseIDs(from: data)
        await MainActor.run { self.favoriteIDs = Set(ids) }
    }

    private func send(songID: String) async -> Bool {
        let encoded = songID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? songID
        guard var req = try? KaraokeAPIClient.request(path: "/api/user/favorites/\(encoded)")
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
