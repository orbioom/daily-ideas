import SwiftUI
import SwiftData

/// Today / Capture: shows today's moment(s) or an inviting CTA, plus a header
/// with the current streak. Pro users can add more than one moment per day.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Moment.createdAt, order: .reverse) private var allMoments: [Moment]

    @State private var showEditor = false
    @State private var editingMoment: Moment?
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var toast: ToastState?

    private var todayKey: String { DayKey.today }

    private var todaysMoments: [Moment] {
        allMoments.filter { $0.dayKey == todayKey }
    }

    private var streak: StreakStats {
        StreakEngine.compute(moments: allMoments)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    streakHeader
                    if todaysMoments.isEmpty {
                        captureCTA
                    } else {
                        ForEach(todaysMoments) { moment in
                            NavigationLink {
                                MomentDetailView(moment: moment)
                            } label: {
                                MomentCard(moment: moment)
                            }
                            .buttonStyle(.plain)
                        }
                        addAnotherRow
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showEditor) {
                MomentEditorView(dayKey: todayKey, existing: editingMoment) { _ in
                    toast = ToastState(symbol: "checkmark.circle.fill", message: "Moment captured")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toast($toast)
        }
    }

    private var streakHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.accentSoft)
                Image(systemName: "flame.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dateFormatter.string(from: Date()))
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Text(streakLine)
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(streak.totalDays) days captured · best \(streak.longest)")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streakLine). \(streak.totalDays) days captured. Best streak \(streak.longest).")
    }

    private var streakLine: String {
        switch streak.current {
        case 0: return "Start a streak today"
        case 1: return "1 day streak"
        default: return "\(streak.current) day streak"
        }
    }

    private var captureCTA: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.heroGradient.opacity(0.18))
                VStack(spacing: 12) {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(Theme.accent)
                    Text("Capture today's glimpse")
                        .font(Theme.rounded(21, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("One photo, a line, a mood.\nThat's the whole ritual.")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 36)
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)

            PrimaryButton(title: "Add today's moment", symbol: "plus") {
                Haptics.tap(settings.hapticsEnabled)
                editingMoment = nil
                showEditor = true
            }
        }
    }

    private var addAnotherRow: some View {
        Button {
            if isPro {
                Haptics.tap(settings.hapticsEnabled)
                editingMoment = nil
                showEditor = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isPro ? "plus.circle.fill" : "lock.fill")
                Text(isPro ? "Add another moment today" : "Add more than one a day with Pro")
                    .font(Theme.rounded(15, .semibold))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Theme.accent)
            .padding(14)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
