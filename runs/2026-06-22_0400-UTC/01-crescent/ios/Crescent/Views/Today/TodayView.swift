import SwiftUI

struct TodayView: View {
    @State private var now = Date()
    private var phase: MoonPhase { MoonEngine.moonPhase(for: now) }
    private var angle: Double   { MoonEngine.phaseAngle(for: now) }
    private var illum: Double   { MoonEngine.illumination(for: now) }
    private var nextNew: Date   { MoonEngine.nextNewMoon(after: now) }
    private var nextFull: Date  { MoonEngine.nextFullMoon(after: now) }

    var body: some View {
        NavigationStack {
            ZStack {
                CrescentTheme.navy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        moonSection
                        phaseInfoCard
                        countdownCards
                        ritualCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Tonight's Moon")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(CrescentTheme.gold)
                    }
                }
            }
        }
        .onAppear { now = Date() }
    }

    private var moonSection: some View {
        VStack(spacing: 12) {
            MoonCanvasView(phaseAngle: angle)
                .frame(width: 180, height: 180)

            Text(phase.symbol + " " + phase.rawValue)
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundColor(CrescentTheme.pearl)

            Text(phase.energy.uppercased())
                .font(.caption)
                .tracking(2)
                .foregroundColor(CrescentTheme.gold)

            Text(String(format: "%.0f%% illuminated", illum * 100))
                .font(.caption)
                .foregroundColor(CrescentTheme.silver)
        }
        .padding(.top, 8)
    }

    private var phaseInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Affirmation")
                .font(.caption)
                .tracking(1.5)
                .foregroundColor(CrescentTheme.gold)
            Text("\u201c\(phase.affirmation)\u201d")
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundColor(CrescentTheme.pearl)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(CrescentTheme.cardBg)
        .cornerRadius(16)
    }

    private var countdownCards: some View {
        HStack(spacing: 12) {
            countdownTile(
                emoji: "🌑",
                label: "Next New Moon",
                days: MoonEngine.daysUntil(nextNew, from: now)
            )
            countdownTile(
                emoji: "🌕",
                label: "Next Full Moon",
                days: MoonEngine.daysUntil(nextFull, from: now)
            )
        }
    }

    private func countdownTile(emoji: String, label: String, days: Int) -> some View {
        VStack(spacing: 6) {
            Text(emoji).font(.title2)
            Text("\(days)")
                .font(.system(size: 36, weight: .light, design: .serif))
                .foregroundColor(CrescentTheme.pearl)
            Text("days")
                .font(.caption2)
                .foregroundColor(CrescentTheme.silver)
            Text(label)
                .font(.caption2)
                .foregroundColor(CrescentTheme.silver)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(CrescentTheme.cardBg)
        .cornerRadius(16)
    }

    private var ritualCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lunar Guidance")
                .font(.caption)
                .tracking(1.5)
                .foregroundColor(CrescentTheme.gold)
            Text(phase.ritualSuggestion)
                .font(.callout)
                .foregroundColor(CrescentTheme.silver)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(CrescentTheme.cardBg)
        .cornerRadius(16)
    }
}
