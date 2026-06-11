import SwiftUI

/// Reference ladder of everyday sound levels plus an interactive exposure
/// ("how long is safe?") calculator.
struct GuideView: View {
    @State private var calcLevel = 94.0
    @State private var calcHours = 1.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    calculatorCard
                    ladderCard
                    aboutCard
                }
                .padding(16)
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Guide")
        }
    }

    private var calculatorCard: some View {
        let dose = NoiseMath.dose(seconds: calcHours * 3600, at: calcLevel)
        let allowed = NoiseMath.allowedSeconds(at: calcLevel)
        return VStack(alignment: .leading, spacing: 14) {
            Label("Exposure calculator", systemImage: "function")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Level")
                    Spacer()
                    Text("\(Int(calcLevel)) dB")
                        .monospacedDigit()
                        .foregroundStyle(Theme.levelColor(calcLevel))
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                Slider(value: $calcLevel, in: 60...120, step: 1)
                    .accessibilityLabel("Sound level")
                    .accessibilityValue("\(Int(calcLevel)) decibels")
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Time at that level")
                    Spacer()
                    Text(calcHours == 1 ? "1 hour" : String(format: "%.1f hours", calcHours))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                Slider(value: $calcHours, in: 0.25...12, step: 0.25)
                    .accessibilityLabel("Exposure time")
                    .accessibilityValue(String(format: "%.2f hours", calcHours))
            }

            Divider()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dose > 0 ? String(format: "%.0f%%", dose) : "0%")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(dose >= 100 ? Theme.danger : (dose >= 50 ? Theme.caution : Theme.safe))
                    Text("of your daily noise dose")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(allowed.map { NoiseMath.formatTime($0) } ?? "Unlimited")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text("safe daily maximum")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if dose >= 100 {
                Label("That exposure exceeds the NIOSH daily limit — hearing protection is strongly recommended.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .soneCard()
    }

    private var ladderCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Everyday sounds", systemImage: "speaker.wave.3")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 10)
            ForEach(NoiseMath.referenceLevels, id: \.db) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.subheadline)
                        .foregroundStyle(Theme.levelColor(item.db))
                        .frame(width: 26)
                        .accessibilityHidden(true)
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(Int(item.db))")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Theme.levelColor(item.db))
                    Text("dB")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.vertical, 7)
                .accessibilityElement(children: .combine)
                if item.db != NoiseMath.referenceLevels.last?.db {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .soneCard()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How Sone measures", systemImage: "info.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("""
            Sone estimates sound pressure level from the iPhone microphone. Phone mics aren't certified instruments — readings are typically within a few dB of a dedicated meter at conversational levels, and you can tighten accuracy with the calibration offset in Settings.

            Exposure math follows the NIOSH recommended limit: 85 dB(A) averaged over 8 hours, with allowable time halving for every 3 dB increase. Your "daily dose" is the share of that limit you've used up.
            """)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .soneCard()
    }
}
