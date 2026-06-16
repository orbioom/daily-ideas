import SwiftUI
import SwiftData

/// Home of the Play tab: pick a mode and configure a new game.
struct PlayHomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]

    @State private var newGameMode: GameMode? = nil
    @State private var activeConfig: GameConfig? = nil
    @State private var showPaywall = false
    @State private var showHowTo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerCard

                    SectionHeader(title: "New game", subtitle: "Pick how you want to play")
                        .padding(.top, 4)

                    modeCard(.solo, locked: false)
                    modeCard(.passAndPlay, locked: false)
                    modeCard(.vsCPU, locked: !isPro)

                    Button {
                        showHowTo = true
                    } label: {
                        HStack {
                            Image(systemName: "book.closed.fill")
                            Text("How to play")
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote)
                        }
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(16)
                        .card()
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Pip")
            .sheet(item: $newGameMode) { mode in
                NewGameSheet(mode: mode) { config in
                    newGameMode = nil
                    // Present the game after the sheet dismisses.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        activeConfig = config
                    }
                }
            }
            .fullScreenCover(item: $activeConfig) { config in
                GameView(config: config)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showHowTo) { HowToPlayView() }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Roll the felt.")
                        .font(Theme.rounded(26, .bold))
                        .foregroundStyle(.white)
                    Text("Five dice. Three rolls. Thirteen ways to score.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "dice.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.95))
                    .accessibilityHidden(true)
            }
            HStack(spacing: 10) {
                miniStat("Games", "\(records.count)")
                miniStat("Best", "\(records.map { $0.myScore }.max() ?? 0)")
                if !isPro {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                            Text("Get Pro")
                        }
                        .font(Theme.rounded(14, .bold))
                        .foregroundStyle(Theme.accentDeep)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(.white, in: Capsule())
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.rLarge, style: .continuous)
                .fill(Theme.feltGradient)
        )
        .accessibilityElement(children: .contain)
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(Theme.rounded(20, .bold)).foregroundStyle(.white)
            Text(label).font(Theme.rounded(12)).foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func modeCard(_ mode: GameMode, locked: Bool) -> some View {
        Button {
            if locked {
                showPaywall = true
            } else {
                newGameMode = mode
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.accentSoft)
                        .frame(width: 52, height: 52)
                    Image(systemName: mode.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(mode.rawValue)
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        if locked { ProLockBadge() }
                    }
                    Text(mode.blurb)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(16)
            .card()
        }
        .accessibilityLabel("\(mode.rawValue). \(mode.blurb)\(locked ? ". Pro feature" : "")")
    }
}
