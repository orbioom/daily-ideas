import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var results: [GameResult]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("timedMode") private var timedMode = true
    @AppStorage("showFacts") private var showFacts = true

    @State private var showPaywall = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    if !pro.isPro {
                        Section {
                            Button { showPaywall = true } label: { proBanner }.buttonStyle(.plain)
                        }.listRowBackground(Color.clear)
                    }

                    Section("Gameplay") {
                        Toggle("Timed questions", isOn: $timedMode)
                        Toggle("Show fun facts", isOn: $showFacts)
                    } footer: {
                        Text("Turn off the timer for a relaxed, pressure-free round.")
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                    }

                    Section("Savant Pro") {
                        if pro.isPro {
                            Label("Savant Pro unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Savant Pro") { showPaywall = true }.foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }.foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack { Text("Rounds played"); Spacer(); Text("\(results.count)").foregroundStyle(Theme.inkSoft) }
                        HStack { Text("Question bank"); Spacer(); Text("\(QuestionBank.all.count) questions").foregroundStyle(Theme.inkSoft) }
                        Button("Reset stats & history", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Savant is fully on-device. No ads, no accounts, no tracking.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Reset everything?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently clears your scores, streaks and history.")
            }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "brain.head.profile").font(.system(size: 30)).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Savant Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("Unlimited practice, difficulty & longer rounds").font(Theme.rounded(13, .regular)).foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.74)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func reset() {
        for r in results { context.delete(r) }
        try? context.save()
        Haptics.warning()
    }
}

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let perks = [
        ("infinity", "Unlimited practice", "Play as many rounds a day as you like — free gives you five."),
        ("slider.horizontal.3", "Difficulty & longer rounds", "Filter by easy, medium or hard and play 15- or 20-question rounds."),
        ("heart.fill", "Support a no-ad game", "One purchase keeps Savant ad-free forever — no subscription.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 58)).foregroundStyle(Theme.accent)
                            .padding(.top, 28).accessibilityHidden(true)
                        Text("Savant Pro").font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                        Text("The daily challenge is always free. Pro unlocks endless play.")
                            .font(Theme.rounded(16, .regular)).foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center).padding(.horizontal, 28)
                        VStack(spacing: 14) {
                            ForEach(perks, id: \.0) { perk in
                                HStack(spacing: 14) {
                                    Image(systemName: perk.0).font(.system(size: 24))
                                        .foregroundStyle(Theme.accent).frame(width: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(perk.1).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                                        Text(perk.2).font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                                    }
                                    Spacer()
                                }
                            }
                        }.padding(.horizontal, 20)
                    }
                }
                VStack(spacing: 10) {
                    Button {
                        pro.unlock(); Haptics.success(); dismiss()
                    } label: {
                        Text("Unlock for $4.99").font(Theme.rounded(18, .bold))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    Button("Maybe later") { dismiss() }
                        .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
        }
    }
}
