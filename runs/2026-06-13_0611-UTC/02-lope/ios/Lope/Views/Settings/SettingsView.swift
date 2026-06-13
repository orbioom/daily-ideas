import SwiftUI
import SwiftData

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var scheme: ColorScheme? {
        switch self { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }
}

struct SettingsView: View {
    @AppStorage("voiceCues") private var voiceCues = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("useMetric") private var useMetric = true
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("activePlanID") private var activePlanID = "c25k"
    @AppStorage("isPro") private var isPro = false

    @Environment(\.modelContext) private var context
    @Query private var logs: [RunLog]
    @State private var showPaywall = false
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    if !isPro {
                        Section {
                            Button { showPaywall = true } label: { proBanner }.buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    Section("Coaching") {
                        Toggle("Voice cues", isOn: $voiceCues)
                        Toggle("Haptic cues", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }
                    Section("Units & look") {
                        Picker("Distance", selection: $useMetric) {
                            Text("Kilometres").tag(true)
                            Text("Miles").tag(false)
                        }
                        Picker("Theme", selection: $appearance) {
                            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                    }
                    Section("Progress") {
                        LabeledContent("Total runs logged", value: "\(logs.count)")
                        Button("Reset current plan progress", role: .destructive) { showReset = true }
                    }
                    Section {
                        if isPro {
                            Label("Lope Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.accent)
                        }
                        LabeledContent("Version", value: "1.0")
                    } header: { Text("About") } footer: {
                        Text("Lope coaches you entirely on your device. No account, no ads, no monthly fee.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView(isPro: $isPro) }
            .alert("Reset progress?", isPresented: $showReset) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetCurrentPlan() }
            } message: {
                Text("This deletes your logged runs for \(PlanLibrary.plan(id: activePlanID).name). Runs from other plans are kept.")
            }
            .onAppear { Haptics.enabled = hapticsEnabled }
        }
    }

    private func resetCurrentPlan() {
        for log in logs where log.planID == activePlanID { context.delete(log) }
        try? context.save()
        Haptics.success()
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.fill").font(.system(size: 28)).foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Lope Pro").font(Theme.display(19)).foregroundStyle(Theme.ink)
                Text("All plans, a custom interval builder, and Health export — one payment.")
                    .font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent.opacity(0.14)))
    }
}

struct PaywallView: View {
    @Binding var isPro: Bool
    @Environment(\.dismiss) private var dismiss
    private let perks: [(String, String)] = [
        ("figure.run", "Every training plan, including 5K→10K"),
        ("slider.horizontal.3", "Build your own interval workouts"),
        ("heart.fill", "Export runs to Apple Health"),
        ("xmark.circle", "No ads, no subscription — ever")
    ]
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "bolt.circle.fill").font(.system(size: 56)).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Lope Pro").font(Theme.display(32)).foregroundStyle(Theme.ink)
                Text("One payment. Yours for good.").font(.system(size: 16)).foregroundStyle(Theme.inkSoft)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(perks, id: \.0) { p in
                        HStack(spacing: 12) {
                            Image(systemName: p.0).foregroundStyle(Theme.accent).frame(width: 26)
                            Text(p.1).font(.system(size: 15)).foregroundStyle(Theme.ink)
                        }
                    }
                }.padding(.horizontal, 34)
                Spacer()
                Button { isPro = true; Haptics.success(); dismiss() } label: {
                    Text("Unlock for $9.99").font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .foregroundStyle(Theme.accentInk)
                }.padding(.horizontal, 24)
                Button("Maybe later") { dismiss() }
                    .font(.system(size: 15)).foregroundStyle(Theme.inkFaint).padding(.bottom, 24)
            }
        }
    }
}
