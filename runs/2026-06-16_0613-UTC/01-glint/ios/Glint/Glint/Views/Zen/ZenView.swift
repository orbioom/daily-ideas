import SwiftUI
import SwiftData

struct ZenView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var pro: ProStore
    @Query(filter: #Predicate<SavedGame> { $0.slot == "zen" }) private var saves: [SavedGame]
    @Query(filter: #Predicate<ZenScore> { $0.key == "zen" }) private var zenScores: [ZenScore]

    @State private var route: PlayConfig?
    @State private var resumeSave: SavedGame?
    @State private var showPaywall = false

    private var highScore: Int { zenScores.first?.highScore ?? 0 }
    private var hasSave: Bool { saves.first != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.calmGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        hero
                        if hasSave, let save = saves.first {
                            resumeCard(save)
                        }
                        newGameCard
                        if pro.isPro {
                            skinsCard
                        } else {
                            proTeaser
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Zen")
            .navigationDestination(item: $route) { config in
                PlayView(config: config, resume: config.resumeSlot == "zen" ? resumeSave : nil)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "infinity")
                .font(.system(size: 50, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text("Endless Zen")
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(.white)
            Text("No moves limit. Just match, breathe, and chase your best.")
                .font(Theme.rounded(15))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill").foregroundStyle(Theme.gold)
                Text("High score: \(highScore)")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("High score \(highScore)")
        }
        .padding(.top, 8)
    }

    private func resumeCard(_ save: SavedGame) -> some View {
        GlintCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Resume your game", systemImage: "play.circle.fill")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Score \(save.score) · saved \(save.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                    resumeSave = save
                    route = PlayConfig(mode: .zen, level: nil, seed: Date().daySeed, allowRestart: true, resumeSlot: "zen")
                }
            }
        }
    }

    private var newGameCard: some View {
        GlintCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("New session", systemImage: "sparkles")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Start a fresh 8×8 board. Your progress saves automatically when you leave.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                Button {
                    if hasSave, let save = saves.first { context.delete(save); try? context.save() }
                    resumeSave = nil
                    route = PlayConfig(mode: .zen, level: nil,
                                       seed: UInt64.random(in: 1...UInt64.max),
                                       allowRestart: true, resumeSlot: nil)
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(hasSave ? "Start over" : "Play").font(Theme.rounded(17, .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(Theme.accent)
                    .background(RoundedRectangle(cornerRadius: Theme.rMed).fill(Theme.surfaceRaised))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var skinsCard: some View {
        GlintCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Zen skins unlocked", systemImage: "paintpalette.fill")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Thanks for going Pro. Calming amethyst & twilight board themes are active in Zen.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var proTeaser: some View {
        Button { showPaywall = true } label: {
            GlintCard {
                HStack(spacing: 12) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Zen board skins")
                            .font(Theme.rounded(16, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Unlock calming themes with Glint Pro.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
