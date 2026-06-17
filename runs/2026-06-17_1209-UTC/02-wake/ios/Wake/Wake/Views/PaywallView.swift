import SwiftUI

/// Why the paywall was shown — drives copy.
enum PaywallReason: Identifiable {
    case builder
    case stats
    case unlimited
    case general

    var id: String {
        switch self {
        case .builder: return "builder"
        case .stats: return "stats"
        case .unlimited: return "unlimited"
        case .general: return "general"
        }
    }

    var symbol: String {
        switch self {
        case .builder: return "slider.horizontal.3"
        case .stats: return "chart.xyaxis.line"
        case .unlimited: return "infinity"
        case .general: return "crown.fill"
        }
    }

    var title: String {
        switch self {
        case .builder: return "Build your own workouts"
        case .stats: return "Unlock advanced analytics"
        case .unlimited: return "Save unlimited workouts"
        case .general: return "Wake Pro"
        }
    }

    var blurb: String {
        switch self {
        case .builder:
            return "The custom set builder is part of Wake Pro — design any workout, rep by rep."
        case .stats:
            return "Pace-per-100 trends and SWOLF analysis are part of Wake Pro."
        case .unlimited:
            return "Free includes the built-in workouts. Wake Pro lets you save as many of your own as you like."
        case .general:
            return "One simple, one-time unlock for everything Wake can do."
        }
    }
}

/// Pricing constants for the simulated one-time Pro unlock.
enum Pro {
    static let priceLabel = "$4.99"
}

/// One-time Pro unlock sheet. Demo unlock sets isPro = true (StoreKit wires in for production).
struct PaywallView: View {
    let reason: PaywallReason
    @AppStorage(PrefKey.isPro) private var isPro = false
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoreNote = false

    private let perks: [(String, String)] = [
        ("slider.horizontal.3", "Custom workout builder"),
        ("chart.xyaxis.line", "Pace trends & SWOLF analysis"),
        ("infinity", "Unlimited saved workouts")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    ZStack {
                        Circle().fill(Theme.accentSoft).frame(width: 110, height: 110)
                        Image(systemName: reason.symbol)
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.top, 8)
                    .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(reason.title)
                            .font(Theme.rounded(26, .bold))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                        Text(reason.blurb)
                            .font(.body)
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(perks, id: \.1) { perk in
                            HStack(spacing: 12) {
                                Image(systemName: perk.0)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 26)
                                    .accessibilityHidden(true)
                                Text(perk.1)
                                    .font(.callout)
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                            }
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))

                    VStack(spacing: 10) {
                        PrimaryButton(title: "Unlock Wake Pro · \(Pro.priceLabel)",
                                      systemImage: "lock.open.fill") {
                            unlock()
                        }
                        Button("Restore Purchase") {
                            Haptics.tap(hapticsEnabled)
                            showRestoreNote = true
                        }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    }

                    Text("Demo unlock for this build — a real StoreKit purchase wires in for production. One-time, no subscription.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    if showRestoreNote {
                        Text("No previous purchase found on this device.")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                            .transition(.opacity)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Wake Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .animation(.easeInOut, value: showRestoreNote)
        }
    }

    private func unlock() {
        isPro = true
        Haptics.success(hapticsEnabled)
        dismiss()
    }
}
