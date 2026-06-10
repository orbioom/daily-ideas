import SwiftUI
import SwiftData

struct PracticeSetupView: View {
    @Query private var affirmations: [Affirmation]
    @AppStorage("practiceTheme") private var practiceThemeRaw = "all"
    @AppStorage("practiceCount") private var practiceCount = 5
    @AppStorage("practiceFavoritesOnly") private var favoritesOnly = false
    @State private var session: PracticeSession?

    private var selectedTheme: AffirmationTheme? {
        practiceThemeRaw == "all" ? nil : AffirmationTheme(rawValue: practiceThemeRaw)
    }

    private var pool: [Affirmation] {
        affirmations.filter { a in
            (selectedTheme == nil || a.theme == selectedTheme!) &&
            (!favoritesOnly || a.isFavorite)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 6) {
                            Image(systemName: "wind")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(Brand.magic)
                                .accessibilityHidden(true)
                            Text("Breathing Practice")
                                .font(.title2.bold())
                                .foregroundStyle(Brand.text)
                            Text("Each affirmation rises as you breathe in and settles as you breathe out.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Theme").font(.headline).foregroundStyle(Brand.text)
                            Picker("Theme", selection: $practiceThemeRaw) {
                                Text("All themes").tag("all")
                                ForEach(AffirmationTheme.allCases) { t in
                                    Text(t.title).tag(t.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Brand.text)

                            Toggle("Favorites only", isOn: $favoritesOnly)
                                .tint(Brand.live)

                            Stepper(value: $practiceCount, in: 3...15) {
                                HStack {
                                    Text("Affirmations")
                                    Spacer()
                                    Text("\(practiceCount)").font(Brand.mono(16, weight: .semibold))
                                        .foregroundStyle(Brand.text2)
                                }
                            }
                        }
                        .padding(18)
                        .glassCard()

                        if pool.isEmpty {
                            Text(favoritesOnly ? "No favorites match this theme yet." : "No affirmations in this theme yet.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.center)
                                .padding()
                        }

                        Button {
                            startSession()
                        } label: {
                            Label("Begin Practice", systemImage: "play.fill")
                        }
                        .buttonStyle(InkButtonStyle())
                        .disabled(pool.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Practice")
            .fullScreenCover(item: $session) { s in
                PracticePlayerView(session: s)
            }
        }
    }

    private func startSession() {
        let chosen = Array(pool.shuffled().prefix(practiceCount))
        guard !chosen.isEmpty else { return }
        session = PracticeSession(items: chosen.map { ($0.text, $0.theme) })
        Haptics.tap()
    }
}

/// A value snapshot of the affirmations to show, decoupled from SwiftData so the
/// full-screen player owns plain data.
struct PracticeSession: Identifiable {
    let id = UUID()
    let items: [(String, AffirmationTheme)]
}

#Preview {
    PracticeSetupView()
        .modelContainer(for: [Affirmation.self, DayLog.self], inMemory: true)
}
