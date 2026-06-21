import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var prefsQuery: [PushPrefs]
    @Environment(\.modelContext) private var modelContext

    @State private var showProPurchase: Bool = false
    @State private var purchaseSuccess: Bool = false

    private var prefs: PushPrefs {
        if let p = prefsQuery.first { return p }
        let p = PushPrefs()
        modelContext.insert(p)
        try? modelContext.save()
        return p
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Controls
                Section {
                    controlSchemePicker
                } header: {
                    Text("Controls")
                }

                // MARK: Gameplay
                Section {
                    Toggle(isOn: Binding(
                        get: { prefs.hapticsEnabled },
                        set: { prefs.hapticsEnabled = $0; save() }
                    )) {
                        Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    }
                    .tint(PushTheme.accent)

                    Toggle(isOn: Binding(
                        get: { prefs.showParMoves },
                        set: { prefs.showParMoves = $0; save() }
                    )) {
                        Label("Show Par Moves", systemImage: "star.fill")
                    }
                    .tint(PushTheme.accent)

                    Toggle(isOn: Binding(
                        get: { prefs.autoAdvance },
                        set: { prefs.autoAdvance = $0; save() }
                    )) {
                        Label("Auto-advance After Solve", systemImage: "arrow.right.circle.fill")
                    }
                    .tint(PushTheme.accent)
                } header: {
                    Text("Gameplay")
                }

                // MARK: Pro
                Section {
                    if prefs.isPro {
                        HStack {
                            Label("Expert Pack Unlocked", systemImage: "lock.open.fill")
                                .foregroundColor(PushTheme.boxOnTarget)
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(PushTheme.boxOnTarget)
                        }
                    } else {
                        Button {
                            showProPurchase = true
                        } label: {
                            HStack {
                                Label("Unlock Expert Pack", systemImage: "lock.fill")
                                    .foregroundColor(PushTheme.wall)
                                Spacer()
                                Text("$2.99")
                                    .font(.system(.callout, design: .rounded, weight: .bold))
                                    .foregroundColor(PushTheme.accent)
                            }
                        }

                        Button {
                            // Restore purchases
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                                .foregroundColor(PushTheme.wall.opacity(0.6))
                        }
                    }
                } header: {
                    Text("Pro")
                } footer: {
                    if !prefs.isPro {
                        Text("One-time purchase. Unlocks all 10 Expert levels. No subscription.")
                            .font(.system(.caption, design: .rounded))
                    }
                }

                // MARK: About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://orbioom.com/push/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: URL(string: "https://orbioom.com/push/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Push — A clean Sokoban puzzle game. No ads, no subscriptions.\nMade with care by Orbioom.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Unlock Expert Pack", isPresented: $showProPurchase) {
                Button("Buy — $2.99") {
                    // In production: StoreKit purchase flow
                    prefs.isPro = true
                    save()
                    purchaseSuccess = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Unlock all 10 Expert levels with a one-time $2.99 purchase. This is a simulated purchase for the prototype.")
            }
            .alert("Unlocked!", isPresented: $purchaseSuccess) {
                Button("Thanks!") { }
            } message: {
                Text("Expert Pack is now available. Enjoy the challenge!")
            }
        }
    }

    // MARK: - Control Scheme Picker

    private var controlSchemePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Control Scheme", systemImage: "gamecontroller.fill")
                .font(.system(.body))

            HStack(spacing: 0) {
                schemeButton(label: "Swipe", value: "swipe", icon: "hand.draw.fill")
                schemeButton(label: "D-pad", value: "dpad", icon: "dpad.fill")
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.systemFill))
            )
        }
        .padding(.vertical, 4)
    }

    private func schemeButton(label: String, value: String, icon: String) -> some View {
        let isSelected = prefs.controlScheme == value
        return Button {
            prefs.controlScheme = value
            save()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : PushTheme.wall.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? PushTheme.accent : Color.clear)
                    .padding(2)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: prefs.controlScheme)
    }

    private func save() {
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [PushRecord.self, PushPrefs.self, PushDailyResult.self, PushOnboarding.self], inMemory: true)
}
