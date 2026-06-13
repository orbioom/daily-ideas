import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var records: [GameProgress]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("letterHaptic") private var letterHaptic = true
    @AppStorage("hexLayout") private var hexLayout = true
    @AppStorage("highContrast") private var highContrast = false
    @AppStorage("showFoundCount") private var showFoundCount = true

    @State private var showPaywall = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    if !pro.isPro {
                        Section {
                            Button { showPaywall = true } label: { proBanner }
                                .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section("Board") {
                        Picker("Letter layout", selection: $hexLayout) {
                            Text("Honeycomb").tag(true)
                            Text("Simple").tag(false)
                        }
                        Toggle("Show found-word count", isOn: $showFoundCount)
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                        Toggle("Haptic on tapping a letter", isOn: $letterHaptic)
                            .disabled(!haptics)
                    }

                    Section {
                        Toggle("High-contrast colours", isOn: $highContrast)
                    } footer: {
                        Text("Swaps the gold accent for a strong blue across the app, for colour-blind and high-contrast needs.")
                    }

                    Section("Pro") {
                        if pro.isPro {
                            Label("Hive Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Hive Pro") { showPaywall = true }
                                .foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }
                            .foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack {
                            Text("Saved games"); Spacer()
                            Text("\(records.count)").foregroundStyle(Theme.inkSoft)
                        }
                        Button("Reset all progress", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Hive keeps everything on your device. No account, no tracking, no ads, no subscription.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Reset all progress?", isPresented: $confirmReset) {
                Button("Delete every game", role: .destructive) { resetProgress() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes your found words for every daily and practice puzzle. Your settings stay.")
            }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "hexagon.fill").font(.system(size: 34)).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Hive Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("Extra puzzles, themes & definition peeks").font(Theme.rounded(13, .regular))
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.78)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func resetProgress() {
        for r in records { context.delete(r) }
        try? context.save()
        Haptics.success()
    }
}

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let perks = [
        ("hexagon.fill", "Extra puzzle pack", "A bonus set of hand-authored honeycombs on top of the free daily and practice puzzles."),
        ("text.book.closed.fill", "Definition peeks", "Tap any found word for a quick glanceable note about it."),
        ("infinity", "One price, forever", "A single purchase — no subscription, no ads, ever.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "hexagon.fill")
                            .font(.system(size: 64)).foregroundStyle(Theme.accent)
                            .padding(.top, 28).accessibilityHidden(true)
                        Text("Hive Pro").font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                        Text("The whole game — daily, practice, archive and stats — is already free. Pro just adds the extras.")
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
                        }
                        .padding(.horizontal, 20)
                    }
                }
                VStack(spacing: 10) {
                    Button {
                        pro.unlock(); Haptics.success(); dismiss()
                    } label: {
                        Text("Unlock for $3.99").font(Theme.rounded(18, .bold))
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
