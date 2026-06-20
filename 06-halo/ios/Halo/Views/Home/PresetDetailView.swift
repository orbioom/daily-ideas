import SwiftUI

struct PresetDetailView: View {
    let preset: HaloPreset
    var engine: BinauralEngine
    var settings: HaloSettings
    var onBegin: (Int, Int) -> Void  // (timerMinutes, moodBefore)

    @Environment(\.dismiss) private var dismiss

    @State private var moodBefore: Int = 3
    @State private var selectedTimerMinutes: Int = 20
    @State private var showHeadphonesReminder = true

    private let timerOptions: [(label: String, minutes: Int)] = [
        ("10 min", 10),
        ("20 min", 20),
        ("30 min", 30),
        ("45 min", 45),
        ("60 min", 60),
        ("Unlimited", 0)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                HaloTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: HaloTheme.spacingL) {
                        heroSection
                        descriptionCard
                        if showHeadphonesReminder {
                            HeadphonesReminder(onDismiss: {
                                withAnimation { showHeadphonesReminder = false }
                            })
                        }
                        moodSection
                        timerSection
                        beginButton
                    }
                    .padding(.horizontal, HaloTheme.spacingM)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(preset.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(HaloTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(HaloTheme.accent)
                }
            }
            .onAppear {
                selectedTimerMinutes = settings.defaultTimerMinutes
            }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: HaloTheme.spacingM) {
            ZStack {
                // Glow layers
                Circle()
                    .fill(preset.category.color.opacity(0.08))
                    .frame(width: 160, height: 160)
                Circle()
                    .fill(preset.category.color.opacity(0.12))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(preset.category.color.opacity(0.5), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .shadow(color: preset.category.color.opacity(0.7), radius: 12)

                Image(systemName: preset.icon)
                    .font(.system(size: 40))
                    .foregroundColor(preset.category.color)
                    .shadow(color: preset.category.color.opacity(0.8), radius: 10)
            }
            .padding(.top, HaloTheme.spacingM)

            VStack(spacing: 6) {
                Text(preset.name)
                    .font(HaloTheme.displayFont)
                    .foregroundColor(HaloTheme.textPrimary)

                Text(preset.tagline)
                    .font(HaloTheme.bodyFont)
                    .foregroundColor(HaloTheme.textSecondary)

                HStack(spacing: HaloTheme.spacingS) {
                    Label(preset.binauralHzDisplay, systemImage: "waveform")
                        .font(HaloTheme.labelFont)
                        .foregroundColor(preset.category.color)

                    Text("•")
                        .foregroundColor(HaloTheme.textTertiary)

                    Label(preset.recommendedDurationDisplay, systemImage: "clock")
                        .font(HaloTheme.labelFont)
                        .foregroundColor(HaloTheme.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: HaloTheme.spacingS) {
            Label("What it does", systemImage: "info.circle")
                .font(HaloTheme.labelFont)
                .foregroundColor(HaloTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            Text(preset.description)
                .font(HaloTheme.bodyFont)
                .foregroundColor(HaloTheme.textPrimary)
                .lineSpacing(4)

            Divider().background(Color.white.opacity(0.1))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Carrier")
                        .font(HaloTheme.captionFont)
                        .foregroundColor(HaloTheme.textTertiary)
                    Text("\(Int(preset.carrierHz)) Hz")
                        .font(HaloTheme.labelFont)
                        .foregroundColor(HaloTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .center, spacing: 2) {
                    Text("Beat")
                        .font(HaloTheme.captionFont)
                        .foregroundColor(HaloTheme.textTertiary)
                    Text(preset.binauralHzDisplay)
                        .font(HaloTheme.labelFont)
                        .foregroundColor(preset.category.color)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Category")
                        .font(HaloTheme.captionFont)
                        .foregroundColor(HaloTheme.textTertiary)
                    Text(preset.category.rawValue)
                        .font(HaloTheme.labelFont)
                        .foregroundColor(preset.category.color)
                }
            }
        }
        .padding(HaloTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                .fill(HaloTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: HaloTheme.spacingM) {
            Label("How are you feeling now?", systemImage: "heart")
                .font(HaloTheme.labelFont)
                .foregroundColor(HaloTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            MoodPicker(rating: $moodBefore)
        }
        .padding(HaloTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                .fill(HaloTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: HaloTheme.spacingM) {
            Label("Session duration", systemImage: "timer")
                .font(HaloTheme.labelFont)
                .foregroundColor(HaloTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: HaloTheme.spacingS) {
                ForEach(timerOptions, id: \.minutes) { option in
                    Button {
                        selectedTimerMinutes = option.minutes
                    } label: {
                        Text(option.label)
                            .font(HaloTheme.captionFont)
                            .foregroundColor(
                                selectedTimerMinutes == option.minutes
                                    ? HaloTheme.background
                                    : HaloTheme.textSecondary
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedTimerMinutes == option.minutes
                                            ? HaloTheme.accent
                                            : HaloTheme.surfaceElevated
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .flexibleGridLayout()
        }
        .padding(HaloTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                .fill(HaloTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var beginButton: some View {
        Button {
            onBegin(selectedTimerMinutes, moodBefore)
        } label: {
            HStack(spacing: HaloTheme.spacingS) {
                Image(systemName: "play.fill")
                Text("Begin Session")
                    .font(HaloTheme.headlineFont)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, HaloTheme.spacingM)
            .background(
                RoundedRectangle(cornerRadius: HaloTheme.radiusL)
                    .fill(
                        LinearGradient(
                            colors: [HaloTheme.primary, HaloTheme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: HaloTheme.accent.opacity(0.5), radius: 16, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Layout helper

extension View {
    func flexibleGridLayout() -> some View {
        self
    }
}
