import SwiftUI
import SwiftData

/// "On this day", time-ago resurfacing, a daily pick, favorites, and (Pro)
/// month montage export.
struct MemoriesView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Moment.createdAt, order: .reverse) private var moments: [Moment]

    @State private var showPaywall = false
    @State private var showMontage = false

    private var onThisDay: [Memory] { MemoriesEngine.onThisDay(moments: moments) }
    private var timeAgo: [Memory] { MemoriesEngine.timeAgo(moments: moments) }
    private var dailyPick: Memory? { MemoriesEngine.dailyPick(moments: moments) }
    private var favorites: [Moment] { moments.filter { $0.isFavorite } }

    private var hasAnything: Bool {
        !onThisDay.isEmpty || !timeAgo.isEmpty || dailyPick != nil || !favorites.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if !hasAnything {
                    EmptyStateView(
                        symbol: "sparkles",
                        title: "Memories will gather here",
                        message: "As you capture moments, Glimpse resurfaces them — on this day, weeks ago, and your favorites."
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 22) {
                            montageCard
                            if let dailyPick {
                                SectionHeader(title: "Today's glimpse back", subtitle: dailyPick.reason)
                                NavigationLink {
                                    MomentDetailView(moment: dailyPick.moment)
                                } label: {
                                    MomentCard(moment: dailyPick.moment)
                                }
                                .buttonStyle(.plain)
                            }
                            if !onThisDay.isEmpty {
                                memorySection(title: "On this day", subtitle: "From earlier years", memories: onThisDay)
                            }
                            if !timeAgo.isEmpty {
                                memorySection(title: "A little while ago", subtitle: "Resurfaced moments", memories: timeAgo)
                            }
                            if !favorites.isEmpty {
                                favoritesSection
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Memories")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showMontage) {
                MontageView(moments: moments)
            }
        }
    }

    private var montageCard: some View {
        Button {
            if isPro { showMontage = true } else { showPaywall = true }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.heroGradient)
                    Image(systemName: "rectangle.grid.3x2.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Month montage")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(isPro ? "Render a mosaic of your month to share" : "Pro: a mosaic of your month to share")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: isPro ? "chevron.right" : "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(14)
            .cardSurface()
        }
        .buttonStyle(.plain)
    }

    private func memorySection(title: String, subtitle: String, memories: [Memory]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, subtitle: subtitle)
            ForEach(memories) { memory in
                VStack(alignment: .leading, spacing: 6) {
                    Text(memory.reason.uppercased())
                        .font(Theme.rounded(11, .bold))
                        .foregroundStyle(Theme.accent)
                    NavigationLink {
                        MomentDetailView(moment: memory.moment)
                    } label: {
                        MomentCard(moment: memory.moment)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Favorites", subtitle: "\(favorites.count) saved")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favorites) { moment in
                        NavigationLink {
                            MomentDetailView(moment: moment)
                        } label: {
                            FavoriteThumb(moment: moment)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct FavoriteThumb: View {
    let moment: Moment
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            MomentImageView(filename: moment.imageFilename, pointSize: 160, cornerRadius: Theme.tileRadius)
                .frame(width: 140, height: 140)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(.black.opacity(0.3), in: Circle())
                        .padding(6)
                        .accessibilityHidden(true)
                }
            MoodDot(mood: moment.mood, size: 8)
        }
        .frame(width: 140)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Favorite, mood \(moment.mood.label)")
    }
}
