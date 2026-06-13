import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var sessions: [PracticeSession]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("tuningID") private var tuningID = Tuning.standardGuitar.id
    @AppStorage("leftHanded") private var leftHanded = false
    @AppStorage("showFingerNumbers") private var showFingerNumbers = true

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

                    Section("Practice defaults") {
                        Picker("Default tuning", selection: $tuningID) {
                            ForEach(Tuning.all) { Text($0.name).tag($0.id) }
                        }
                        Toggle("Show finger numbers", isOn: $showFingerNumbers)
                        Toggle("Left-handed diagrams", isOn: $leftHanded)
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                    }

                    Section("Pro") {
                        if pro.isPro {
                            Label("Fretwork Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Fretwork Pro") { showPaywall = true }
                                .foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }
                            .foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack {
                            Text("Logged sessions"); Spacer()
                            Text("\(sessions.count)").foregroundStyle(Theme.inkSoft)
                        }
                        Button("Reset practice history", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Fretwork keeps everything on your device. No account, no tracking, no subscription.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Reset practice history?", isPresented: $confirmReset) {
                Button("Delete all sessions", role: .destructive) { resetHistory() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes every logged drill and change round. Your settings stay.")
            }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "star.circle.fill").font(.system(size: 34)).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Fretwork Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("Pro progressions, custom drills & more").font(Theme.rounded(13, .regular))
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

    private func resetHistory() {
        for s in sessions { context.delete(s) }
        try? context.save()
        Haptics.success()
    }
}

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let perks = [
        ("metronome.fill", "Pro progressions", "Jazz ii–V–I, Canon, Andalusian cadence and more to play along with."),
        ("slider.horizontal.3", "Custom drills", "Choose your own fret range, string subsets and round lengths."),
        ("infinity", "One price, forever", "A single purchase — no monthly fee, no ads, ever.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 64)).foregroundStyle(Theme.accent)
                            .padding(.top, 28).accessibilityHidden(true)
                        Text("Fretwork Pro").font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                        Text("Everything in Fretwork is already free. Pro just adds the extras.")
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
                        Text("Unlock for $7.99").font(Theme.rounded(18, .bold))
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
