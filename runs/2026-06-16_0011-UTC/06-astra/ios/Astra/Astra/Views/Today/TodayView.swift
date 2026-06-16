import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Profile.createdDate) private var profiles: [Profile]
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @AppStorage("isPro") private var isPro = false
    @State private var showAddProfile = false
    @State private var showCheckIn = false
    @State private var paywallReason: PaywallReason?

    private var primary: Profile? {
        ProfileResolver.primary(from: profiles, primaryID: settings.primaryProfileID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.skyGradient.ignoresSafeArea()
                Starfield(starCount: 50).ignoresSafeArea()
                content
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }
                    .accessibilityLabel("Add chart")
                }
            }
            .sheet(isPresented: $showAddProfile) {
                ProfileEditorView(profile: nil)
            }
            .sheet(isPresented: $showCheckIn) {
                if let primary {
                    CheckInView(profile: primary, reading: reading(for: primary))
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let primary {
            loadedContent(for: primary)
        } else {
            EmptyStateView(
                symbol: "sparkles",
                title: "Create your chart",
                message: "Add your birth date, time, and city to compute your accurate chart and see today's reading.",
                actionTitle: "Create your chart"
            ) {
                showAddProfile = true
            }
            .padding()
        }
    }

    private func loadedContent(for profile: Profile) -> some View {
        let dayReading = reading(for: profile)
        let myEntries = entries.filter { $0.profileName == profile.name }
        let streak = StreakEngine.currentStreak(entries: myEntries)
        let hasToday = StreakEngine.hasEntryToday(entries: myEntries)

        return ScrollView {
            VStack(spacing: 18) {
                headerCard(profile: profile, reading: dayReading)
                streakRow(streak: streak, hasToday: hasToday)
                moonCard(reading: dayReading)
                if let strongest = dayReading.strongest {
                    transitCard(strongest)
                }
                readingCard(dayReading)
                outlookCard(dayReading)
                checkInCard(hasToday: hasToday)
                if !myEntries.isEmpty {
                    recentEntries(myEntries)
                }
            }
            .padding(16)
        }
    }

    private func headerCard(profile: Profile, reading: DailyReading) -> some View {
        VStack(spacing: 8) {
            Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkFaint)
            Text("Hello, \(profile.name)")
                .font(Theme.serif(26, .bold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func streakRow(streak: Int, hasToday: Bool) -> some View {
        HStack(spacing: 12) {
            StatChip(caption: "Streak", value: "\(streak)d", tint: Theme.gold)
            StatChip(caption: "Today", value: hasToday ? "Logged" : "Open",
                     tint: hasToday ? Theme.good : Theme.accent)
        }
    }

    private func moonCard(reading: DailyReading) -> some View {
        HStack(spacing: 14) {
            GlyphBadge(glyph: reading.moonSign.glyph, tint: Theme.gold, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text("Moon in \(reading.moonSign.name)")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Emotional weather: \(reading.moonSign.keywords.joined(separator: ", "))")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private func transitCard(_ t: TransitHit) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(t.kind.color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Strongest transit")
                    .font(Theme.rounded(11, .bold))
                    .foregroundStyle(Theme.inkFaint)
                Text(t.headline)
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(t.kind.rawValue) · \(t.exactness)")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private func readingCard(_ reading: DailyReading) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Your reading", systemImage: "text.book.closed.fill")
            Text(reading.body)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .cardSurface()
    }

    @ViewBuilder
    private func outlookCard(_ reading: DailyReading) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Days ahead", systemImage: "calendar.badge.clock")
                if !isPro { ProLockChip() }
            }
            if isPro {
                if reading.outlook.isEmpty {
                    Text("No tight transits in the next few days — open, quiet skies.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                } else {
                    ForEach(reading.outlook) { day in
                        HStack(spacing: 12) {
                            Text(day.moonSign.glyph)
                                .font(.system(size: 18)).foregroundStyle(Theme.gold)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(day.date, format: .dateTime.weekday(.wide).month().day())
                                    .font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.ink)
                                Text(day.headline)
                                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        if day.id != reading.outlook.last?.id {
                            Divider().overlay(Theme.hairline)
                        }
                    }
                }
            } else {
                Text("See a calm, multi-day outlook of the transits coming your way with Astra Pro.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                SecondaryButton(title: "Unlock the outlook", systemImage: "lock.open.fill") {
                    paywallReason = .transitOutlook
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func checkInCard(hasToday: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Daily reflection", systemImage: "heart.text.square.fill")
            Text(hasToday
                 ? "You've logged today. Tap to update how you're feeling."
                 : "How are you, honestly? A quick note keeps your streak and grounds the day.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: hasToday ? "Update today's note" : "Check in",
                          systemImage: "square.and.pencil") {
                showCheckIn = true
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func recentEntries(_ entries: [JournalEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent reflections", systemImage: "calendar")
            ForEach(entries.prefix(5)) { entry in
                HStack(spacing: 12) {
                    Image(systemName: entry.moodSymbol)
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.gold)
                        .frame(width: 26)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date, format: .dateTime.month().day())
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.ink)
                        if !entry.note.isEmpty {
                            Text(entry.note)
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Text(entry.moodLabel)
                        .font(Theme.rounded(11, .bold))
                        .foregroundStyle(Theme.inkFaint)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                if entry.id != entries.prefix(5).last?.id {
                    Divider().overlay(Theme.hairline)
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func reading(for profile: Profile) -> DailyReading {
        let natal = ChartService.chart(for: profile)
        return TransitEngine.reading(natal: natal, on: Date(), baseOrb: settings.defaultOrb, includeOutlook: isPro)
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewContainer.shared)
        .environmentObject(AppSettings())
}
