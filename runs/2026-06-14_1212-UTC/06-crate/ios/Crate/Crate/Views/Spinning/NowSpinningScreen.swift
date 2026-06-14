import SwiftUI
import SwiftData

/// Now Spinning — a seeded "What should I spin?" surprise picker, one-tap log, and a recent shelf.
struct NowSpinningScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var allRecords: [Record]

    @State private var seed: UInt64 = UInt64(Date().timeIntervalSince1970)
    @State private var genreFilter: Genre?
    @State private var decadeFilter: Int?
    @State private var loggedID: UUID?
    @State private var spinAngle: Double = 0

    private var owned: [Record] { allRecords.filter { $0.status == .owned } }

    private var availableDecades: [Int] {
        Set(owned.compactMap { $0.decade }).sorted(by: >)
    }

    private var pickID: UUID? {
        SpinPicker.pick(from: owned,
                    genre: genreFilter,
                    decade: decadeFilter,
                    preferUnplayed: settings.preferUnplayed,
                    seed: seed)
    }

    private var picked: Record? {
        guard let pickID else { return nil }
        return owned.first { $0.id == pickID }
    }

    private var recent: [Record] {
        owned.filter { $0.lastSpinDate != nil }
            .sorted { ($0.lastSpinDate ?? .distantPast) > ($1.lastSpinDate ?? .distantPast) }
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Now Spinning")
            .navigationDestination(for: Record.self) { rec in
                RecordDetailView(record: rec)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if owned.isEmpty {
            EmptyStateView(symbol: "opticaldisc",
                           title: "Nothing to spin yet",
                           message: "Add records to your collection and Crate will help you pick what to play.")
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    filterRow
                    if let picked {
                        turntableCard(picked)
                    } else {
                        EmptyStateView(symbol: "line.3.horizontal.decrease.circle",
                                       title: "No records match",
                                       message: "No owned records fit these filters. Clear them to draw from your whole crate.",
                                       actionTitle: "Clear filters") { genreFilter = nil; decadeFilter = nil }
                    }
                    recentShelf
                }
                .padding(20)
            }
        }
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            Menu {
                Button("Any genre") { genreFilter = nil; reroll() }
                ForEach(Genre.allCases) { g in Button(g.rawValue) { genreFilter = g; reroll() } }
            } label: {
                chip(genreFilter?.rawValue ?? "Any genre", active: genreFilter != nil)
            }
            Menu {
                Button("Any decade") { decadeFilter = nil; reroll() }
                ForEach(availableDecades, id: \.self) { d in Button("\(d)s") { decadeFilter = d; reroll() } }
            } label: {
                chip(decadeFilter.map { "\($0)s" } ?? "Any decade", active: decadeFilter != nil)
            }
            Spacer()
        }
    }

    private func chip(_ text: String, active: Bool) -> some View {
        HStack(spacing: 5) {
            Text(text).font(Theme.rounded(13, .semibold))
            Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(active ? .white : Theme.ink)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Capsule().fill(active ? Theme.accent : Theme.surfaceAlt))
    }

    private func turntableCard(_ rec: Record) -> some View {
        VStack(spacing: 16) {
            ZStack {
                VinylDisc(labelHue: rec.coverHue, labelFraction: 0.46)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(spinAngle))
                // Tonearm hint.
                Image(systemName: "line.diagonal")
                    .font(.system(size: 120, weight: .ultraLight))
                    .foregroundStyle(Theme.inkFaint.opacity(0.25))
                    .accessibilityHidden(true)
            }
            .frame(height: 210)
            .onAppear { startSpin() }

            VStack(spacing: 4) {
                Text(rec.title)
                    .font(Theme.serif(22, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(rec.artist)
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                HStack(spacing: 6) {
                    Pill(text: rec.format.display, systemImage: rec.format.symbol, tint: Theme.accent)
                    Pill(text: rec.genre.rawValue, systemImage: rec.genre.symbol, tint: rec.genre.hue)
                    Pill(text: rec.yearLabel, systemImage: "calendar")
                }
                .padding(.top, 4)
                if let last = rec.lastSpinDate {
                    Text("Last spun \(last.formatted(date: .abbreviated, time: .omitted))")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.top, 2)
                } else {
                    Text("Never spun — give it a turn")
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 2)
                }
            }

            if loggedID == rec.id {
                Label("Spin logged", systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.good)
                    .transition(.opacity)
            }

            VStack(spacing: 10) {
                PrimaryButton(title: "Log spin", systemImage: "play.circle.fill") { logSpin(rec) }
                HStack(spacing: 10) {
                    Button { reroll() } label: {
                        Label("Re-roll", systemImage: "dice")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accentSoft))
                    }
                    NavigationLink(value: rec) {
                        Label("Details", systemImage: "info.circle")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surfaceAlt))
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
        .animation(.easeInOut, value: loggedID)
    }

    @ViewBuilder
    private var recentShelf: some View {
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recently spun")
                    .font(Theme.serif(18, .semibold))
                    .foregroundStyle(Theme.ink)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recent) { rec in
                            NavigationLink(value: rec) {
                                VStack(alignment: .leading, spacing: 6) {
                                    CoverArtView(title: rec.title, artist: rec.artist, hue: rec.coverHue, showDisc: false)
                                        .frame(width: 104, height: 104)
                                    Text(rec.title)
                                        .font(Theme.rounded(12, .semibold))
                                        .foregroundStyle(Theme.ink)
                                        .lineLimit(1)
                                        .frame(width: 104, alignment: .leading)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func startSpin() {
        guard !reduceMotion else { spinAngle = 0; return }
        spinAngle = 0
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            spinAngle = 360
        }
    }

    private func reroll() {
        Haptics.tap(settings.hapticsEnabled)
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        loggedID = nil
        startSpin()
    }

    private func logSpin(_ rec: Record) {
        let spin = Spin(date: .now, rating: 0, note: "")
        spin.record = rec
        rec.spins.append(spin)
        try? context.save()
        loggedID = rec.id
        Haptics.success(settings.hapticsEnabled)
    }
}
