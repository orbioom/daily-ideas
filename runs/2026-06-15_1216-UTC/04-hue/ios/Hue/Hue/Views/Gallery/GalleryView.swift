import SwiftUI
import SwiftData

struct GalleryView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Artwork.updatedAt, order: .reverse) private var artworks: [Artwork]
    @Query private var customPalettes: [CustomPalette]

    @State private var route: ColoringRoute?
    @State private var paywall: PaywallReason?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    private var resolvedCustom: [Palette] { customPalettes.map { $0.asPalette() } }

    private var inProgress: [Artwork] {
        artworks.filter { !$0.isCompleted }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    dailySection
                    if !inProgress.isEmpty { continueSection }
                    ForEach(PageCategory.allCases) { category in
                        categorySection(category)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Hue")
            .navigationDestination(item: $route) { route in
                ColoringContainerView(route: route)
            }
            .sheet(item: $paywall) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    // MARK: - Daily

    private var dailySection: some View {
        let page = PageLibrary.dailyPage()
        let unlocked = Pro.isPageUnlocked(page, isPro: isPro)
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Page of the day", systemImage: "sparkles")
            Button {
                open(page)
            } label: {
                HStack(spacing: 16) {
                    PagePreviewThumb(page: page, side: 96, palette: defaultPalette)
                        .overlay(lockBadge(unlocked: unlocked), alignment: .topTrailing)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(page.title)
                            .font(Theme.rounded(20, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("\(page.category.rawValue) • \(page.regionCount) regions")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                        Text("A fresh page picked just for today.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.inkFaint)
                }
                .cardSurface()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Page of the day: \(page.title), \(page.category.rawValue), \(page.regionCount) regions\(unlocked ? "" : ", Pro page")")
        }
    }

    // MARK: - Continue

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Continue", systemImage: "arrow.uturn.backward.circle.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(inProgress) { art in
                        if let page = PageLibrary.page(withID: art.pageID) {
                            Button {
                                openExisting(art, page: page)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ArtworkThumb(artwork: art, page: page, palette: defaultPalette, side: 120)
                                    Text(art.title)
                                        .font(Theme.rounded(14, .medium))
                                        .foregroundStyle(Theme.ink)
                                        .lineLimit(1)
                                    ProgressBadge(filled: art.filledCount, total: page.regionCount)
                                }
                                .frame(width: 120)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Continue \(art.title), \(percent(art, page)) percent filled")
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Category

    private func categorySection(_ category: PageCategory) -> some View {
        let pages = PageLibrary.pages(in: category)
        return Group {
            if !pages.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(category.rawValue, systemImage: category.symbol)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(pages) { page in
                            pageCell(page)
                        }
                    }
                }
            }
        }
    }

    private func pageCell(_ page: ColoringPage) -> some View {
        let unlocked = Pro.isPageUnlocked(page, isPro: isPro)
        return Button {
            open(page)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                PagePreviewThumb(page: page, side: 150, palette: defaultPalette)
                    .overlay(lockBadge(unlocked: unlocked), alignment: .topTrailing)
                Text(page.title)
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(page.regionCount) regions")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(page.title), \(page.category.rawValue), \(page.regionCount) regions\(unlocked ? "" : ", Pro page, locked")")
        .accessibilityHint(unlocked ? "Opens the coloring canvas" : "Shows the Hue Pro unlock")
    }

    // MARK: - Helpers

    private var defaultPalette: Palette {
        PaletteLibrary.resolve(id: settings.defaultPaletteId, custom: resolvedCustom)
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func lockBadge(unlocked: Bool) -> some View {
        if !unlocked {
            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(7)
                .background(Circle().fill(Theme.accent))
                .padding(8)
                .accessibilityHidden(true)
        }
    }

    private func percent(_ art: Artwork, _ page: ColoringPage) -> Int {
        guard page.regionCount > 0 else { return 0 }
        return Int((Double(art.filledCount) / Double(page.regionCount)) * 100)
    }

    private func open(_ page: ColoringPage) {
        if !Pro.isPageUnlocked(page, isPro: isPro) {
            paywall = .premiumPage(page.title)
            return
        }
        // Reuse an existing in-progress artwork for this page if present.
        if let existing = artworks.first(where: { $0.pageID == page.id && !$0.isCompleted }) {
            openExisting(existing, page: page)
        } else {
            // Enforce the free-tier artwork limit when creating something new.
            guard Pro.canCreateArtwork(currentCount: artworks.count, isPro: isPro) else {
                paywall = .artworkLimit
                return
            }
            route = ColoringRoute(pageID: page.id, artworkID: nil)
        }
    }

    private func openExisting(_ art: Artwork, page: ColoringPage) {
        route = ColoringRoute(pageID: page.id, artworkID: art.persistentModelID)
    }
}
