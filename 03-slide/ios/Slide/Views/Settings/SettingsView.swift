import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var prefsArr: [SlidePrefs]
    @Environment(\.modelContext) private var ctx
    @State private var selectedTheme: SlideArtTheme = .classic

    private var prefs: SlidePrefs {
        if let p = prefsArr.first { return p }
        let p = SlidePrefs(); ctx.insert(p); return p
    }

    var body: some View {
        ZStack {
            SlideTheme.background.ignoresSafeArea()
            Form {
                Section("Gameplay") {
                    Picker(
                        "Default Grid Size",
                        selection: Binding(
                            get: { prefs.defaultSize },
                            set: { prefs.defaultSize = $0; try? ctx.save() }
                        )
                    ) {
                        Text("3×3").tag(3)
                        Text("4×4").tag(4)
                        Text("5×5").tag(5)
                    }
                    Toggle(
                        "Show Numbers on Tiles",
                        isOn: Binding(
                            get: { prefs.showNumbers },
                            set: { prefs.showNumbers = $0; try? ctx.save() }
                        )
                    )
                    Toggle(
                        "Haptic Feedback",
                        isOn: Binding(
                            get: { prefs.hapticsEnabled },
                            set: { prefs.hapticsEnabled = $0; try? ctx.save() }
                        )
                    )
                    Toggle(
                        "Daily Reminder",
                        isOn: Binding(
                            get: { prefs.dailyReminderEnabled },
                            set: { prefs.dailyReminderEnabled = $0; try? ctx.save() }
                        )
                    )
                }

                Section("Default Theme") {
                    ForEach(SlideArtTheme.allCases) { theme in
                        Button(action: {
                            guard !theme.isPro || prefs.isPro else { return }
                            selectedTheme = theme
                        }) {
                            HStack {
                                Circle()
                                    .fill(theme.accent)
                                    .frame(width: 20, height: 20)
                                Text(theme.name)
                                    .foregroundStyle(.primary)
                                if theme.isPro && !prefs.isPro {
                                    Text("PRO")
                                        .font(.caption2.bold())
                                        .foregroundStyle(SlideTheme.accent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(SlideTheme.accent.opacity(0.15),
                                                    in: .capsule)
                                }
                                Spacer()
                                if selectedTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(SlideTheme.accent)
                                }
                            }
                        }
                        .disabled(theme.isPro && !prefs.isPro)
                    }
                }

                Section("Pro") {
                    if prefs.isPro {
                        Label("Pro Unlocked — All themes available", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(SlideTheme.accent)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Slide Pro — $2.99").font(.headline)
                            Text("• Galaxy + Forest themes")
                            Text("• Unlimited stats history")
                        }
                        Button("Unlock Pro") {
                            prefs.isPro = true
                            try? ctx.save()
                        }
                        .foregroundStyle(SlideTheme.accent)
                        Button("Restore Purchase") {
                            // Stub — real StoreKit integration needed for production
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Bundle ID")
                        Spacer()
                        Text("com.orbioom.slide").foregroundStyle(.secondary).font(.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
    }
}
