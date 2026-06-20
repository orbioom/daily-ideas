import SwiftUI

struct DropSettingsView: View {
    @AppStorage("drop_difficulty") private var difficulty: Int = 2
    @AppStorage("drop_first_player") private var firstPlayer: String = "human"
    @AppStorage("drop_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("drop_sound_enabled") private var soundEnabled: Bool = true
    @AppStorage("drop_pro_unlocked") private var proUnlocked: Bool = false
    @AppStorage("drop_onboarding_done") private var onboardingDone: Bool = true

    @State private var showProSheet: Bool = false
    @State private var showResetAlert: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.08, blue: 0.22),
                        Color(red: 0.10, green: 0.14, blue: 0.38)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Pro banner
                        if !proUnlocked {
                            proBanner
                        } else {
                            proUnlockedBadge
                        }

                        // Game settings
                        settingsGroup("Game") {
                            // Difficulty
                            VStack(alignment: .leading, spacing: 8) {
                                Label("AI Difficulty", systemImage: "cpu.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)

                                Picker("Difficulty", selection: $difficulty) {
                                    Text("Easy").tag(1)
                                    Text("Medium").tag(2)
                                    Text("Hard").tag(3)
                                }
                                .pickerStyle(.segmented)
                                .tint(DropTheme.accent)
                            }
                            .padding(16)

                            Divider().background(.white.opacity(0.1))

                            // First player
                            VStack(alignment: .leading, spacing: 8) {
                                Label("First Player", systemImage: "person.2.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)

                                Picker("First Player", selection: $firstPlayer) {
                                    Text("You (Red)").tag("human")
                                    Text("CPU (Yellow)").tag("cpu")
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(16)
                        }

                        // Feedback settings
                        settingsGroup("Feedback") {
                            settingsToggle(
                                title: "Haptics",
                                subtitle: "Vibration on drops and wins",
                                icon: "hand.tap.fill",
                                isOn: $hapticsEnabled
                            )

                            Divider().background(.white.opacity(0.1))

                            settingsToggle(
                                title: "Sound Effects",
                                subtitle: "Audio feedback during play",
                                icon: "speaker.wave.2.fill",
                                isOn: $soundEnabled
                            )
                        }

                        // About section
                        settingsGroup("About") {
                            aboutRow(title: "Version", value: "1.0.0")
                            Divider().background(.white.opacity(0.1))
                            aboutRow(title: "Developer", value: "Orbioom")
                            Divider().background(.white.opacity(0.1))
                            aboutRow(title: "AI Engine", value: "Minimax α-β")
                        }

                        // Reset / danger zone
                        settingsGroup("Data") {
                            Button {
                                showResetAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundStyle(.red)
                                    Text("Reset Onboarding")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.red)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(16)
                            }
                        }

                        Text("Drop v1.0.0 · Made with ❤️ by Orbioom")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.bottom, 20)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showProSheet) {
                DropProSheet(isPresented: $showProSheet)
            }
            .alert("Reset Onboarding", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    onboardingDone = false
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will show the onboarding screens again next time you launch the app.")
            }
        }
    }

    // MARK: - Pro Banner

    private var proBanner: some View {
        Button {
            showProSheet = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(DropTheme.accent.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "star.fill")
                        .foregroundStyle(DropTheme.accent)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock Drop Pro")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Extra themes · Unlimited history · $1.99")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Text("Unlock")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(DropTheme.accent))
                    .foregroundStyle(Color(red: 0.10, green: 0.14, blue: 0.38))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [DropTheme.accent.opacity(0.15), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(DropTheme.accent.opacity(0.4), lineWidth: 1)
                    )
            )
        }
    }

    private var proUnlockedBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(DropTheme.accent)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Drop Pro Unlocked")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Thank you for your support!")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DropTheme.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 4)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    private func settingsToggle(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(DropTheme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DropTheme.accent)
        }
        .padding(16)
    }

    private func aboutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(16)
    }
}

// MARK: - Pro Sheet

struct DropProSheet: View {
    @Binding var isPresented: Bool
    @AppStorage("drop_pro_unlocked") private var proUnlocked: Bool = false
    @State private var isPurchasing: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.22),
                    Color(red: 0.10, green: 0.14, blue: 0.38)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(DropTheme.accent.opacity(0.2))
                            .frame(width: 80, height: 80)
                        Image(systemName: "star.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(DropTheme.accent)
                    }
                    .shadow(color: DropTheme.accent.opacity(0.4), radius: 12)

                    Text("Drop Pro")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("One-time purchase · No subscription")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 40)

                // Features
                VStack(spacing: 16) {
                    proFeatureRow(icon: "paintpalette.fill", title: "Extra Themes", desc: "Dark mode, High-contrast, and more")
                    proFeatureRow(icon: "clock.arrow.circlepath", title: "Unlimited History", desc: "Track every game you've ever played")
                    proFeatureRow(icon: "heart.fill", title: "Support Development", desc: "Keep Drop ad-free and improving")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.07))
                )
                .padding(.horizontal, 24)

                // CTA
                VStack(spacing: 12) {
                    Button {
                        isPurchasing = true
                        // Simulate purchase flow — real IAP would use StoreKit 2
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            proUnlocked = true
                            isPurchasing = false
                            isPresented = false
                        }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(Color(red: 0.10, green: 0.14, blue: 0.38))
                                    .frame(height: 20)
                            } else {
                                Text("Unlock for $1.99")
                                    .font(.headline.weight(.bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(DropTheme.accent))
                        .foregroundStyle(Color(red: 0.10, green: 0.14, blue: 0.38))
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 24)

                    Button("Restore Purchase") {
                        // StoreKit restore
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                }

                Button("Maybe Later") {
                    isPresented = false
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func proFeatureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(DropTheme.accent)
                .font(.title3)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
    }
}
