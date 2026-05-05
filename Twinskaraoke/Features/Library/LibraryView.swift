import SwiftUI

struct LibraryView: View {
  @StateObject var viewModel = PlaylistsViewModel()
  let cols = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
  var body: some View {
    NavigationStack {
      List {
        Section {
          NavigationLink {
            PlaylistsGridScreen(viewModel: viewModel)
          } label: {
            LibraryRow(icon: "music.note.list", color: .appAccent, title: "Playlists")
          }
          NavigationLink {
            ArtistsView()
          } label: {
            LibraryRow(icon: "music.mic", color: .appAccent, title: "Artists")
          }
          NavigationLink {
            LibraryPlaceholderView(title: "Albums", systemImage: "square.stack")
          } label: {
            LibraryRow(icon: "square.stack", color: .appAccent, title: "Albums")
          }
          NavigationLink {
            LibraryPlaceholderView(title: "Songs", systemImage: "music.note")
          } label: {
            LibraryRow(icon: "music.note", color: .appAccent, title: "Songs")
          }
          NavigationLink {
            LibraryPlaceholderView(title: "Made For You", systemImage: "sparkles")
          } label: {
            LibraryRow(icon: "sparkles", color: .appAccent, title: "Made For You")
          }
          NavigationLink {
            VideoGalleryView()
          } label: {
            LibraryRow(icon: "play.rectangle", color: .appAccent, title: "Video Gallery")
          }
          NavigationLink {
            ArtGalleryView()
          } label: {
            LibraryRow(icon: "paintpalette", color: .appAccent, title: "Art Gallery")
          }
          NavigationLink {
            LibraryPlaceholderView(title: "Genres", systemImage: "guitars")
          } label: {
            LibraryRow(icon: "guitars", color: .appAccent, title: "Genres")
          }
          NavigationLink {
            LibraryPlaceholderView(title: "Composers", systemImage: "music.quarternote.3")
          } label: {
            LibraryRow(icon: "music.quarternote.3", color: .appAccent, title: "Composers")
          }
          NavigationLink {
            LibraryPlaceholderView(title: "Compilations", systemImage: "rectangle.stack")
          } label: {
            LibraryRow(icon: "rectangle.stack", color: .appAccent, title: "Compilations")
          }
          NavigationLink {
            DownloadedSongsView()
          } label: {
            LibraryRow(icon: "arrow.down.circle.fill", color: .appAccent, title: "Downloaded")
          }
          NavigationLink {
            RandomSongsView()
          } label: {
            LibraryRow(icon: "shuffle", color: .appAccent, title: "Random Songs")
          }
        }
        Section {
          RecentlyAddedCarousel(viewModel: viewModel)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 12, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listSectionSpacing(.compact)
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Library")
      .onAppear {
        viewModel.fetchPlaylists()
        viewModel.fetchFavoriteSongs()
      }
    }
  }
}

private struct RecentlyAddedCarousel: View {
  @ObservedObject var viewModel: PlaylistsViewModel
  @ObservedObject var savedStore: SavedPlaylistsStore = .shared
  @ObservedObject var addedTracker: RecentlyAddedTracker = .shared
  @State private var showAll = false
  private let rows = [
    GridItem(.fixed(220), spacing: 16),
    GridItem(.fixed(220), spacing: 16),
  ]
  var body: some View {
    let recents = viewModel.recentlyAddedPlaylists(saved: savedStore.playlists)
    VStack(alignment: .leading, spacing: 12) {
      Button {
        showAll = true
      } label: {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("Recently Added")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.primary)
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
          Spacer()
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 12)
      .background(
        NavigationLink(destination: RecentlyAddedView(viewModel: viewModel), isActive: $showAll) {
          EmptyView()
        }
        .opacity(0)
      )
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHGrid(rows: rows, spacing: 16) {
          ForEach(recents) { playlist in
            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
              VStack(alignment: .leading, spacing: 6) {
                PlaylistArtwork(playlist: playlist, cornerRadius: 10)
                  .frame(width: 170, height: 170)
                  .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(playlist.name)
                  .font(.system(size: 15, weight: .semibold))
                  .foregroundColor(.primary)
                  .lineLimit(1)
                Text("\(playlist.songCount) songs")
                  .font(.system(size: 12))
                  .foregroundColor(.secondary)
                  .lineLimit(1)
              }
              .frame(width: 170)
            }
            .buttonStyle(PressableButtonStyle())
          }
        }
        .padding(.horizontal, 12)
      }
    }
  }
}

