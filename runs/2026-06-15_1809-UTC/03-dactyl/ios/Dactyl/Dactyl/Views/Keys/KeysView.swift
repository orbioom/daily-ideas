import SwiftUI
import SwiftData

/// The signature insight: a QWERTY grid colored by your real per-key error rate, plus a
/// per-finger breakdown and a custom-drill launcher. The heatmap & custom drills gate behind Pro.
struct KeysView: View {
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Query private var results: [TestResult]

    @State private var paywallReason: PaywallReason?
    @State private var customDraft = ""
    @State private var activeConfig: SessionConfig?

    private var keyStats: [String: KeyStat] { KeyHeatmap.keyStats(from: results) }
    private var fingerStats: [FingerStat] {
        KeyHeatmap.fingerStats(from: results).sorted { $0.errorRate > $1.errorRate }
    }
    private var worst: KeyStat? { KeyHeatmap.worstKey(from: results) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if results.isEmpty {
                        EmptyStateView(
                            symbol: "keyboard",
                            title: "No key data yet",
                            message: "Type a few sessions and your per-key error heatmap will light up here."
                        )
                        .padding(.top, 30)
                    } else if isPro {
                        heatmapCard
                        fingerCard
                    } else {
                        lockedHeatmapCard
                    }
                    customDrillCard
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Keys")
            .navigationDestination(item: $activeConfig) { cfg in
                TypingSessionView(config: cfg)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    // MARK: Heatmap

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Key error heatmap", systemImage: "flame.fill")
            if let worst, worst.errorCount > 0 {
                Text("Your toughest key is **\(displayName(worst.key))** — \(Int((worst.errorRate * 100).rounded()))% error rate. Aim there next.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Cool and even — no standout problem keys. Nice.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            keyboardGrid
            legend
        }
        .padding(18)
        .cardSurface()
    }

    private var keyboardGrid: some View {
        VStack(spacing: 6) {
            heatRow(KeyHeatmap.row1)
            heatRow(KeyHeatmap.row2).padding(.leading, 14)
            heatRow(KeyHeatmap.row3).padding(.leading, 34)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(gridAccessibilityLabel)
    }

    private func heatRow(_ keys: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                heatKey(key)
            }
        }
    }

    private func heatKey(_ key: String) -> some View {
        let stat = keyStats[key]
        let rate = stat?.errorRate ?? 0
        return Text(key.uppercased())
            .font(Theme.mono(15, .semibold))
            .foregroundStyle(rate > 0.18 ? Color.white : Theme.ink)
            .frame(width: 30, height: 38)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(heatColor(rate))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Theme.keycapEdge, lineWidth: 1)
            )
    }

    /// Maps error rate 0...~0.4 onto a cool→hot gradient (mint surface → red).
    private func heatColor(_ rate: Double) -> Color {
        let clamped = min(1.0, max(0.0, rate / 0.4))
        if clamped <= 0.001 { return Theme.keycap }
        // Blend keycap → warn → bad.
        if clamped < 0.5 {
            return blend(Theme.accentSoft, Theme.warn, t: clamped / 0.5)
        } else {
            return blend(Theme.warn, Theme.bad, t: (clamped - 0.5) / 0.5)
        }
    }

    private func blend(_ a: Color, _ b: Color, t: Double) -> Color {
        let ua = UIColor(a), ub = UIColor(b)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        ua.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        ub.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let tt = CGFloat(min(1, max(0, t)))
        return Color(.sRGB,
                     red: Double(r1 + (r2 - r1) * tt),
                     green: Double(g1 + (g2 - g1) * tt),
                     blue: Double(b1 + (b2 - b1) * tt),
                     opacity: 1)
    }

    private var legend: some View {
        HStack(spacing: 10) {
            legendSwatch(Theme.accentSoft, "Clean")
            legendSwatch(Theme.warn, "Some slips")
            legendSwatch(Theme.bad, "Trouble")
            Spacer()
        }
        .padding(.top, 4)
    }

    private func legendSwatch(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 14, height: 14)
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
        }
        .accessibilityHidden(true)
    }

    // MARK: Finger breakdown

    private var fingerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "By finger", systemImage: "hand.point.up.left.fill")
            ForEach(fingerStats) { stat in
                HStack(spacing: 10) {
                    Text(stat.finger.label)
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 96, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceAlt)
                            Capsule()
                                .fill(heatColor(stat.errorRate))
                                .frame(width: max(6, geo.size.width * min(1, stat.errorRate / 0.4)))
                        }
                    }
                    .frame(height: 12)
                    Text("\(Int((stat.errorRate * 100).rounded()))%")
                        .font(Theme.mono(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(width: 44, alignment: .trailing)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(stat.finger.label), \(Int((stat.errorRate * 100).rounded())) percent error rate")
            }
        }
        .padding(18)
        .cardSurface()
    }

    // MARK: Locked teaser

    private var lockedHeatmapCard: some View {
        Button {
            paywallReason = .keyHeatmap
        } label: {
            VStack(spacing: 14) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Unlock the key heatmap")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Dactyl's signature insight: a keyboard colored by your real error rate, so you know exactly which keys to drill.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                ProLockChip()
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .cardSurface()
        }
        .buttonStyle(PressableScale())
    }

    // MARK: Custom drill

    private var customDrillCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Custom drill", systemImage: "pencil.and.scribble")
            Text("Type your own text and practice it with full live stats.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)

            TextField("Paste or type any text…", text: $customDraft, axis: .vertical)
                .font(Theme.mono(15))
                .lineLimit(2...5)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .fill(Theme.surfaceAlt)
                )
                .accessibilityLabel("Custom drill text")

            PrimaryButton(title: "Drill this text", systemImage: "play.fill") {
                startCustom()
            }
            .disabled(trimmedDraft.isEmpty)
            .opacity(trimmedDraft.isEmpty ? 0.5 : 1)
        }
        .padding(18)
        .cardSurface()
    }

    private var trimmedDraft: String {
        customDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func startCustom() {
        guard !trimmedDraft.isEmpty else { return }
        guard isPro else { paywallReason = .customDrill; return }
        activeConfig = SessionConfig(
            title: "Custom drill",
            text: trimmedDraft,
            mode: .drill,
            strict: settings.strictMode,
            focusKeys: [],
            lessonID: nil,
            timeLimit: nil
        )
    }

    private func displayName(_ key: String) -> String {
        switch key {
        case "space": return "space"
        case ",": return "comma"
        case ".": return "period"
        case ";": return "semicolon"
        default: return key.uppercased()
        }
    }

    private var gridAccessibilityLabel: String {
        if let worst, worst.errorCount > 0 {
            return "Key error heatmap. Toughest key \(displayName(worst.key)) at \(Int((worst.errorRate * 100).rounded())) percent."
        }
        return "Key error heatmap. No standout problem keys."
    }
}
