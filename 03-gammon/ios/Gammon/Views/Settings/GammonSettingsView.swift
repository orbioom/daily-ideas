import SwiftUI
import SwiftData

struct GammonSettingsView: View {
    @Binding var boardColorSchemeRaw: String
    @Binding var aiDifficulty: Int
    @Binding var gameModeRaw: String
    @Binding var hapticsEnabled: Bool

    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("showHints") private var showHints = true
    @AppStorage("hasProUnlock") private var hasProUnlock = false

    @State private var showProSheet = false
    @State private var showResetConfirm = false
    @Environment(\.modelContext) private var modelContext
    @Query private var results: [GammonResult]

    private var selectedScheme: BoardColorScheme {
        BoardColorScheme(rawValue: boardColorSchemeRaw) ?? .classic
    }

    var body: some View {
        ZStack {
            GammonTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: GammonTheme.sectionSpacing) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Settings")
                            .font(GammonTheme.titleFont)
                            .foregroundStyle(GammonTheme.textPrimary)
                        Text("Customize your Gammon experience")
                            .font(.subheadline)
                            .foregroundStyle(GammonTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    // Game Settings
                    settingsSection(title: "Game", icon: "gamecontroller.fill") {
                        // Game Mode
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Game Mode")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(GammonTheme.textPrimary)

                            HStack(spacing: 0) {
                                modeButton(label: "vs AI", value: "ai")
                                modeButton(label: "2 Player", value: "2player", proRequired: true)
                            }
                            .background(GammonTheme.surfaceHigh)
                            .cornerRadius(10)
                        }

                        Divider().background(GammonTheme.surfaceHigh)

                        // AI Difficulty
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("AI Difficulty")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(GammonTheme.textPrimary)
                                Spacer()
                                Text(difficultyName(aiDifficulty))
                                    .font(.caption)
                                    .foregroundStyle(GammonTheme.accent)
                            }

                            HStack(spacing: 0) {
                                ForEach(1...3, id: \.self) { level in
                                    difficultyButton(level: level)
                                }
                            }
                            .background(GammonTheme.surfaceHigh)
                            .cornerRadius(10)

                            Text(difficultyDescription(aiDifficulty))
                                .font(.caption)
                                .foregroundStyle(GammonTheme.textSecondary)
                        }

                        Divider().background(GammonTheme.surfaceHigh)

