import SwiftUI
import SwiftData

/// "Can I have one more?" — the last safe time for a drink given your bedtime.
struct CurfewCalcView: View {
    @Query private var intakes: [Intake]
    @Query(sort: \CaffeineSource.name) private var sources: [CaffeineSource]
    @AppStorage("halfLifeHours") private var halfLife = 5.0
    @AppStorage("bedtimeHour") private var bedtimeHour = 23
    @AppStorage("bedtimeMinute") private var bedtimeMinute = 0
    @AppStorage("sleepThresholdMg") private var sleepThreshold = 50.0

    @State private var doseMg = 95.0
    @State private var now = Date.now
    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var doses: [CaffeineMath.Dose] { intakes.map { $0.dose } }
    private var bedtime: Date { Bedtime.next(hour: bedtimeHour, minute: bedtimeMinute, from: now) }
    private var safe: CaffeineMath.SafeTime {
        CaffeineMath.lastSafeTime(bedtime: bedtime, targetAtBed: sleepThreshold,
                                  newDoseMg: doseMg, doses: doses, halfLifeHours: halfLife)
    }
    private var projectedNow: Double {
        CaffeineMath.projectedAtBed(bedtime: bedtime, newDoseMg: doseMg, at: now,
                                    doses: doses, halfLifeHours: halfLife)
    }
    private var existingAtBed: Double {
        CaffeineMath.level(at: bedtime, doses: doses, halfLifeHours: halfLife)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    resultCard
                    drinkCard
                    projectionCard
                    contextCard
                }
                .padding(16)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Curfew")
            .onReceive(ticker) { now = $0 }
            .onAppear { now = .now }
        }
    }

    private var resultCard: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 34)).foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(headline).font(Brand.mono(30, weight: .bold)).foregroundStyle(tint)
                .multilineTextAlignment(.center)
            Text(subline).font(.subheadline).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).glassCard(padding: 24)
    }

    private var drinkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "That next drink")
                Spacer()
                Text(Fmt.mg(doseMg)).font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
            }
            Slider(value: $doseMg, in: 10...300, step: 5)
            if !sources.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sources) { s in
                            Button { doseMg = s.mg; Haptics.selection() } label: {
                                Chip(text: "\(s.name) \(Int(s.mg))", tint: Brand.text2)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private var projectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "If you drink it now")
            HStack {
                Text("Level at bedtime").font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
                Text(Fmt.mg(projectedNow))
                    .font(Brand.mono(20, weight: .semibold))
                    .foregroundStyle(projectedNow > sleepThreshold ? Brand.danger : Brand.live)
            }
            ProgressView(value: min(1, projectedNow / max(sleepThreshold * 2, 1)))
                .tint(projectedNow > sleepThreshold ? Brand.danger : Brand.live)
            Text("Your sleep line is \(Int(sleepThreshold)) mg. Bedtime is \(Fmt.time(bedtime)).")
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "The math")
            row("Already in you at bedtime", Fmt.mg(existingAtBed))
            row("Half-life", String(format: "%.1f h", halfLife))
            Text("Curfew assumes caffeine halves every \(String(format: "%.1f", halfLife)) hours. The last safe time is when a \(Int(doseMg)) mg drink would decay to leave you at or under your sleep line by bedtime.")
                .font(.caption).foregroundStyle(Brand.text3).padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private func row(_ l: String, _ v: String) -> some View {
        HStack { Text(l).font(.subheadline).foregroundStyle(Brand.text2); Spacer()
            Text(v).font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text) }
    }

    private var icon: String {
        switch safe {
        case .anytime: return "checkmark.circle.fill"
        case .alreadyOver: return "exclamationmark.triangle.fill"
        case .by(let d): return d >= now ? "clock.fill" : "moon.zzz.fill"
        }
    }
    private var tint: Color {
        switch safe {
        case .anytime: return Brand.live
        case .alreadyOver: return Brand.danger
        case .by(let d): return d >= now ? Brand.text : Brand.warn
        }
    }
    private var headline: String {
        switch safe {
        case .anytime: return "Go ahead"
        case .alreadyOver: return "Skip it"
        case .by(let d): return d >= now ? "By \(Fmt.time(d))" : "Too late"
        }
    }
    private var subline: String {
        switch safe {
        case .anytime:
            return "Even now, a \(Int(doseMg)) mg drink keeps you under your sleep line at bedtime."
        case .alreadyOver:
            return "You're already projected over your sleep line at bedtime without it."
        case .by(let d):
            return d >= now
                ? "Have your \(Int(doseMg)) mg drink by this time to protect your sleep."
                : "A \(Int(doseMg)) mg drink now would leave too much caffeine at bedtime."
        }
    }
}
