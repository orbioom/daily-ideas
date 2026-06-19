import SwiftUI
import SwiftData
import Charts

struct MemoirProgressView: View {
    @Query(sort: \StoryEntry.createdDate, order: .reverse) private var entries: [StoryEntry]

    private var engine: MemoirEngine { MemoirEngine() }

    private var totalWords: Int { engine.totalWords(from: entries) }
    private var streak: Int { engine.streakDays(from: entries) }
    private var weeklyData: [(day: String, words: Int)] { engine.weeklyWordCounts(from: entries) }
    private var eraData: [(era: LifeEra, count: Int)] { engine.eraBreakdown(from: entries) }
    private var moodData: [(mood: EntryMood, count: Int)] { engine.moodBreakdown(from: entries) }
    private var recentEntries: [StoryEntry] { engine.recentEntries(from: entries, limit: 5) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stat cards
                    HStack(spacing: 12) {
                        BigStatCard(
                            value: "\(entries.count)",
                            label: "Entries",
                            icon: "book.pages.fill",
                            color: MemoirTheme.warmAmber
                        )
                        BigStatCard(
                            value: totalWords.formatted(),
                            label: "Words",
                            icon: "text.alignleft",
                            color: MemoirTheme.forestGreen
                        )
                        BigStatCard(
                            value: "\(streak)",
                            label: streak == 1 ? "Day" : "Days",
                            icon: "flame.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 16)

                    // Weekly word count chart
                    if weeklyData.contains(where: { $0.words > 0 }) {
                        ChartSection(title: "Words This Week", icon: "chart.bar.fill") {
                            Chart(weeklyData, id: \.day) { item in
                                BarMark(
                                    x: .value("Day", item.day),
                                    y: .value("Words", item.words)
                                )
                                .foregroundStyle(MemoirTheme.warmAmber.gradient)
                                .cornerRadius(6)
                            }
                            .frame(height: 150)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .padding(.top, 8)
                        }
                    }

                    // Era distribution
                    let filteredEra = eraData.filter { $0.count > 0 }
                    if !filteredEra.isEmpty {
                        ChartSection(title: "Stories by Era", icon: "clock.arrow.circlepath") {
                            Chart(filteredEra, id: \.era) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Era", item.era.displayName)
                                )
                                .foregroundStyle(MemoirTheme.eraColor(item.era).gradient)
                                .cornerRadius(5)
                                .annotation(position: .trailing) {
                                    Text("\(item.count)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(height: CGFloat(filteredEra.count) * 38 + 20)
                            .chartXAxis(.hidden)
                            .padding(.top, 8)
                        }
                    }

                    // Mood breakdown
                    let filteredMood = moodData.filter { $0.count > 0 }
                    if !filteredMood.isEmpty {
                        ChartSection(title: "Mood Breakdown", icon: "heart.fill") {
                            VStack(spacing: 0) {
                                // Donut
                                Chart(filteredMood, id: \.mood) { item in
                                    SectorMark(
                                        angle: .value("Count", item.count),
                                        innerRadius: .ratio(0.55),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(MemoirTheme.moodColor(item.mood))
                                    .cornerRadius(4)
                                }
                                .frame(height: 180)

                                // Legend
                                LazyVGrid(
                                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                                    spacing: 8
                                ) {
                                    ForEach(filteredMood, id: \.mood) { item in
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(MemoirTheme.moodColor(item.mood))
                                                .frame(width: 8, height: 8)
                                            Text("\(item.mood.emoji) \(item.mood.displayName)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("\(item.count)")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(MemoirTheme.inkBrown)
                                        }
                                    }
                                }
                                .padding(.top, 12)
                            }
                        }
                    }

                    // Recent activity
                    if !recentEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(MemoirTheme.warmAmber)
                                Text("Recent Activity")
                                    .font(.headline)
                                    .foregroundColor(MemoirTheme.inkBrown)
                            }
                            .padding(.horizontal, 16)

                            VStack(spacing: 8) {
                                ForEach(recentEntries) { entry in
                                    NavigationLink {
                                        StoryDetailView(entry: entry)
                                    } label: {
                                        RecentEntryRow(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }

                    // Empty state
                    if entries.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundColor(MemoirTheme.warmAmber.opacity(0.4))
                            Text("Start writing to see your progress")
                                .font(.system(.subheadline, design: .serif))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 12)
            }
            .background(MemoirTheme.parchment.opacity(0.3).ignoresSafeArea())
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - BigStatCard

private struct BigStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(MemoirTheme.inkBrown)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
    }
}

// MARK: - ChartSection

private struct ChartSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(MemoirTheme.warmAmber)
                Text(title)
                    .font(.headline)
                    .foregroundColor(MemoirTheme.inkBrown)
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - RecentEntryRow

private struct RecentEntryRow: View {
    let entry: StoryEntry

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(MemoirTheme.eraColor(entry.era))
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.system(.subheadline, design: .serif).weight(.medium))
                    .foregroundColor(MemoirTheme.inkBrown)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(entry.era.displayName)
                        .font(.caption2)
                        .foregroundColor(MemoirTheme.eraColor(entry.era))
                    Text("·")
                        .foregroundColor(.secondary)
                    Text("\(entry.wordCount) words")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(entry.createdDate.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundColor(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
        )
    }
}
