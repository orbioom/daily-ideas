import SwiftUI
import SwiftData

/// Life-statistics screen: precise age, weeks lived/remaining, % lived, summers left,
/// and a reflective "time spent" line. Animated progress arc that honors Reduce Motion.
struct PerspectiveScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var profiles: [LifeProfile]
    @State private var animateProgress = false

    private var profile: LifeProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    content(for: profile)
                } else {
                    EmptyStateView(symbol: "hourglass",
                                   title: "No perspective yet",
                                   message: "Set up your life profile on the Life tab to see your weeks, years, and the time still ahead.")
                    .frame(maxHeight: .infinity)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Perspective")
        }
    }

    @ViewBuilder
    private func content(for profile: LifeProfile) -> some View {
        // Re-tick every minute so "days lived" etc. stay live.
        TimelineView(.periodic(from: .now, by: 60)) { tlContext in
            let engine = SpanEngine(profile: profile)
            let stats = engine.stats(now: tlContext.date)
            ScrollView {
                VStack(spacing: 18) {
                    progressCard(stats: stats, profile: profile)
                    ageCard(stats: stats)
                    statGrid(stats: stats)
                    reflectionCard(stats: stats)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .onAppear {
            if reduceMotion {
                animateProgress = true
            } else {
                withAnimation(.easeOut(duration: 1.0)) { animateProgress = true }
            }
        }
    }

    private func progressCard(stats: LifeStats, profile: LifeProfile) -> some View {
        CardView {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Theme.surfaceAlt, lineWidth: 16)
                    Circle()
                        .trim(from: 0, to: animateProgress ? stats.fractionLived : 0)
                        .stroke(Theme.accent,
                                style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(Fmt.oneDecimal(stats.percentLived))%")
                            .font(Theme.rounded(34, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("of an expected\n\(profile.lifeExpectancyYears) years")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: 200, height: 200)
                .padding(.top, 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(Fmt.oneDecimal(stats.percentLived)) percent of an expected \(profile.lifeExpectancyYears) years lived")

                Text("\(Fmt.grouped(stats.weeksLived)) weeks behind you · \(Fmt.grouped(stats.weeksRemaining)) ahead")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func ageCard(stats: LifeStats) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("YOU ARE")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.accent)
                Text("\(stats.years) years, \(stats.months) months, \(stats.days) days old")
                    .font(Theme.serif(22, .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    private func statGrid(stats: LifeStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)], spacing: 14) {
            statTile("calendar", Fmt.grouped(stats.weeksLived), "weeks lived")
            statTile("calendar.badge.clock", Fmt.grouped(stats.weeksRemaining), "weeks remaining")
            statTile("sun.max.fill", "\(stats.summersRemaining)", "summers remaining")
            statTile("clock", Fmt.grouped(stats.daysLived), "days lived")
            statTile("moon.stars.fill", Fmt.grouped(stats.monthsLived), "months lived")
            statTile("heart.fill", "\(stats.years)", "years young")
        }
    }

    private func statTile(_ icon: String, _ value: String, _ label: String) -> some View {
        CardView(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(value)
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(label)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private func reflectionCard(stats: LifeStats) -> some View {
        // A gentle, factual reflection drawn from the numbers.
        let sleepWeeks = Int(Double(stats.weeksLived) * 0.33)   // ~8h/day ≈ a third of life
        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("A little perspective", systemImage: "quote.opening")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Text("Of the \(Fmt.grouped(stats.weeksLived)) weeks you've lived, roughly \(Fmt.grouped(sleepWeeks)) were spent asleep. You have about \(Fmt.grouped(stats.weeksRemaining)) weeks and \(stats.summersRemaining) summers still ahead. Each dot is one of them — spend it on what matters.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
