import SwiftUI
import StoreKit

struct OrbSettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("showAimLine") private var showAimLine = true
    @AppStorage("colorBlindMode") private var colorBlindMode = false
    @AppStorage("isPro") private var isPro = false
    @AppStorage("highestLevelReached") private var highestLevelReached = 1
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @State private var showingProSheet = false
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                OrbTheme.background.ignoresSafeArea()

                List {
                    // Gameplay settings
                    Section {
                        ToggleRow(
                            title: "Haptics",
                            icon: "hand.tap.fill",
                            color: .orange,
                            isOn: $hapticsEnabled
                        )
                        ToggleRow(
                            title: "Sound Effects",
                            icon: "speaker.wave.2.fill",
                            color: .blue,
                            isOn: $soundEnabled
                        )
                        ToggleRow(
                            title: "Show Aim Line",
                            icon: "scope",
                            color: OrbTheme.accent,
                            isOn: $showAimLine
                        )
                        ToggleRow(
                            title: "Color Blind Mode",
                            icon: "eye.fill",
                            color: .green,
                            isOn: $colorBlindMode
                        )
                    } header: {
                        Text("Gameplay")
                            .foregroundColor(OrbTheme.textSecondary)
                    }
                    .listRowBackground(OrbTheme.surface)

                    // Pro upgrade section
                    Section {
                        Button(action: { showingProSheet = true }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(OrbTheme.starGold)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isPro ? "Pro Unlocked" : "Unlock Pro")
                                        .foregroundColor(.white)
                                        .font(.body)
                                    Text(isPro ? "Thanks for your support!" : "Levels 21-50 • Themes • More")
                                        .font(.caption)
                                        .foregroundColor(OrbTheme.textSecondary)
                                }

                                Spacer()

                                if isPro {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Text("$2.99")
                                        .foregroundColor(OrbTheme.accent)
                                        .font(.subheadline.bold())
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(OrbTheme.textSecondary)
                                        .font(.caption)
                                }
                            }
                        }
                    } header: {
                        Text("Pro Version")
                            .foregroundColor(OrbTheme.textSecondary)
                    }
                    .listRowBackground(OrbTheme.surface)

                    // Other options
                    Section {
                        Button(action: { showingResetAlert = true }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 28)
                                Text("Reset Progress")
                                    .foregroundColor(.red)
                            }
                        }

                        Button(action: { hasSeenOnboarding = false }) {
                            HStack {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(OrbTheme.accent)
                                    .frame(width: 28)
                                Text("Show Tutorial Again")
                                    .foregroundColor(.white)
                            }
                        }
                    } header: {
                        Text("Other")
                            .foregroundColor(OrbTheme.textSecondary)
                    }
                    .listRowBackground(OrbTheme.surface)

                    // App info footer
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text("Orb — Bubble Shooter")
                                    .font(.caption.bold())
                                    .foregroundColor(OrbTheme.textSecondary)
                                Text("Version 1.0.0  •  No ads, ever.")
                                    .font(.caption2)
                                    .foregroundColor(OrbTheme.textSecondary.opacity(0.6))
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingProSheet) {
                ProUnlockSheet(isPro: $isPro)
            }
            .alert("Reset Progress?", isPresented: $showingResetAlert) {
                Button("Reset", role: .destructive) {
                    highestLevelReached = 1
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset your level progress. Stats will remain.")
            }
        }
    }
}

struct ToggleRow: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 28)
                Text(title)
                    .foregroundColor(.white)
            }
        }
        .tint(OrbTheme.accent)
    }
}

struct ProUnlockSheet: View {
    @Binding var isPro: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            OrbTheme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [OrbTheme.starGold, Color(red: 1.0, green: 0.6, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: OrbTheme.starGold.opacity(0.5), radius: 20)
                    .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Orb Pro")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("One-time purchase, no subscription")
                        .font(.subheadline)
                        .foregroundColor(OrbTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ProFeatureRow(icon: "square.grid.3x3.fill", text: "30 additional levels (21–50)")
                    ProFeatureRow(icon: "eye.fill", text: "Color blind accessibility mode")
                    ProFeatureRow(icon: "paintpalette.fill", text: "Premium space themes")
                    ProFeatureRow(icon: "heart.fill", text: "Support solo indie development")
                    ProFeatureRow(icon: "nosign", text: "No ads — ever")
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        // In production: StoreKit purchase flow here
                        isPro = true
                        dismiss()
                    }) {
                        Text("Unlock Pro — $2.99")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(OrbTheme.starGold)
                            .cornerRadius(16)
                    }

                    Button("Restore Purchase") {
                        // In production: StoreKit restore flow here
                        dismiss()
                    }
                    .foregroundColor(OrbTheme.textSecondary)
                    .font(.subheadline)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.large])
    }
}

struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(OrbTheme.starGold)
                .frame(width: 24)
            Text(text)
                .foregroundColor(OrbTheme.textPrimary)
                .font(.body)
        }
    }
}
