import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var logs: [WorkoutLog]
    @Query private var progressRecords: [ExerciseProgress]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("defaultRest") private var defaultRest = 60
    @AppStorage("keepAwake") private var keepAwake = true
    @AppStorage("voiceCues") private var voiceCues = true

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

                    Section("Session defaults") {
                        Picker("Default rest", selection: $defaultRest) {
                            Text("45s").tag(45); Text("60s").tag(60)
                            Text("90s").tag(90); Text("120s").tag(120)
                        }
                        Toggle("Keep screen awake during sessions", isOn: $keepAwake)
                    } footer: {
                        Text("Each level prescribes its own rest; the default is used when a level doesn't specify one. Reps and holds are measured in reps and seconds.")
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                        Toggle("Voice & sound cues", isOn: $voiceCues)
                    }

                    Section("Pro") {
                        if pro.isPro {
                            Label("Lever Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Lever Pro") { showPaywall = true }
                                .foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }
                            .foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack {
                            Text("Logged sessions"); Spacer()
                            Text("\(logs.count)").foregroundStyle(Theme.inkSoft)
                        }
                        Button("Reset history", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Lever keeps everything on your device. No account, no tracking, no subscription.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Reset history?", isPresented: $confirmReset) {
                Button("Delete all data", role: .destructive) { resetHistory() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes every logged session and resets your level on each movement. Your settings stay.")
            }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.circle.fill").font(.system(size: 34)).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Lever Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("Advanced skill ladders & custom routines").font(Theme.rounded(13, .regular))
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
        for log in logs { context.delete(log) }
        for rec in progressRecords { context.delete(rec) }
        try? context.save()
        Haptics.success()
    }
}

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let perks = [
        ("figure.gymnastics", "Advanced skill ladders", "Planche, front lever, muscle-up, archer and one-arm progressions for every movement."),
        ("slider.horizontal.3", "Custom routines", "Build your own multi-movement sessions with the sets, reps and rest you want."),
        ("infinity", "One price, forever", "A single purchase — no subscription, no ads, ever.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 64)).foregroundStyle(Theme.accent)
                            .padding(.top, 28).accessibilityHidden(true)
                        Text("Lever Pro").font(Theme.rounded(30, .bold)).foregroundStyle(Theme.ink)
                        Text("The full ladder is already free. Pro unlocks the elite rungs and custom routines.")
                            .font(Theme.rounded(16, .regular)).foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center).padding(.horizontal, 28)
                        VStack(spacing: 14) {
                            ForEach(perks, id: \.0) { perk in
                                HStack(spacing: 14) {
                                    Image(systemName: perk.0).font(.system(size: 24))
                                        .foregroundStyle(Theme.accent).frame(width: 36)
                                        .accessibilityHidden(true)
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
                        Text("Unlock for $8.99").font(Theme.rounded(18, .bold))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    Button("Restore purchase") { pro.restore(); dismiss() }
                        .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
                    Button("Maybe later") { dismiss() }
                        .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
        }
    }
}
