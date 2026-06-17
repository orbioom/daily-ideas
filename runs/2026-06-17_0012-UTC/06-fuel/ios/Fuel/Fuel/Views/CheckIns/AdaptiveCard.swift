import SwiftUI

/// The adaptive-TDEE recalibration card. Shows the estimated true expenditure,
/// the recommended target change with rationale, and an "Apply" button. Gated
/// behind Pro (free users see a locked teaser).
struct AdaptiveCard: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings

    let profile: Profile
    let checkIns: [CheckIn]
    let activeTarget: Double
    let isPro: Bool
    let appliedBanner: Bool
    let onUnlock: () -> Void
    let onApply: (AdaptiveResult) -> Void

    private var result: AdaptiveResult? {
        AdaptiveEngine.recalibrate(samples: checkIns.map(\.sample),
                                   currentTarget: activeTarget,
                                   goal: profile.goal,
                                   plannedRatePercent: profile.goalRatePercent,
                                   weightKg: profile.currentWeightKg,
                                   aggressiveness: settings.aggressiveness,
                                   roundTo: settings.roundTo)
    }

    var body: some View {
        FuelCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    FuelSectionHeader(title: "Adaptive recalibration", systemImage: "wand.and.stars")
                    if !isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(FuelTheme.orange)
                    }
                }

                if checkIns.count < 2 {
                    Text("Log at least two weigh-ins about a week apart and Fuel will recalibrate your target.")
                        .font(.subheadline)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                } else if let result {
                    if isPro {
                        proBody(result)
                    } else {
                        lockedBody(result)
                    }
                } else {
                    Text("Not enough signal yet — keep logging weekly weigh-ins.")
                        .font(.subheadline)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                }
            }
        }
    }

    @ViewBuilder
    private func proBody(_ result: AdaptiveResult) -> some View {
        // Estimated TDEE + confidence
        HStack(spacing: 12) {
            metric(title: "Est. true TDEE",
                   value: result.estimatedTDEE.map { "\(Fmt.kcal($0))" } ?? "—",
                   sub: result.estimatedTDEE == nil ? "from trend" : "kcal/day")
            metric(title: "Observed rate",
                   value: Fmt.weeklyChange(result.observedWeeklyChangeKg, unit: settings.weightUnit),
                   sub: "smoothed")
        }

        confidenceChip(result.confidence)

        // Recommended target
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recommended target")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FuelTheme.primaryText(scheme))
                Spacer()
                Text("\(Fmt.kcal(result.recommendedTarget)) kcal")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(FuelTheme.orange)
            }
            if abs(result.targetDelta) >= 1 {
                Text("\(result.targetDelta > 0 ? "+" : "−")\(Fmt.kcal(abs(result.targetDelta))) kcal vs current \(Fmt.kcal(activeTarget))")
                    .font(.caption)
                    .foregroundStyle(FuelTheme.secondaryText(scheme))
            }
        }

        Text(result.rationale)
            .font(.subheadline)
            .foregroundStyle(FuelTheme.primaryText(scheme))
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(FuelTheme.subtleSurface(scheme)))

        if appliedBanner {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                Text("New target applied")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(FuelTheme.positive)
        } else {
            Button(abs(result.targetDelta) < 1 ? "Target is on track" : "Apply new target") {
                onApply(result)
            }
            .buttonStyle(FuelPrimaryButtonStyle())
            .disabled(abs(result.targetDelta) < 1)
            .opacity(abs(result.targetDelta) < 1 ? 0.6 : 1)
        }
    }

    @ViewBuilder
    private func lockedBody(_ result: AdaptiveResult) -> some View {
        Text("Fuel has a recalibration ready based on your trend. Unlock Pro to see the estimate and apply it automatically each week.")
            .font(.subheadline)
            .foregroundStyle(FuelTheme.secondaryText(scheme))
            .fixedSize(horizontal: false, vertical: true)

        // Blurred teaser of the number.
        HStack {
            Text("Recommended target")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FuelTheme.primaryText(scheme))
            Spacer()
            Text("\(Fmt.kcal(result.recommendedTarget)) kcal")
                .font(.title3.weight(.bold))
                .foregroundStyle(FuelTheme.orange)
                .blur(radius: 7)
                .accessibilityHidden(true)
        }

        Button {
            onUnlock()
        } label: {
            HStack {
                Image(systemName: "lock.open.fill")
                Text("Unlock adaptive recalibration")
            }
        }
        .buttonStyle(FuelPrimaryButtonStyle())
    }

    private func metric(title: String, value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(FuelTheme.secondaryText(scheme))
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(FuelTheme.primaryText(scheme))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(sub)
                .font(.caption2)
                .foregroundStyle(FuelTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(FuelTheme.subtleSurface(scheme)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(sub)")
    }

    private func confidenceChip(_ confidence: AdaptiveResult.Confidence) -> some View {
        let color: Color
        switch confidence {
        case .low: color = FuelTheme.warning
        case .medium: color = FuelTheme.teal
        case .high: color = FuelTheme.positive
        }
        return HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(confidence.rawValue.capitalized) confidence")
                .font(.caption.weight(.medium))
                .foregroundStyle(FuelTheme.secondaryText(scheme))
        }
        .accessibilityLabel("\(confidence.rawValue) confidence in this estimate")
    }
}
