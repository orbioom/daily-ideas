import SwiftUI

/// Reason a paywall was presented (for a tailored headline).
enum PaywallReason: Identifiable {
    case french
    case advancedTense
    case allVerbs
    case stats

    var id: String {
        switch self {
        case .french: return "french"
        case .advancedTense: return "tense"
        case .allVerbs: return "verbs"
        case .stats: return "stats"
        }
    }

    var headline: String {
        switch self {
        case .french: return "Add French to your training"
        case .advancedTense: return "Unlock advanced tenses"
        case .allVerbs: return "Train the full verb library"
        case .stats: return "See your full progress"
        }
    }
}

/// Simulated one-time Pro purchase screen.
struct PaywallView: View {
    let reason: PaywallReason
    @AppStorage(Prefs.isPro) private var isPro = false
    @AppStorage(Prefs.haptics) private var haptics = true
    @Environment(\.dismiss) private var dismiss

    private let features: [(String, String)] = [
        ("globe.europe.africa", "French verbs & tenses (présent, imparfait, futur, passé composé)"),
        ("clock.arrow.circlepath", "Advanced Spanish: subjuntivo & condicional"),
        ("books.vertical", "The complete verb library — no limits"),
        ("chart.line.uptrend.xyaxis", "Full progress analytics & weak-spot targeting"),
        ("wifi.slash", "Everything offline, forever — no account, no subscription"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        VStack(spacing: 10) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.gold)
                                .accessibilityHidden(true)
                            Text(reason.headline)
                                .font(Theme.serif(26, .bold))
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center)
                            Text("Verbo Pro — a one-time unlock")
                                .font(Theme.rounded(15))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .padding(.top, 12)

                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(features.enumerated()), id: \.offset) { _, f in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: f.0)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(Theme.accent)
                                        .frame(width: 26)
                                        .accessibilityHidden(true)
                                    Text(f.1)
                                        .font(Theme.rounded(15))
                                        .foregroundStyle(Theme.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))

                        VStack(spacing: 12) {
                            Text("$5.99")
                                .font(Theme.serif(34, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("Pay once. Yours forever.")
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)

                            PrimaryButton(title: isPro ? "Pro unlocked" : "Unlock Pro (demo)",
                                          systemImage: isPro ? "checkmark.circle.fill" : "lock.open.fill") {
                                isPro = true
                                Haptics.success(haptics)
                                dismiss()
                            }
                            .disabled(isPro)

                            Button("Restore purchase") {
                                isPro = true
                                Haptics.success(haptics)
                                dismiss()
                            }
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.accent)
                        }
                        .padding(.bottom, 24)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Verbo Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
