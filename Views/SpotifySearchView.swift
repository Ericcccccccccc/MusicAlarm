import SwiftUI

struct SpotifySearchView: View {
    @StateObject private var viewModel = SpotifySearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onSongSelected: ((SpotifySong) -> Void)?
    
    init(onSongSelected: ((SpotifySong) -> Void)? = nil) {
        self.onSongSelected = onSongSelected
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchHeaderView
            
            Divider()
            
            contentView
        }
        .background(Color.appBackground)
        .navigationTitle("Search Songs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if onSongSelected != nil {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .onChange(of: viewModel.searchQuery) { _ in
            viewModel.searchSongs()
        }
    }
    
    // MARK: - Header
    
    private var searchHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textSecondary)
                
                TextField("Search for songs...", text: $viewModel.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.searchSongs()
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button("Clear") {
                        viewModel.clearSearch()
                    }
                    .foregroundColor(.textSecondary)
                    .font(.caption)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(Color.appSecondaryBackground)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.searchQuery.isEmpty {
            emptySearchView
        } else if viewModel.showEmptyState {
            noResultsView
        } else if viewModel.showResults {
            searchResultsList
        } else {
            Spacer()
        }
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.appSecondary)
            
            Text("Search for Songs")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            Text("Find the perfect song to wake up to")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "music.quarternote.3")
                .font(.system(size: 60))
                .foregroundColor(.appSecondary)
            
            Text("No Results")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            Text("Try searching with different keywords")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var searchResultsList: some View {
        List(viewModel.searchResults) { song in
            SongRowView(
                song: song,
                onSelect: {
                    handleSongSelection(song)
                }
            )
            .listRowBackground(Color.appBackground)
        }
        .listStyle(.plain)
    }
    
    private func handleSongSelection(_ song: SpotifySong) {
        viewModel.selectSong(song)
        onSongSelected?(song)
        
        if onSongSelected != nil {
            dismiss()
        }
    }
}

// MARK: - Song Row View

struct SongRowView: View {
    let song: SpotifySong
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            albumArtPlaceholder
            
            songInfoView
            
            Spacer()
            
            selectButton
        }
        .padding(.vertical, 8)
    }
    
    private var albumArtPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.appSecondary.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay {
                Image(systemName: "music.note")
                    .foregroundColor(.textSecondary)
                    .font(.title3)
            }
    }
    
    private var songInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(song.title)
                .font(.headline)
                .foregroundColor(.textPrimary)
                .lineLimit(1)
            
            Text(song.artist)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineLimit(1)
            
            Text("Track")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .lineLimit(1)
        }
    }
    
    private var selectButton: some View {
        Button("Select") {
            onSelect()
        }
        .foregroundColor(.spotifyGreen)
        .font(.headline)
        .fontWeight(.medium)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        SpotifySearchView()
    }
}

#Preview("With Selection Handler") {
    NavigationStack {
        SpotifySearchView { song in
            print("Selected: \(song.title)")
        }
    }
}