import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var preferences: [AppPreferences]
    @Query private var records: [GameRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var showingProSheet = false
    @State private var showingClearConfirm = false

    private var prefs: AppPreferences {
        if let p = preferences.first { return p }
        let p = AppPreferences()
        modelContext.insert(p)
        return p
    }

    var body: some View {
        ZStack {
            AnteTheme.feltGreenDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Pro section
                    proCard

                    // Gameplay settings
                    settingsSection(title: "Gameplay") {
                        stepperRow(
                            label: "Winning Score",
                            value: prefs.winningScore,
                            range: 50...200,
                            step: 25
                        ) { prefs.winningScore = $0 }

                        Divider().background(AnteTheme.gold.opacity(0.15))

                        toggleRow(
                            label: "Show Card Count",
                            subtitle: "Display remaining deck size",
                            isOn: prefs.showCardCount
                        ) { prefs.showCardCount = $0 }
                    }

                    // Visual settings
                    settingsSection(title: "Appearance") {
                        toggleRow(
                            label: "Animations",
                            subtitle: "Card deal and flip animations",
                            isOn: prefs.animationsEnabled
                        ) { prefs.animationsEnabled = $0 }

                        if prefs.isPro {
                            Divider().background(AnteTheme.gold.opacity(0.15))
                            cardBackPicker
                        }
                    }

                    // Audio/Haptics
                    settingsSection(title: "Feedback") {
                        toggleRow(
                            label: "Haptic Feedback",
                            subtitle: "Vibration on card actions",
                            isOn: prefs.hapticsEnabled
                        ) { prefs.hapticsEnabled = $0 }

                        Divider().background(AnteTheme.gold.opacity(0.15))

                        toggleRow(
                            label: "Sound Effects",
                            subtitle: "Card sounds and fanfares",
                            isOn: prefs.soundEnabled
                        ) { prefs.soundEnabled = $0 }
                    }

                    // Data
                    settingsSection(title: "Data") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Game History")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Text("\(records.count) games recorded")
                                    .font(.caption)
                                    .foregroundColor(AnteTheme.textMuted)
                            }
                            Spacer()
                            Button("Clear") {
                                showingClearConfirm = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                        }
                    }

                    // About
                    VStack(spacing: 8) {
                        Text("Ante — Gin Rummy")
                            .font(.caption)
                            .foregroundColor(AnteTheme.textMuted)
                        Text("v1.0  •  com.orbioom.ante")
                            .font(.caption2)
                            .foregroundColor(AnteTheme.textMuted.opacity(0.6))
                        Text("No sign-in required. Fully offline. Your data stays on your device.")
                            .font(.caption2)
                            .foregroundColor(AnteTheme.textMuted.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(.bottom, 24)
                }
                .padding(20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingProSheet) {
            ProUpgradeView(prefs: prefs)
        }
        .confirmationDialog("Clear Game History?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
            Button("Clear All History", role: .destructive) {
                for record in records {
                    modelContext.delete(record)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(records.count) game records. Stats will be reset.")
        }
    }

    private var proCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(prefs.isPro ? AnteTheme.gold : AnteTheme.textMuted)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(prefs.isPro ? "Ante Pro — Active" : "Ante Pro")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(prefs.isPro ? "All features unlocked" : "Unlock unlimited history + custom backs")
                        .font(.caption)
                        .foregroundColor(AnteTheme.textMuted)
                }
                Spacer()
                if !prefs.isPro {
                    Text("$2.99")
                        .font(.headline)
                        .foregroundColor(AnteTheme.gold)
                }
            }

            if !prefs.isPro {
                VStack(alignment: .leading, spacing: 8) {
                    proFeatureRow("Unlimited game history & export")
                    proFeatureRow("Custom card back colors (3 options)")
                    proFeatureRow("Oklahoma variant (progressive scoring)")
                }

                Button {
                    showingProSheet = true
                } label: {
                    Text("Upgrade to Pro — $2.99")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AnteTheme.feltGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AnteTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(AnteTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(prefs.isPro ? AnteTheme.gold.opacity(0.5) : AnteTheme.gold.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func proFeatureRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.caption)
            .foregroundColor(AnteTheme.textSecondary)
    }

    private var cardBackPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Back Color")
                .font(.subheadline)
                .foregroundColor(.white)
            HStack(spacing: 12) {
                ForEach(["blue", "green", "red"], id: \.self) { colorName in
                    Button {
                        prefs.cardBackColor = colorName
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AnteTheme.cardBackColor(for: colorName))
                                .frame(width: 48, height: 64)
                            if prefs.cardBackColor == colorName {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title3)
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(prefs.cardBackColor == colorName ? AnteTheme.gold : Color.clear, lineWidth: 2)
                    )
                }
            }
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(AnteTheme.textMuted)
                .kerning(1.5)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(AnteTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func toggleRow(label: String, subtitle: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AnteTheme.textMuted)
            }
            Spacer()
            Toggle("", isOn: Binding(get: { isOn }, set: onChange))
                .labelsHidden()
                .tint(AnteTheme.gold)
        }
    }

    private func stepperRow(label: String, value: Int, range: ClosedRange<Int>, step: Int, onChange: @escaping (Int) -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Current: \(value) points")
                    .font(.caption)
                    .foregroundColor(AnteTheme.textMuted)
            }
            Spacer()
            HStack(spacing: 12) {
                Button {
                    let newVal = max(range.lowerBound, value - step)
                    onChange(newVal)
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundColor(AnteTheme.gold)
                }
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 44)
                    .multilineTextAlignment(.center)

                Button {
                    let newVal = min(range.upperBound, value + step)
                    onChange(newVal)
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(AnteTheme.gold)
                }
                .disabled(value >= range.upperBound)
            }
        }
    }
}

struct ProUpgradeView: View {
    let prefs: AppPreferences
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AnteTheme.feltGreenDark
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "crown.fill")
                    .font(.system(size: 72))
                    .foregroundColor(AnteTheme.gold)
                    .shadow(color: AnteTheme.gold.opacity(0.5), radius: 20)

                VStack(spacing: 8) {
                    Text("Ante Pro")
                        .font(.largeTitle.weight(.black))
                        .foregroundColor(.white)
                    Text("One-time purchase • No subscription")
                        .font(.subheadline)
                        .foregroundColor(AnteTheme.textMuted)
                }

                VStack(alignment: .leading, spacing: 16) {
                    proRow(icon: "clock.fill", title: "Unlimited History", body: "Keep every game on record forever with full stats.")
                    proRow(icon: "paintpalette.fill", title: "Custom Card Backs", body: "Choose from blue, green, or red card backs.")
                    proRow(icon: "chart.bar.fill", title: "Oklahoma Variant", body: "Progressive scoring mode with spade multipliers.")
                }
                .padding(20)
                .background(AnteTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        // In production: initiate StoreKit purchase
                        prefs.isPro = true
                        dismiss()
                    } label: {
                        Text("Purchase for $2.99")
                            .font(.headline)
                            .foregroundColor(AnteTheme.feltGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AnteTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button("Restore Purchase") {
                        // StoreKit restore
                    }
                    .font(.subheadline)
                    .foregroundColor(AnteTheme.textMuted)
                }

                Text("Payment processed by Apple. Non-refundable.")
                    .font(.caption2)
                    .foregroundColor(AnteTheme.textMuted.opacity(0.6))
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 28)
        }
    }

    private func proRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(AnteTheme.gold)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(body)
                    .font(.caption)
                    .foregroundColor(AnteTheme.textSecondary)
            }
        }
    }
}
