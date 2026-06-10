import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var affirmations: [Affirmation]
    @Query private var logs: [DayLog]
    @AppStorage("enabledThemes") private var enabledThemesRaw = ""

    @State private var deck: [Affirmation] = []
    @State private var index = 0
    @State private var affirmedToday = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var enabledThemes: Set<String> {
        let s = enabledThemesRaw.split(separator: ",").map(String.init)
        return s.isEmpty ? Set(AffirmationTheme.allCases.map(\.rawValue)) : Set(s)
    }

    private var pool: [Affirmation] {
        let filtered = affirmations.filter { enabledThemes.contains($0.themeRaw) }
        return filtered.isEmpty ? affirmations : filtered
    }

    private var current: Affirmation? {
        guard !deck.isEmpty, index >= 0, index < deck.count else { return nil }
        return deck[index]
    }

    private var stats: StreakStats { StreakEngine.stats(from: logs) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if pool.isEmpty {
                    EmptyStateView(icon: "square.stack",
                                   title: "No affirmations yet",
                                   message: "Add your own from the Library, or enable a theme in Settings.")
                } else {
                    content
                }
            }
            .navigationTitle("Today")
        }
        .onAppear(perform: rebuildDeck)
        .onChange(of: enabledThemesRaw) { _, _ in rebuildDeck() }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                if let current {
                    AffirmationCardView(affirmation: current)
                        .id(current.id)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity))

                    HStack(spacing: 12) {
                        Button {
                            Haptics.tap()
                            withAnimation(reduceMotion ? nil : Brand.ease(0.4)) {
                                index = (index + 1) % max(1, deck.count)
                            }
                        } label: {
                            Label("Next", systemImage: "arrow.right")
                        }
                        .buttonStyle(GlassButtonStyle())

                        Button {
                            toggleFavorite(current)
                        } label: {
                            Label(current.isFavorite ? "Saved" : "Save",
                                  systemImage: current.isFavorite ? "heart.fill" : "heart")
                        }
                        .buttonStyle(GlassButtonStyle())
                        .tint(Brand.danger)
                    }

                    Button {
                        markAffirmed()
                    } label: {
                        Label(affirmedToday ? "Affirmed today" : "I affirm this",
                              systemImage: affirmedToday ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                    .buttonStyle(InkButtonStyle())
                    .disabled(affirmedToday)
                }
            }
            .padding(20)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: greeting)
                Text(stats.current > 0 ? "\(stats.current)-day streak" : "Begin your streak")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)
            }
            Spacer()
            ZStack {
                Circle().fill(Brand.magic.opacity(0.16)).frame(width: 48, height: 48)
                Image(systemName: "flame")
                    .foregroundStyle(stats.current > 0 ? Brand.magic : Brand.text3)
            }
            .accessibilityHidden(true)
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }

    private func rebuildDeck() {
        let p = pool
        guard !p.isEmpty else { deck = []; return }
        deck = AffirmationEngine.deck(from: p)
        // Start the day on the deterministic daily affirmation.
        if let daily = AffirmationEngine.dailyAffirmation(from: p),
           let i = deck.firstIndex(where: { $0.id == daily.id }) {
            index = i
        } else {
            index = 0
        }
        refreshAffirmedState()
    }

    private func refreshAffirmedState() {
        let today = Calendar.current.startOfDay(for: .now)
        affirmedToday = logs.contains { Calendar.current.startOfDay(for: $0.day) == today && $0.count > 0 }
    }

    private func toggleFavorite(_ a: Affirmation) {
        Haptics.selection()
        a.isFavorite.toggle()
        try? context.save()
    }

    private func markAffirmed() {
        guard !affirmedToday else { return }
        Haptics.success()
        PracticeLog.record(context, count: 1)
        withAnimation(Brand.ease()) { affirmedToday = true }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Affirmation.self, DayLog.self], inMemory: true)
}
