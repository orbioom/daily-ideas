import SwiftUI
import SwiftData

/// Settings: gameplay toggles, Pro, and About.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage(Pro.storageKey) private var isPro = false

    @State private var paywall: PaywallReason? = nil
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Gameplay") {
                    Toggle("Highlight Peers", isOn: $settings.highlightPeers)
                    Toggle("Highlight Same Number", isOn: $settings.highlightSameNumber)
                    Toggle("Conflict Highlighting", isOn: $settings.conflictHighlight)
                    Toggle("Auto Candidate Mode", isOn: $settings.autoCandidateMode)
                }

                Section {
                    Toggle("Mistake Limit (3 strikes)", isOn: $settings.mistakeLimitOn)
                    Toggle("Show Timer", isOn: $settings.showTimer)
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("Challenge & Feedback")
                } footer: {
                    Text("With the mistake limit on, three wrong digits ends the game.")
                }

                Section("Nonet Pro") {
                    if isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Theme.success)
                    } else {
                        Button {
                            paywall = .themes
                        } label: {
                            HStack {
                                Label("Unlock Nonet Pro", systemImage: "seal")
                                Spacer()
                                Text(Pro.price).foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    Button("Restore Purchase") {
                        isPro = UserDefaults.standard.bool(forKey: Pro.storageKey)
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Clear Saved Games & History", systemImage: "trash")
                    }
                }

                Section("About") {
                    aboutRow("Version", appVersion)
                    aboutRow("Engine", "Technique-graded generator")
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Nonet", systemImage: "info.circle")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywall) { PaywallView(reason: $0) }
            .alert("Clear All Data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) { clearAll() }
            } message: {
                Text("This deletes your saved games and completed history. Streaks and Pro are kept.")
            }
        }
    }

    private func aboutRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(value).foregroundStyle(Theme.textSecondary)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return v
    }

    private func clearAll() {
        if let games = try? context.fetch(FetchDescriptor<SavedGame>()) {
            for g in games { context.delete(g) }
        }
        if let recs = try? context.fetch(FetchDescriptor<GameRecord>()) {
            for r in recs { context.delete(r) }
        }
        try? context.save()
    }
}

/// About screen with the ad-free promise and credits.
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 96, height: 96)
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.top, 16)
                Text("Nonet")
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Clean, ad-free Sudoku with a real engine.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.textSecondary)

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        promise("checkmark.seal.fill", "No ads. No interruptions. Ever.")
                        promise("infinity", "Free daily puzzle and unlimited Easy & Medium.")
                        promise("brain.head.profile", "Hints that teach real logical techniques.")
                        promise("lock.open.fill", "One-time Pro unlock — never a subscription.")
                    }
                }
                .padding(.horizontal)

                Text("Nonet by Orbioom. Every puzzle is generated with a unique solution and graded by the hardest human technique it requires. The daily puzzle is seeded by date, so everyone solves the same board.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer(minLength: 20)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func promise(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.accent).frame(width: 26)
            Text(text).font(Theme.rounded(14)).foregroundStyle(Theme.textPrimary)
            Spacer()
        }
    }
}
