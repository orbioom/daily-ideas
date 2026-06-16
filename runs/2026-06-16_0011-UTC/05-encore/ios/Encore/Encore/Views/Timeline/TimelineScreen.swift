import SwiftUI
import SwiftData

/// Home screen: attended shows reverse-chronological grouped by year, with a live
/// countdown banner for the next upcoming wishlist show.
struct TimelineScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Concert.date, order: .reverse) private var concerts: [Concert]
    @Query private var allGenres: [Genre]

    @State private var showEditor = false
    @State private var paywallReason: PaywallReason?
    @State private var seeded = false

    private var attended: [Concert] {
        concerts.filter { $0.status == .attended }
    }

    private var nextUpcoming: Concert? {
        concerts
            .filter { $0.isUpcoming }
            .min { $0.date < $1.date }
    }

    /// Years (desc) → shows in that year (already date-desc from the query).
    private var grouped: [(year: Int, shows: [Concert])] {
        let dict = Dictionary(grouping: attended) { $0.year }
        return dict.keys.sorted(by: >).map { year in
            (year, dict[year] ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.bg.ignoresSafeArea()
                content
                addButton
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { presentEditor() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log a show")
                }
            }
            .navigationDestination(for: Concert.self) { c in
                ConcertDetailView(concert: c, allGenres: allGenres)
            }
            .sheet(isPresented: $showEditor) {
                ConcertEditorView(concert: nil, allGenres: allGenres)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
        .task {
            guard !seeded else { return }
            SeedData.seedIfNeeded(context: context)
            seeded = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if attended.isEmpty && nextUpcoming == nil {
            EmptyStateView(symbol: "ticket",
                           title: "Your timeline is empty",
                           message: "Log the first show you've been to and Encore starts building your concert history — setlist, support acts, and all.",
                           actionTitle: "Log a show") { presentEditor() }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
                    if settings.showCountdowns, let next = nextUpcoming {
                        UpcomingBanner(concert: next)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    if attended.isEmpty {
                        EmptyStateView(symbol: "calendar.badge.plus",
                                       title: "No past shows yet",
                                       message: "You have an upcoming show on your bucket list. Log a past one to fill your timeline.",
                                       actionTitle: "Log a show") { presentEditor() }
                            .padding(.top, 12)
                    }

                    ForEach(grouped, id: \.year) { group in
                        Section {
                            ForEach(group.shows) { concert in
                                NavigationLink(value: concert) {
                                    TicketStubCard(concert: concert)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            yearHeader(group.year, count: group.shows.count)
                        }
                    }
                }
                .padding(.bottom, 96)
            }
        }
    }

    private func yearHeader(_ year: Int, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(String(year))
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
            Text(count == 1 ? "1 show" : "\(count) shows")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.bg.opacity(0.97))
    }

    private var addButton: some View {
        Button {
            presentEditor()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Theme.heroGradient))
                .shadow(color: Theme.accent.opacity(0.4), radius: 10, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Log a show")
    }

    private func presentEditor() {
        let total = concerts.count
        if !Pro.canAddShow(currentCount: total, isPro: isPro) {
            paywallReason = .showLimit
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        Haptics.tap(enabled: settings.hapticsEnabled)
        showEditor = true
    }
}

/// The live countdown banner for the next upcoming show. Uses TimelineView so the
/// "days left" stays current; respects Reduce Motion for the glow.
struct UpcomingBanner: View {
    let concert: Concert
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            let days = concert.daysUntil ?? 0
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.heroGradient)
                        .frame(width: 56, height: 56)
                    VStack(spacing: 0) {
                        Text("\(days)")
                            .font(Theme.rounded(20, .bold))
                            .foregroundStyle(.white)
                        Text(days == 1 ? "day" : "days")
                            .font(Theme.rounded(9, .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Next up")
                        .font(Theme.rounded(11, .bold))
                        .foregroundStyle(Theme.accent)
                    Text(concert.headliner)
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(bannerSubtitle)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                            .strokeBorder(Theme.accent.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: reduceMotion ? .clear : Theme.accent.opacity(0.22),
                            radius: reduceMotion ? 0 : 14, y: 6)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Next up: \(concert.headliner), \(bannerSubtitle), in \(days) \(days == 1 ? "day" : "days")")
        }
    }

    private var bannerSubtitle: String {
        var parts: [String] = []
        if !concert.locationLine.isEmpty { parts.append(concert.locationLine) }
        parts.append(concert.date.formatted(date: .abbreviated, time: .omitted))
        return parts.joined(separator: " · ")
    }
}

#Preview("Timeline") {
    TimelineScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