private struct RecentlyAddedTile: View {
  let playlist: Playlist
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      PlaylistArtwork(playlist: playlist, cornerRadius: 6)
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
      Text(playlist.name)
        .font(.system(size: 15, weight: .regular))
        .foregroundColor(.primary)
        .lineLimit(1)
        .padding(.top, 2)
      Text(playlist.isFavorites ? "Playlist" : "Playlist")
        .font(.system(size: 13))
        .foregroundColor(.secondary)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct RecentlyAddedSection: View {
  @ObservedObject var viewModel: PlaylistsViewModel
  @ObservedObject var savedStore: SavedPlaylistsStore = .shared
  @ObservedObject var addedTracker: RecentlyAddedTracker = .shared
  let cols: [GridItem]
  var body: some View {
    let recents = viewModel.recentlyAddedPlaylists(saved: savedStore.playlists)
    VStack(alignment: .leading, spacing: 16) {
      NavigationLink {
        RecentlyAddedView(viewModel: viewModel)
      } label: {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("Recently Added")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.primary)
          Spacer()
          Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      if viewModel.isLoading && recents.isEmpty {
        LoadingIndicator(size: 48)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 40)
      } else if recents.isEmpty {
        Text("Playlists you add will appear here.")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 12)
      } else {
        LazyVGrid(columns: cols, spacing: 18) {
          ForEach(recents.prefix(8)) { playlist in
            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
              PlaylistGridCell(playlist: playlist)
            }
            .buttonStyle(PressableButtonStyle())
          }
        }
      }
    }
  }
}

struct RecentlyAddedView: View {
  @ObservedObject var viewModel: PlaylistsViewModel
  @ObservedObject var savedStore: SavedPlaylistsStore = .shared
  @ObservedObject var addedTracker: RecentlyAddedTracker = .shared
  private let cols = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
  var body: some View {
    let recents = viewModel.recentlyAddedPlaylists(saved: savedStore.playlists)
    ScrollView {
      if recents.isEmpty {
        VStack(spacing: 16) {
          Image(systemName: "clock")
            .font(.system(size: 48))
            .foregroundColor(.secondary)
          Text("Nothing here yet")
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
      } else {
        LazyVGrid(columns: cols, spacing: 18) {
          ForEach(recents) { playlist in
            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
              PlaylistGridCell(playlist: playlist)
            }
            .buttonStyle(PressableButtonStyle())
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
    }
    .navigationTitle("Recently Added")
    .navigationBarTitleDisplayMode(.large)
  }
}

struct LibraryRow: View {
  let icon: String
  let color: Color
  let title: String
  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: icon)
        .font(.system(size: 20, weight: .medium))
        .foregroundColor(color)
        .frame(width: 28)
      Text(title)
        .font(.system(size: 17))
      Spacer()
    }
    .padding(.vertical, 4)
  }
}

struct PlaylistListRow: View {
  let playlist: Playlist
  var body: some View {
    HStack(spacing: 12) {
      PlaylistArtwork(playlist: playlist, cornerRadius: 6)
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
      VStack(alignment: .leading, spacing: 2) {
        Text(playlist.name)
          .font(.system(size: 15, weight: .medium))
          .lineLimit(1)
        Text("\(playlist.songCount) songs")
          .font(.system(size: 12))
          .foregroundColor(.secondary)
      }
      Spacer()
    }
    .padding(.vertical, 2)
  }
}

struct PlaylistsGridScreen: View {
  @ObservedObject var viewModel: PlaylistsViewModel
  @ObservedObject var savedStore: SavedPlaylistsStore = .shared
  let cols = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
  var body: some View {
    let all = viewModel.allPlaylists(saved: savedStore.playlists)
    ScrollView {
      Group {
        if viewModel.isLoading && all.isEmpty {
          PlaylistsSkeletonView(cols: cols)
        } else if all.isEmpty {
          VStack(spacing: 16) {
            Image(systemName: "music.note.list")
              .font(.system(size: 48))
              .foregroundColor(.secondary)
            Text("No playlists yet")
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.top, 80)
        } else {
          LazyVGrid(columns: cols, spacing: 16) {
            ForEach(all) { playlist in
              NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                PlaylistGridCell(playlist: playlist)
              }
              .buttonStyle(PressableButtonStyle())
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
      }
    }
    .navigationTitle("Playlists")
  }
}

struct PlaylistGridCell: View {
  let playlist: Playlist
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      PlaylistArtwork(playlist: playlist, cornerRadius: 10)
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
      Text(playlist.name)
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(.primary)
        .lineLimit(1)
      Text("\(playlist.songCount) songs")
        .font(.system(size: 12))
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct LibraryPlaceholderView: View {
  let title: String
  let systemImage: String
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: systemImage)
        .font(.system(size: 48))
        .foregroundColor(.secondary)
      Text("No \(title) Yet")
        .font(.system(size: 18, weight: .semibold))
      Text("Items you add will appear here.")
        .font(.system(size: 14))
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct PlaylistsSkeletonView: View {
  let cols: [GridItem]
  var body: some View {
    LoadingIndicator(size: 64)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(.top, 80)
  }
}
