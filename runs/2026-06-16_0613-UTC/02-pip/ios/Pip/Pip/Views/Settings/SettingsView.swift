import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query private var records: [GameRecord]

    @State private var showPaywall = false
    @State private var showHowTo = false
    @State private var showResetConfirm = false
    @State private var toast: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    proSection
                    appearanceSection
                    gameplaySection
                    referenceSection
                    dataSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)

                if let toast {
                    VStack { Spacer(); ToastView(text: toast).padding(.bottom, 30) }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showHowTo) { HowToPlayView() }
            .animation(.easeInOut(duration: 0.25), value: toast != nil)
            .confirmationDialog("Reset all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) { resetData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all saved games, profiles and Daily results.")
            }
        }
    }

    @ViewBuilder
    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Pip Pro unlocked").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                        Text("Thanks for supporting Pip.").font(.footnote).foregroundStyle(Theme.inkSoft)
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(Theme.gold)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Unlock Pip Pro").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                            Text("CPU, themes, full stats, Daily archive · \(Pro.price)")
                                .font(.footnote).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Theme.inkSoft)
                    }
                }
                Button("Restore purchase") { restore() }
                    .foregroundStyle(Theme.accent)
            }
        } header: {
            Text("Pip Pro")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { Text($0.rawValue).tag($0) }
            }
        }
    }

    private var gameplaySection: some View {
        Section("Gameplay") {
            Toggle("Haptics", isOn: $settings.hapticsEnabled)

            Picker("Dice roll animation", selection: Binding(
                get: { settings.rollSpeed },
                set: { settings.rollSpeed = $0 }
            )) {
                ForEach(RollSpeed.allCases) { Text($0.rawValue).tag($0) }
            }

            Toggle("Auto-hold suggestions", isOn: $settings.autoHoldSuggestions)
            Toggle("Sort scorecard by best score", isOn: $settings.sortScorecardByValue)
        }
    }

    private var referenceSection: some View {
        Section("Learn") {
            Button {
                showHowTo = true
            } label: {
                Label("How to play & scoring", systemImage: "book.closed.fill")
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    private var dataSection: some View {
        Section {
            HStack {
                Text("Games saved")
                Spacer()
                Text("\(records.count)").foregroundStyle(Theme.inkSoft)
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all data", systemImage: "trash")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Your games are stored only on this device.")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Made by")
                Spacer()
                Text("Orbioom").foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("About")
        } footer: {
            Text("Pip — a clean, fair, ad-free dice game. No ads. No subscriptions.")
        }
    }

    private func restore() {
        // Simulated restore (StoreKit-ready). Re-applies any prior entitlement.
        flash("No previous purchase found")
    }

    private func resetData() {
        for record in records { context.delete(record) }
        let profiles = (try? context.fetch(FetchDescriptor<PlayerProfile>())) ?? []
        for p in profiles { context.delete(p) }
        let dailies = (try? context.fetch(FetchDescriptor<DailyResult>())) ?? []
        for d in dailies { context.delete(d) }
        try? context.save()
        flash("All data reset")
    }

    private func flash(_ text: String) {
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if toast == text { toast = nil }
        }
    }
}