                        // Show Hints
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Move Hints")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(GammonTheme.textPrimary)
                                Text("Highlight valid destinations")
                                    .font(.caption)
                                    .foregroundStyle(GammonTheme.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $showHints)
                                .tint(GammonTheme.accent)
                                .labelsHidden()
                        }
                    }

                    // Board Appearance
                    settingsSection(title: "Board Theme", icon: "paintpalette.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color Scheme")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(GammonTheme.textPrimary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(BoardColorScheme.allCases) { scheme in
                                    BoardSchemeCard(
                                        scheme: scheme,
                                        isSelected: scheme == selectedScheme,
                                        isLocked: scheme != .classic && !hasProUnlock
                                    ) {
                                        if scheme == .classic || hasProUnlock {
                                            boardColorSchemeRaw = scheme.rawValue
                                        } else {
                                            showProSheet = true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Audio & Haptics
                    settingsSection(title: "Feedback", icon: "speaker.wave.2.fill") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sound Effects")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(GammonTheme.textPrimary)
                                Text("Dice rolls, moves, and wins")
                                    .font(.caption)
                                    .foregroundStyle(GammonTheme.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $soundEnabled)
                                .tint(GammonTheme.accent)
                                .labelsHidden()
                        }

                        Divider().background(GammonTheme.surfaceHigh)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haptic Feedback")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(GammonTheme.textPrimary)
                                Text("Vibrations on moves and wins")
                                    .font(.caption)
                                    .foregroundStyle(GammonTheme.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $hapticsEnabled)
                                .tint(GammonTheme.accent)
                                .labelsHidden()
                        }
                    }

                    // Pro Unlock
                    if !hasProUnlock {
                        proUnlockBanner()
                    } else {
                        proActiveBadge()
                    }

                    // About / Reset
                    settingsSection(title: "About", icon: "info.circle.fill") {
                        VStack(spacing: 12) {
                            infoRow(label: "App Version", value: "1.0.0")
                            Divider().background(GammonTheme.surfaceHigh)
                            infoRow(label: "Games Played", value: "\(results.count)")
                            Divider().background(GammonTheme.surfaceHigh)
                            Button(role: .destructive) {
                                showResetConfirm = true
                            } label: {
                                HStack {
                                    Text("Reset All Stats")
                                        .font(.subheadline)
                                        .foregroundStyle(GammonTheme.loseColor)
                                    Spacer()
                                    Image(systemName: "trash")
                                        .foregroundStyle(GammonTheme.loseColor)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, GammonTheme.cardPadding)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showProSheet) {
            ProUnlockSheet(isPresented: $showProSheet, hasProUnlock: $hasProUnlock)
        }
        .confirmationDialog("Reset all statistics?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset Stats", role: .destructive) {
                resetStats()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all game history. This cannot be undone.")
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(GammonTheme.accent)
                Text(title)
                    .font(GammonTheme.headingFont)
                    .foregroundStyle(GammonTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(GammonTheme.cardPadding)
            .gammonCard()
        }
    }

    @ViewBuilder
    private func modeButton(label: String, value: String, proRequired: Bool = false) -> some View {
        Button {
            if proRequired && !hasProUnlock {
                showProSheet = true
            } else {
                gameModeRaw = value
            }
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                if proRequired && !hasProUnlock {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                }
            }
            .foregroundStyle(gameModeRaw == value ? GammonTheme.background : GammonTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(gameModeRaw == value ? GammonTheme.accent : Color.clear)
            .cornerRadius(9)
            .padding(2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func difficultyButton(level: Int) -> some View {
        Button {
            aiDifficulty = level
        } label: {
            Text(difficultyName(level))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(aiDifficulty == level ? GammonTheme.background : GammonTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(aiDifficulty == level ? GammonTheme.accent : Color.clear)
                .cornerRadius(9)
                .padding(2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func proUnlockBanner() -> some View {
        Button { showProSheet = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(GammonTheme.accent.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(GammonTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Unlock Gammon Pro")
                        .font(.headline)
                        .foregroundStyle(GammonTheme.textPrimary)
                    Text("2-Player mode • 3 board themes • Full stats")
                        .font(.caption)
                        .foregroundStyle(GammonTheme.textSecondary)
                }

                Spacer()

                Text("$2.99")
                    .font(.headline.bold())
                    .foregroundStyle(GammonTheme.accent)
            }
            .padding(GammonTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: GammonTheme.cornerRadius)
                    .fill(GammonTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: GammonTheme.cornerRadius)
                            .stroke(GammonTheme.accent.opacity(0.5), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func proActiveBadge() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(GammonTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Gammon Pro")
                    .font(.headline)
                    .foregroundStyle(GammonTheme.textPrimary)
                Text("All features unlocked")
                    .font(.caption)
                    .foregroundStyle(GammonTheme.textSecondary)
            }
            Spacer()
        }
        .padding(GammonTheme.cardPadding)
        .gammonCard()
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(GammonTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(GammonTheme.textPrimary)
        }
    }

    // MARK: - Helpers

    private func difficultyName(_ level: Int) -> String {
        switch level {
        case 1: return "Easy"
        case 2: return "Medium"
        default: return "Hard"
        }
    }

    private func difficultyDescription(_ level: Int) -> String {
        switch level {
        case 1: return "Random moves — great for beginners."
        case 2: return "Smart positional play — a real challenge."
        default: return "Aggressive optimization — for experts only."
        }
    }

    private func resetStats() {
        for result in results {
            modelContext.delete(result)
        }
        try? modelContext.save()
    }
}

// MARK: - Board Scheme Card

struct BoardSchemeCard: View {
    let scheme: BoardColorScheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Mini board preview
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(scheme.boardSurface)
                        .frame(height: 48)
                        .overlay(
                            HStack(spacing: 2) {
                                ForEach(0..<4, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(i % 2 == 0 ? scheme.pointColorA : scheme.pointColorB)
                                        .frame(width: 10)
                                }
                            }
                            .padding(.horizontal, 6)
                        )

                    if isLocked {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.55))
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundStyle(GammonTheme.accent)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? GammonTheme.accent : Color.clear, lineWidth: 2)
                )

                Text(scheme.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? GammonTheme.accent : GammonTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pro Unlock Sheet

struct ProUnlockSheet: View {
    @Binding var isPresented: Bool
    @Binding var hasProUnlock: Bool

    @State private var isPurchasing = false

    var body: some View {
        ZStack {
            GammonTheme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Crown icon
                ZStack {
                    Circle()
                        .fill(GammonTheme.accent.opacity(0.15))
                        .frame(width: 110, height: 110)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(GammonTheme.accent)
                }

                VStack(spacing: 10) {
                    Text("Gammon Pro")
                        .font(GammonTheme.titleFont)
                        .foregroundStyle(GammonTheme.textPrimary)
                    Text("One-time purchase. No subscription.")
                        .font(.subheadline)
                        .foregroundStyle(GammonTheme.textSecondary)
                }

                // Feature list
                VStack(alignment: .leading, spacing: 14) {
                    ProFeatureRow(icon: "person.2.fill", text: "2-Player pass-and-play mode")
                    ProFeatureRow(icon: "paintpalette.fill", text: "3 additional board themes")
                    ProFeatureRow(icon: "chart.bar.fill", text: "Full statistics & game history")
                    ProFeatureRow(icon: "infinity", text: "All future features included")
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        simulatePurchase()
                    } label: {
                        HStack(spacing: 8) {
                            if isPurchasing {
                                ProgressView().tint(GammonTheme.background)
                            }
                            Text(isPurchasing ? "Processing..." : "Unlock for $2.99")
                        }
                        .gammonButton(large: true)
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 24)

                    Button("Restore Purchase") {
                        // Restore logic
                    }
                    .font(.subheadline)
                    .foregroundStyle(GammonTheme.textSecondary)

                    Button("Maybe Later") {
                        isPresented = false
                    }
                    .font(.subheadline)
                    .foregroundStyle(GammonTheme.textMuted)
                }
                .padding(.bottom, 32)
            }
        }
    }

    private func simulatePurchase() {
        isPurchasing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            hasProUnlock = true
            isPurchasing = false
            isPresented = false
        }
    }
}

struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(GammonTheme.accent)
                .frame(width: 28)
            Text(text)
                .font(.body)
                .foregroundStyle(GammonTheme.textPrimary)
            Spacer()
        }
    }
}

#Preview {
    GammonSettingsView(
        boardColorSchemeRaw: .constant("Classic"),
        aiDifficulty: .constant(2),
        gameModeRaw: .constant("ai"),
        hapticsEnabled: .constant(true)
    )
    .modelContainer(for: GammonResult.self, inMemory: true)
    .preferredColorScheme(.dark)
}
