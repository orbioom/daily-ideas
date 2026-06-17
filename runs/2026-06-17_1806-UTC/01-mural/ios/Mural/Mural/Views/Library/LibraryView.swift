import SwiftUI
import SwiftData

struct LibraryView: View {
    @Binding var selectedTab: Int
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \SavedWallpaper.createdAt, order: .reverse) private var wallpapers: [SavedWallpaper]
    @State private var showFavoritesOnly = false
    @State private var showPaywall = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var filtered: [SavedWallpaper] {
        showFavoritesOnly ? wallpapers.filter { $0.isFavorite } : wallpapers
    }

    var body: some View {
        NavigationStack {
            Group {
                if wallpapers.isEmpty {
                    EmptyStateView(
                        icon: "square.stack.3d.up.slash",
                        title: "Your library is empty",
                        message: "Design something in the Studio and save it here. Every wallpaper stays editable.",
                        actionTitle: "Open Studio",
                        action: { selectedTab = 0 }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filtered.isEmpty {
                    EmptyStateView(
                        icon: "heart.slash",
                        title: "No favorites yet",
                        message: "Tap the heart on any wallpaper to keep it here.",
                        actionTitle: "Show all",
                        action: { showFavoritesOnly = false }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    grid
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.selection(enabled: settings.hapticsEnabled)
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundStyle(showFavoritesOnly ? Theme.bad : Theme.accent)
                    }
                    .accessibilityLabel(showFavoritesOnly ? "Showing favorites" : "Show favorites only")
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .navigationDestination(for: SavedWallpaper.self) { item in
                WallpaperDetailView(wallpaper: item, selectedTab: $selectedTab)
            }
        }
    }

    private var grid: some View {
        ScrollView {
            if !isPro {
                capacityBanner
            }
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(filtered) { item in
                    NavigationLink(value: item) {
                        thumbnail(item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private var capacityBanner: some View {
        let count = wallpapers.count
        return HStack(spacing: 10) {
            Image(systemName: "tray.full.fill")
                .foregroundStyle(Theme.accent)
            Text("\(count) of \(Pro.freeLibraryLimit) free saves used")
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Button("Go Pro") { showPaywall = true }
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.subtleCardGradient, in: RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
    }

    private func thumbnail(_ item: SavedWallpaper) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                WallpaperPreview(spec: item.spec, aspect: AspectRatioOption.phone.ratio, cornerRadius: Theme.radius)
                if item.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(8)
                        .accessibilityHidden(true)
                }
            }
            Text(item.name)
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.spec.style.displayName)\(item.isFavorite ? ", favorite" : "")")
        .accessibilityHint("Opens wallpaper details")
    }
}
