import Combine
import Foundation

/// Tracks the date each playlist was first added to the user's library
/// (whether locally saved or returned by the server). Used to sort the
/// "Recently Added" section by most recent.
@MainActor
final class RecentlyAddedTracker: ObservableObject {
  static let shared = RecentlyAddedTracker()
  private static let storageKey = "nk.recentlyAddedDates.v1"
  @Published private(set) var dates: [String: Date] = [:]
  private init() { load() }
  func date(for id: String) -> Date {
    dates[id] ?? .distantPast
  }
  /// Records `now` for any IDs we haven't seen before. Pass the current
  /// known set on each refresh; only new entries are stamped.
  func registerIfNew(_ ids: [String]) {
    var changed = false
    let now = Date()
    for id in ids where dates[id] == nil {
      dates[id] = now
      changed = true
    }
    if changed { save() }
  }
  /// Bumps the timestamp to now (used when the user explicitly adds a
  /// playlist to their library, so it jumps to the front of the section).
  func bump(_ id: String) {
    dates[id] = Date()
    save()
  }
  private func load() {
    guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
    if let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
      dates = decoded
    }
  }
  private func save() {
    if let data = try? JSONEncoder().encode(dates) {
      UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
  }
}
