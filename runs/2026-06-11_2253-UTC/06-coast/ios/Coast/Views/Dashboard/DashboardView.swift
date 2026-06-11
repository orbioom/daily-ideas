import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("retirementAge") private var retirementAge = 65.0
    @Query private var profiles: [Profile]
    @State private var showEditor = false

    private var profile: Profile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile {
                    VStack(spacing: 16) {
                        fiHero(profile)
                        coastCard(profile)
                        leverRow(profile)
                        passiveCard(profile)
                    }
                    .padding()
                } else {
                    EmptyStateView(icon: "sailboat",
                                   title: "Setting up your plan…",
                                   message: "One moment while Coast prepares your numbers.")
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Your plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEditor = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel("Edit assumptions")
                }
            }
            .sheet(isPresented: $showEditor) {
                if let profile { AssumptionsEditor(profile: profile) }
            }
        }
    }

    private func fiHero(_ profile: Profile) -> some View {
        let progress = FIEngine.progress(profile: profile)
        let years = FIEngine.yearsToFI(profile: profile)
        return VStack(spacing: 14) {
            Text("Your FI number")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft(scheme))
            Text(FIEngine.money(profile.fiNumber, code: profile.currencyCode))
                .font(Theme.display(40))
                .foregroundStyle(Theme.ink(scheme))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            ProgressWave(progress: progress)
                .frame(height: 90)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int((progress * 100).rounded()))% there")
                        .font(.headline)
                        .foregroundStyle(Theme.teal)
                    Text(FIEngine.money(profile.currentInvested, code: profile.currencyCode, compact: true) + " invested")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft(scheme))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(years.map { FIEngine.yearsLabel($0) } ?? "—")
                        .font(.headline)
                        .foregroundStyle(Theme.ink(scheme))
                    Text(years != nil ? "to freedom" : "adjust assumptions")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft(scheme))
                }
            }
            if let years {
                let fiAge = profile.currentAge + years
                Text("Work optional at age \(String(format: "%.0f", fiAge))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.deepSea)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.teal.opacity(0.12), in: Capsule())
            }
        }
        .coastCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("FI number \(FIEngine.money(profile.fiNumber, code: profile.currencyCode)), \(Int((progress * 100).rounded())) percent reached")
    }

    private func coastCard(_ profile: Profile) -> some View {
        let coastNumber = FIEngine.coastFINumber(profile: profile, retirementAge: retirementAge)
        let reached = FIEngine.hasReachedCoastFI(profile: profile, retirementAge: retirementAge)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "wind")
                    .foregroundStyle(Theme.sun)
                Text("Coast FI")
                    .font(.headline)
                    .foregroundStyle(Theme.ink(scheme))
                Spacer()
                if reached {
                    Text("Reached ⛵️")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.teal)
                }
            }
            if reached {
                Text("You've already saved enough that — even if you never invested another dollar — compounding alone grows you to your FI number by age \(Int(retirementAge)). You're coasting.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            } else {
                Text("At \(FIEngine.money(coastNumber, code: profile.currencyCode)) invested, you could stop contributing and still hit FI by age \(Int(retirementAge)). You're \(FIEngine.money(max(coastNumber - profile.currentInvested, 0), code: profile.currencyCode, compact: true)) away.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
                let coastYears = FIEngine.yearsToReach(target: coastNumber,
                                                       current: profile.currentInvested,
                                                       contribution: profile.annualContribution,
                                                       rate: profile.realReturn)
                if let cy = coastYears {
                    Text("Coast FI in about \(FIEngine.yearsLabel(cy)).")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.sun)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coastCard()
    }

    private func leverRow(_ profile: Profile) -> some View {
        let savingsRate = FIEngine.savingsRate(profile: profile)
        return HStack(spacing: 12) {
            statTile(title: "Savings rate", value: "\(Int((savingsRate * 100).rounded()))%",
                     caption: "the #1 lever")
            statTile(title: "Real return", value: "\(String(format: "%.1f", profile.realReturn * 100))%",
                     caption: "after inflation")
            statTile(title: "Withdrawal", value: "\(String(format: "%.1f", profile.withdrawalRate * 100))%",
                     caption: "yearly")
        }
    }

    private func statTile(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft(scheme))
            Text(value)
                .font(Theme.display(20))
                .foregroundStyle(Theme.ink(scheme))
            Text(caption)
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private func passiveCard(_ profile: Profile) -> some View {
        let monthly = FIEngine.currentPassiveMonthly(profile: profile)
        let coverage = profile.annualExpenses > 0
            ? (profile.currentInvested * profile.withdrawalRate) / profile.annualExpenses : 0
        return VStack(alignment: .leading, spacing: 8) {
            Text("Where you stand today").font(.headline)
            Text("Your portfolio could safely pay you about \(FIEngine.money(monthly, code: profile.currencyCode))/month right now — that already covers \(Int((coverage * 100).rounded()))% of your spending.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coastCard()
    }
}

/// A filling-wave progress indicator in Coast's ocean language.
struct ProgressWave: View {
    let progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Double = 0

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let level = h * (1 - CGFloat(min(max(progress, 0), 1)))
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.deepSea.opacity(0.10))
                WaveShape(phase: phase, amplitude: 5, baseline: level / h)
                    .fill(LinearGradient(colors: [Theme.teal, Theme.deepSea],
                                         startPoint: .top, endPoint: .bottom))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                Text("\(Int((progress * 100).rounded()))%")
                    .font(Theme.display(24))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            .frame(width: w, height: h)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
        .accessibilityHidden(true)
    }
}

struct WaveShape: Shape {
    var phase: Double
    var amplitude: CGFloat
    var baseline: Double // 0 (top) ... 1 (bottom)

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.height * baseline
        path.move(to: CGPoint(x: 0, y: midY))
        let step: CGFloat = 4
        var x: CGFloat = 0
        while x <= rect.width {
            let relative = Double(x / rect.width)
            let y = midY + sin(relative * .pi * 2 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
