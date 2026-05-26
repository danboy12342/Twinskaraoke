import Foundation

struct FallbackArt {
  let url: URL
  let artistName: String?
  let artistLink: String?
}

final class FallbackArtProvider: @unchecked Sendable {
  static let shared = FallbackArtProvider()

  private var items: [FallbackArtItem] = []
  private var cache: [String: FallbackArt] = [:]
  private let lock = NSLock()
  private let persistKey = "nk.fallbackArtCache"

  private static let defaultURL = URL(
    string: "\(StorageHost.images)/WxURxyML82UkE7gY-PiBKw/277232b2-e00e-426b-ffb8-bb8664a73600/quality=95"
  )!

  private init() {
    loadPersistedCache()
    fetch()
  }

  func art(for id: String) -> FallbackArt {
    lock.lock()
    if let cached = cache[id] {
      lock.unlock()
      return cached
    }
    let result: FallbackArt
    if items.isEmpty {
      if let persisted = loadPersistedEntry(for: id) {
        cache[id] = persisted
        lock.unlock()
        return persisted
      }
      result = FallbackArt(url: Self.defaultURL, artistName: nil, artistLink: nil)
    } else {
      let index = Self.stableHash(id) % items.count
      let item = items[index]
      result = FallbackArt(url: item.url, artistName: item.artistName, artistLink: item.artistLink)
      persistEntry(id: id, url: item.url, artistName: item.artistName, artistLink: item.artistLink)
    }
    cache[id] = result
    lock.unlock()
    return result
  }

  func url(for id: String) -> URL {
    art(for: id).url
  }

  func resetBindings() {
    lock.lock()
    cache.removeAll()
    lock.unlock()
    UserDefaults.standard.removeObject(forKey: persistKey)
  }

  var randomURL: URL {
    lock.lock()
    let cached = items
    lock.unlock()
    guard !cached.isEmpty else { return Self.defaultURL }
    return cached[Int.random(in: 0..<cached.count)].url
  }

  private static func stableHash(_ string: String) -> Int {
    var hash: UInt64 = 5381
    for byte in string.utf8 {
      hash = hash &* 33 &+ UInt64(byte)
    }
    return Int(hash % UInt64(Int.max))
  }

  private func loadPersistedCache() {
    guard let dict = UserDefaults.standard.dictionary(forKey: persistKey) as? [String: [String: String]] else { return }
    for (id, entry) in dict {
      guard let urlStr = entry["url"], let url = URL(string: urlStr) else { continue }
      cache[id] = FallbackArt(url: url, artistName: entry["artistName"], artistLink: entry["artistLink"])
    }
  }

  private func loadPersistedEntry(for id: String) -> FallbackArt? {
    guard let dict = UserDefaults.standard.dictionary(forKey: persistKey) as? [String: [String: String]],
      let entry = dict[id],
      let urlStr = entry["url"],
      let url = URL(string: urlStr)
    else { return nil }
    return FallbackArt(url: url, artistName: entry["artistName"], artistLink: entry["artistLink"])
  }

  private func persistEntry(id: String, url: URL, artistName: String?, artistLink: String?) {
    var dict = (UserDefaults.standard.dictionary(forKey: persistKey) as? [String: [String: String]]) ?? [:]
    var entry: [String: String] = ["url": url.absoluteString]
    if let name = artistName { entry["artistName"] = name }
    if let link = artistLink { entry["artistLink"] = link }
    dict[id] = entry
    UserDefaults.standard.set(dict, forKey: persistKey)
  }

  private func fetch() {
    let urlString = "\(StorageHost.api)/api/media/gallery?page=1&pageSize=48&search=&tag=Twins&sort=newest&hideWebM=false"
    guard let url = URL(string: urlString) else { return }
    var request = URLRequest(url: url)
    GuestIdentity.applyIfNeeded(to: &request)
    URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
      guard let self, let data else { return }
      guard let response = try? JSONDecoder().decode(GalleryResponse.self, from: data) else { return }
      let parsed = response.items.compactMap { item -> FallbackArtItem? in
        guard let path = item.absolutePath else { return nil }
        guard let url = URL(string: "\(StorageHost.images)\(path)/quality=95") else { return nil }
        return FallbackArtItem(url: url, artistName: item.artist?.name, artistLink: item.artist?.socialLink)
      }
      self.lock.lock()
      self.items = parsed
      self.lock.unlock()
    }.resume()
  }
}

private struct FallbackArtItem {
  let url: URL
  let artistName: String?
  let artistLink: String?
}

private struct GalleryResponse: Decodable {
  let items: [GalleryItem]
}

private struct GalleryItem: Decodable {
  let absolutePath: String?
  let artist: GalleryArtistInfo?
}

private struct GalleryArtistInfo: Decodable {
  let name: String?
  let socialLink: String?
}
