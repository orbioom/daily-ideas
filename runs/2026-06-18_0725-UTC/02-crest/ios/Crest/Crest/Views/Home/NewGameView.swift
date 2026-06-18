import SwiftUI

struct NewGameView: View {
    @EnvironmentObject private var pro: ProStore
    let onStart: (GameRequest) -> Void

    enum DealMode: String, CaseIterable, Identifiable {
        case daily = "Daily", numbered = "Numbered", random = "Random"
        var id: String { rawValue }
    }

    @State private var layout: BoardLayout = .threePeaks
    @State private var mode: DealMode = .random
    @State private var numberText: String = "1"
    @State private var showPaywall = false

    private var numberedDeal: Int {
        let trimmed = numberText.trimmingCharacters(in: .whitespaces)
        guard let n = Int(trimmed), n > 0 else { return 1 }
        return min(n, 999_999)
    }

    private var resolvedRequest: GameRequest {
        switch mode {
        case .daily:
            return .new(layout, dealNumber: SeedFactory.dailyDealNumber(for: Date()), isDaily: true)
        case .numbered:
            return .new(layout, dealNumber: numberedDeal, isDaily: false)
        case .random:
            return .new(layout, dealNumber: Int.random(in: 1...999_999), isDaily: false)
        }
    }

    private var canStart: Bool { pro.isPro || !layout.isPro }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                layoutSection
                modeSection
                if mode == .numbered { numberSection }
                if !canStart { lockedNote }
                startButton
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("New Game")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Board")
            ForEach(BoardLayout.allCases) { l in
                layoutRow(l)
            }
        }
    }

    private func layoutRow(_ l: BoardLayout) -> some View {
        let locked = l.isPro && !pro.isPro
        return Button {
            if locked { showPaywall = true } else { layout = l }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: l.symbolName)
                    .font(.system(size: 22))
                    .foregroundStyle(layout == l ? Theme.accent : Theme.inkSoft)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(l.title)
                            .font(Theme.rounded(17, .semibold))
                            .foregroundStyle(Theme.ink)
                        if l.isPro { ProBadge() }
                    }
                    Text(l.subtitle)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if locked {
                    Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint)
                } else {
                    Image(systemName: layout == l ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(layout == l ? Theme.accent : Theme.inkFaint)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusTile, style: .continuous)
                    .fill(layout == l ? Theme.accent.opacity(0.08) : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusTile, style: .continuous)
                    .strokeBorder(layout == l ? Theme.accent.opacity(0.4) : Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
        .accessibilityHint(locked ? "Pro feature, opens unlock screen" : "Selects this board")
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Deal")
            Picker("Deal mode", selection: $mode) {
                ForEach(DealMode.allCases) { m in Text(m.rawValue).tag(m) }
            }
            .pickerStyle(.segmented)
            Text(modeHint)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var modeHint: String {
        switch mode {
        case .daily: return "Everyone gets the same deal today. Compete on score and streak."
        case .numbered: return "Type a deal number — the same number always deals the same board."
        case .random: return "A fresh, randomly chosen deal."
        }
    }

    private var numberSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Deal number")
            TextField("Deal #", text: $numberText)
                .keyboardType(.numberPad)
                .font(Theme.rounded(17, .semibold))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                        .fill(Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                )
                .onChange(of: numberText) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue { numberText = filtered }
                }
        }
    }

    private var lockedNote: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill").foregroundStyle(Theme.gold)
                Text("\(layout.title) is a Pro board. Tap to unlock.")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous).fill(Theme.gold.opacity(0.12)))
        }
        .buttonStyle(PressableStyle())
    }

    private var startButton: some View {
        Group {
            if canStart {
                PrimaryButton(title: "Deal", icon: "play.fill") {
                    onStart(resolvedRequest)
                }
            } else {
                PrimaryButton(title: "Unlock to play", icon: "lock.fill") {
                    showPaywall = true
                }
            }
        }
        .padding(.top, 4)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Theme.rounded(12, .bold))
            .foregroundStyle(Theme.inkFaint)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
