import SwiftUI
import SwiftData

/// First-run flow: intro → chronotype pick → wake/goal anchor. Persists choices
/// into SleepSettings and flips the onboarding flag.
struct OnboardingView: View {
    @Binding var hasOnboarded: Bool
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step = 0
    @State private var chronotype: Chronotype = .bear
    @State private var wakeTime: Date = SleepSettings.defaultWake()
    @State private var goalHours: Double = 8.0

    var body: some View {
        ZStack {
            DriftBackground()
            VStack {
                progressDots
                    .padding(.top, 12)

                TabView(selection: $step) {
                    intro.tag(0)
                    chronotypePicker.tag(1)
                    anchorPicker.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: step)

                controls
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i == step ? Theme.accent : Theme.textSecondary.opacity(0.3))
                    .frame(width: i == step ? 22 : 8, height: 8)
            }
        }
        .accessibilityLabel("Step \(step + 1) of 3")
    }

    // MARK: - Pages

    private var intro: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Theme.dusk)
                .accessibilityHidden(true)
            Text("Welcome to Drift")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.textPrimary)
            Text("A calm sleep coach that plans your bedtime around your body clock — and keeps your sleep debt honest. No account, no wearable, no paywall on the basics.")
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var chronotypePicker: some View {
        VStack(spacing: 16) {
            Text("What's your body clock?")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 12)
            Text("Pick the animal that fits how you naturally sleep. You can change it any time.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Chronotype.allCases) { type in
                        ChronotypeRow(type: type, isSelected: type == chronotype) {
                            chronotype = type
                            goalHours = type.targetSleepHours
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var anchorPicker: some View {
        VStack(spacing: 18) {
            Text("Anchor your schedule")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 12)
            Text("Drift plans backward from a steady wake time. Consistency here is what pays down sleep debt.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target wake time")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                    DatePicker("Target wake time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .frame(maxHeight: 130)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Nightly sleep goal")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(Format.duration(goalHours))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Slider(value: $goalHours, in: 6...10, step: 0.25)
                        .accessibilityValue(Format.duration(goalHours))
                }
            }
            .driftCard(padding: 18)
            .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack {
            if step > 0 {
                Button("Back") { withAnimation { step -= 1 } }
                    .buttonStyle(.bordered)
            }
            Spacer()
            Button(step < 2 ? "Continue" : "Start drifting") {
                if step < 2 {
                    withAnimation { step += 1 }
                } else {
                    finish()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func finish() {
        let settings = SettingsStore.current(context)
        settings.chronotype = chronotype
        settings.anchorWakeTime = wakeTime
        settings.goalHours = goalHours
        try? context.save()
        withAnimation { hasOnboarded = true }
    }
}

private struct ChronotypeRow: View {
    let type: Chronotype
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: type.symbol)
                    .font(.title2)
                    .foregroundStyle(type.tint)
                    .frame(width: 40)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(type.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(type.blurb)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary.opacity(0.4))
                    .accessibilityHidden(true)
            }
            .driftCard()
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .stroke(isSelected ? Theme.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
