import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("hardMode") private var hardMode = false
    @AppStorage("colorBlind") private var colorBlind = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("isPro") private var isPro = false

    @Environment(\.modelContext) private var context
    @Query private var records: [GameRecord]
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
                    Section {
                        Toggle("Hard mode", isOn: $hardMode)
                    } header: { Text("Gameplay") } footer: {
                        Text("In hard mode, any revealed hints must be used in your next guess.")
                    }
                    Section("Accessibility & look") {
                        Toggle("High-contrast colors", isOn: $colorBlind)
                            .onChange(of: colorBlind) { _, v in Theme.colorBlind = v }
                        Picker("Theme", selection: $appearance) {
                            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                        Toggle("Haptic feedback", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }
                    Section("Your record") {
                        LabeledContent("Daily games", value: "\(records.filter { $0.isDaily }.count)")
                        LabeledContent("Practice games", value: "\(records.filter { !$0.isDaily }.count)")
                        Button("Reset statistics", role: .destructive) { showReset = true }
                    }
                    Section {
                        if isPro {
                            Label("Lexicon Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.accent)
                        }
                        LabeledContent("Words", value: "\(WordList.words.count)")
                        LabeledContent("Version", value: "1.0")
                    } header: { Text("About") } footer: {
                        Text("A complete word game with no ads and no timers. The full archive is free.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onAppear { Haptics.enabled = hapticsEnabled; Theme.colorBlind = colorBlind }
            .sheet(isPresented: $showPaywall) { PaywallView(isPro: $isPro) }
            .alert("Reset statistics?", isPresented: $showReset) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { reset() }
            } message: {
                Text("This deletes every game record and clears your streaks. This cannot be undone.")
            }
        }
    }

    private func reset() {
        for r in records { context.delete(r) }
        try? context.save()
        // clear any in-progress daily/archive boards
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("lex.progress.") {
            UserDefaults.standard.removeObject(forKey: key)
        }
        Haptics.warning()
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "paintpalette.fill").font(.system(size: 26)).foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Lexicon Pro").font(Theme.rounded(19)).foregroundStyle(Theme.ink)
                Text("Tile themes and 6- and 7-letter modes — one payment, no ads.")
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
        ("textformat.size", "6- and 7-letter word modes"),
        ("paintpalette", "A set of tile & background themes"),
        ("infinity", "Unlimited practice, no daily wait"),
        ("nosign", "No ads, no timers, ever")
    ]
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "paintpalette.fill").font(.system(size: 52)).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Lexicon Pro").font(Theme.rounded(32)).foregroundStyle(Theme.ink)
                Text("One payment. No subscription.").font(.system(size: 16)).foregroundStyle(Theme.inkSoft)
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
                    Text("Unlock for $3.99").font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .foregroundStyle(.white)
                }.padding(.horizontal, 24)
                Button("Maybe later") { dismiss() }
                    .font(.system(size: 15)).foregroundStyle(Theme.inkFaint).padding(.bottom, 24)
            }
        }
    }
}
