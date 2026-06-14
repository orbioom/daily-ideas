import SwiftUI
import SwiftData

/// "What to wear tonight": pick a season + occasion, get ranked eligible bottles.
struct TonightScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query private var allFragrances: [Fragrance]

    @State private var season: Season = Season.current()
    @State private var occasion: Occasion = .evening

    private var collection: [Fragrance] {
        allFragrances.filter { $0.status.isInCollection }
    }

    private var recommendations: [Fragrance] {
        Recommender.recommend(fragrances: allFragrances, season: season, occasion: occasion)
    }

    private var recent: [(fragrance: Fragrance, date: Date)] {
        Recommender.recentlyWorn(fragrances: allFragrances, limit: 8)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Tonight")
            .navigationDestination(for: Fragrance.self) { f in
                FragranceDetailView(fragrance: f)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if collection.isEmpty {
            EmptyStateView(symbol: "moon.stars",
                           title: "Nothing to recommend yet",
                           message: "Add a few bottles to your collection and Sillage will help you choose what to wear.")
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    pickerCard
                    if !recent.isEmpty { recentStrip }
                    resultsSection
                }
                .padding(20)
            }
        }
    }

    private var pickerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What's the vibe?")
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: 8) {
                Text("SEASON").font(Theme.rounded(11, .bold)).foregroundStyle(Theme.inkFaint)
                FlowLayout(spacing: 8) {
                    ForEach(Season.allCases) { s in
                        selectChip(s.rawValue, symbol: s.symbol, on: season == s, tint: s.hue) {
                            season = s
                            Haptics.tap(settings.hapticsEnabled)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("OCCASION").font(Theme.rounded(11, .bold)).foregroundStyle(Theme.inkFaint)
                FlowLayout(spacing: 8) {
                    ForEach(Occasion.allCases) { o in
                        selectChip(o.rawValue, symbol: o.symbol, on: occasion == o, tint: Theme.accent) {
                            occasion = o
                            Haptics.tap(settings.hapticsEnabled)
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private func selectChip(_ text: String, symbol: String, on: Bool, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
                Text(text).font(Theme.rounded(14, .medium))
            }
            .foregroundStyle(on ? .white : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(on ? tint : tint.opacity(0.14)))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var recentStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently worn")
                .font(Theme.rounded(13, .bold))
                .foregroundStyle(Theme.inkSoft)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recent, id: \.fragrance.id) { item in
                        NavigationLink(value: item.fragrance) {
                            VStack(spacing: 6) {
                                JuiceSwatch(family: item.fragrance.primaryFamily,
                                            colorHue: item.fragrance.colorHue, size: 58)
                                Text(item.fragrance.name)
                                    .font(Theme.rounded(11, .medium))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                    .frame(width: 70)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        let results = recommendations
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tonight's picks")
                    .font(Theme.serif(20, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(results.count)")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }

            if results.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "nose")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.accent.opacity(0.7))
                        .accessibilityHidden(true)
                    Text("Nothing tagged for \(season.rawValue.lowercased()) + \(occasion.rawValue.lowercased()) yet.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                    Text("Tag your bottles with seasons & occasions, or try a different combination.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(22)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
            } else {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, f in
                    recommendationRow(f, rank: index + 1)
                }
            }
        }
    }

    private func recommendationRow(_ f: Fragrance, rank: Int) -> some View {
        HStack(spacing: 12) {
            NavigationLink(value: f) {
                HStack(spacing: 12) {
                    JuiceSwatch(family: f.primaryFamily, colorHue: f.colorHue, size: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(f.house.uppercased())
                            .font(Theme.rounded(10, .bold))
                            .foregroundStyle(Theme.inkFaint)
                        Text(f.name)
                            .font(Theme.serif(16, .semibold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Text(lastWornText(f))
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button {
                wear(f)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                    Text("Wore it")
                        .font(Theme.rounded(10, .semibold))
                }
                .foregroundStyle(.white)
                .frame(width: 60, height: 52)
                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Theme.accent))
            }
            .accessibilityLabel("I wore \(f.name) today")
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private func lastWornText(_ f: Fragrance) -> String {
        guard let last = f.lastWorn else { return "Never worn — give it a day" }
        let days = Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0
        if days <= 0 { return "Worn today" }
        if days == 1 { return "Worn yesterday" }
        return "Worn \(days) days ago"
    }

    private func wear(_ f: Fragrance) {
        let log = WearLog(date: .now, occasion: occasion, season: season, note: "")
        log.fragrance = f
        f.wears.append(log)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }
}
