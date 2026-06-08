import Foundation

// MARK: - Milestone definition

struct Milestone: Identifiable {
    let days: Int
    let title: String
    let symbol: String

    var id: Int { days }
}

struct MilestoneStatus: Identifiable {
    let milestone: Milestone
    let achieved: Bool
    let progress: Double   // 0.0...1.0 toward this milestone from previous
    var id: Int { milestone.days }
}

// MARK: - Health timeline event

struct HealthEvent: Identifiable {
    let id: UUID
    let afterSeconds: TimeInterval   // how many seconds after quit start
    let title: String
    let detail: String
    let reached: Bool

    init(afterSeconds: TimeInterval, title: String, detail: String, reached: Bool) {
        self.id = UUID()
        self.afterSeconds = afterSeconds
        self.title = title
        self.detail = detail
        self.reached = reached
    }
}

// MARK: - Engine

enum SobrietyEngine {

    // MARK: Elapsed components

    static func elapsed(since start: Date, to now: Date) -> DateComponents {
        let cal = Calendar.current
        return cal.dateComponents([.day, .hour, .minute, .second], from: start, to: now)
    }

    // MARK: Clean days

    static func cleanDays(start: Date, now: Date) -> Int {
        let secs = now.timeIntervalSince(start)
        guard secs >= 0 else { return 0 }
        return Int(secs / 86400)
    }

    // MARK: Fractional days

    private static func fractionalDays(start: Date, now: Date) -> Double {
        let secs = now.timeIntervalSince(start)
        guard secs >= 0 else { return 0 }
        return secs / 86400.0
    }

    // MARK: Money saved

    static func moneySaved(quit: Quit, now: Date) -> Double {
        let days = fractionalDays(start: quit.startDate, now: now)
        guard days >= 0, quit.costPerUnit >= 0, quit.unitsPerDay >= 0 else { return 0 }
        return quit.unitsPerDay * quit.costPerUnit * days
    }

    // MARK: Units avoided

    static func unitsAvoided(quit: Quit, now: Date) -> Double {
        let days = fractionalDays(start: quit.startDate, now: now)
        guard days >= 0, quit.unitsPerDay >= 0 else { return 0 }
        return quit.unitsPerDay * days
    }

    // MARK: Projected money saved (future days from now)

    static func projectedMoneySaved(quit: Quit, daysFromNow: Double) -> Double {
        guard daysFromNow >= 0, quit.costPerUnit >= 0, quit.unitsPerDay >= 0 else { return 0 }
        return quit.unitsPerDay * quit.costPerUnit * daysFromNow
    }

    // MARK: Longest streak

    static func longestStreak(quit: Quit, now: Date) -> Int {
        let current = cleanDays(start: quit.startDate, now: now)
        let pastMax = quit.relapses.map(\.previousCleanDays).max() ?? 0
        return max(current, pastMax)
    }

    // MARK: Milestone ladder

    static let milestoneLadder: [Milestone] = [
        Milestone(days: 1,    title: "First Day",      symbol: "sunrise.fill"),
        Milestone(days: 3,    title: "72 Hours",       symbol: "bolt.fill"),
        Milestone(days: 7,    title: "One Week",       symbol: "calendar.badge.checkmark"),
        Milestone(days: 14,   title: "Two Weeks",      symbol: "star.fill"),
        Milestone(days: 30,   title: "One Month",      symbol: "moon.fill"),
        Milestone(days: 60,   title: "Two Months",     symbol: "flame.fill"),
        Milestone(days: 90,   title: "Three Months",   symbol: "crown.fill"),
        Milestone(days: 180,  title: "Six Months",     symbol: "trophy.fill"),
        Milestone(days: 365,  title: "One Year",       symbol: "rosette"),
        Milestone(days: 500,  title: "500 Days",       symbol: "sparkles"),
        Milestone(days: 730,  title: "Two Years",      symbol: "medal.fill"),
        Milestone(days: 1000, title: "1000 Days",      symbol: "diamond.fill"),
    ]

    static func milestoneStatuses(quit: Quit, now: Date) -> [MilestoneStatus] {
        let days = cleanDays(start: quit.startDate, now: now)
        var statuses: [MilestoneStatus] = []
        for (index, ms) in milestoneLadder.enumerated() {
            let achieved = days >= ms.days
            let prevDays = index == 0 ? 0 : milestoneLadder[index - 1].days
            let span = ms.days - prevDays
            let progress: Double
            if achieved {
                progress = 1.0
            } else if span > 0 {
                progress = min(1.0, max(0.0, Double(days - prevDays) / Double(span)))
            } else {
                progress = 0.0
            }
            statuses.append(MilestoneStatus(milestone: ms, achieved: achieved, progress: progress))
        }
        return statuses
    }

    /// Returns the next unachieved milestone, if any.
    static func nextMilestone(quit: Quit, now: Date) -> MilestoneStatus? {
        milestoneStatuses(quit: quit, now: now).first(where: { !$0.achieved })
    }

    // MARK: Health timeline

    static func healthTimeline(category: QuitCategory, cleanDays: Int) -> [HealthEvent] {
        let events = rawHealthEvents(for: category)
        return events.map { raw in
            let reachedSecs = Double(cleanDays) * 86400.0
            return HealthEvent(
                afterSeconds: raw.0,
                title: raw.1,
                detail: raw.2,
                reached: reachedSecs >= raw.0
            )
        }
    }

    // (afterSeconds, title, detail)
    private static func rawHealthEvents(for category: QuitCategory) -> [(TimeInterval, String, String)] {
        switch category {
        case .nicotine:
            return [
                (20 * 60,          "Heart Rate Drops",      "Heart rate and blood pressure begin to return to normal levels."),
                (12 * 3600,        "Carbon Monoxide Clears", "CO levels in blood drop to normal; oxygen delivery improves."),
                (24 * 3600,        "Heart Attack Risk Falls", "Your risk of a sudden cardiac event begins to decline."),
                (48 * 3600,        "Taste & Smell Improve",  "Nerve endings start to regenerate — flavours and aromas intensify."),
                (72 * 3600,        "Breathing Eases",        "Bronchial tubes relax; lung capacity noticeably increases."),
                (14 * 86400,       "Circulation Improves",   "Blood flow to hands and feet increases; walking becomes easier."),
                (30 * 86400,       "Lung Function +30%",     "Cilia regrow in the lungs, improving mucus clearance."),
                (90 * 86400,       "Coughing Subsides",      "Smoker's cough fades; sinus congestion clears substantially."),
                (365 * 86400,      "CHD Risk Halved",        "Risk of coronary heart disease is roughly half that of a smoker."),
                (5 * 365 * 86400,  "Stroke Risk Normalized", "Stroke risk equals that of a non-smoker after five years."),
            ]
        case .alcohol:
            return [
                (24 * 3600,        "Better Sleep",           "Sleep quality begins to improve as alcohol leaves your system."),
                (48 * 3600,        "Hydration Restored",     "Cells rehydrate; brain fog and headaches diminish."),
                (72 * 3600,        "Anxiety Settles",        "Nervous system stabilises; anxiety and irritability ease."),
                (7 * 86400,        "Liver Starts Healing",   "Liver inflammation begins to reduce after one week."),
                (14 * 86400,       "Blood Pressure Drops",   "Sustained lower blood pressure reduces cardiovascular risk."),
                (30 * 86400,       "Skin Clears",            "Skin tone improves; redness and puffiness fade noticeably."),
                (90 * 86400,       "Liver Function Normal",  "Liver enzymes trend toward normal in many people."),
                (180 * 86400,      "Cancer Risk Declining",  "Risk of alcohol-related cancers starts to measurably decrease."),
                (365 * 86400,      "Immune System Stronger", "Immune function approaches that of a non-drinker."),
            ]
        case .sugar:
            return [
                (24 * 3600,        "Cravings Peak",          "Sugar cravings are most intense in the first 24 hours — push through."),
                (48 * 3600,        "Blood Sugar Stabilises", "Glucose levels even out; energy crashes become less frequent."),
                (7 * 86400,        "Skin Improves",          "Reduced glycation improves skin clarity and texture."),
                (14 * 86400,       "Energy Steadies",        "Natural energy rhythms return without the spike-and-crash cycle."),
                (30 * 86400,       "Inflammation Drops",     "Inflammatory markers in blood start to normalise."),
                (90 * 86400,       "Taste Recalibrates",     "Natural sweetness in foods becomes more vivid and satisfying."),
                (180 * 86400,      "Weight Trend Improves",  "Without liquid and hidden sugar, body composition often shifts."),
                (365 * 86400,      "Metabolic Health",       "Insulin sensitivity improves; long-term diabetes risk reduced."),
            ]
        case .caffeine:
            return [
                (24 * 3600,        "Withdrawal Peaks",       "Headaches and fatigue peak within the first day — stay hydrated."),
                (48 * 3600,        "Sleep Deepens",          "Sleep architecture improves; more restorative slow-wave sleep."),
                (72 * 3600,        "Headaches Subside",      "Caffeine-withdrawal headaches typically resolve by day three."),
                (7 * 86400,        "Natural Energy Returns", "Adrenal glands recover; energy levels begin to stabilise naturally."),
                (14 * 86400,       "Anxiety Reduces",        "Baseline anxiety often decreases without stimulant-driven spikes."),
                (30 * 86400,       "Heart Rate Steady",      "Resting heart rate normalises without stimulant elevation."),
                (90 * 86400,       "Sleep Quality Optimal",  "Full adjustment to natural sleep-wake cycle is typically complete."),
            ]
        case .gambling:
            return [
                (24 * 3600,        "Urge Peaks",             "The strongest urges hit in the first 24 hours — have a plan ready."),
                (7 * 86400,        "Financial Clarity",      "One week of real savings shows the tangible cost of the habit."),
                (14 * 86400,       "Dopamine Resets",        "Reward pathways begin recalibrating to everyday pleasures."),
                (30 * 86400,       "Stress Reduces",         "Financial anxiety starts to lift as debts may begin stabilising."),
                (90 * 86400,       "Relationships Heal",     "Trust and transparency with loved ones begin to rebuild."),
                (180 * 86400,      "Focus Improves",         "Preoccupation with gambling fades; concentration strengthens."),
                (365 * 86400,      "New Identity",           "One year free; identity as a problem gambler recedes significantly."),
            ]
        case .screen:
            return [
                (24 * 3600,        "Restlessness Peaks",     "The urge to check is strongest in the first day — expect it."),
                (48 * 3600,        "Presence Improves",      "Attention span begins to lengthen; boredom tolerance grows."),
                (7 * 86400,        "Sleep Improves",         "Blue-light reduction before bed improves sleep onset and depth."),
                (14 * 86400,       "Mood Steadier",          "Comparison-driven anxiety from social feeds begins to settle."),
                (30 * 86400,       "Focus Returns",          "Sustained-attention tasks become noticeably easier."),
                (90 * 86400,       "Creativity Blooms",      "Boredom-driven creativity returns; new hobbies often emerge."),
                (180 * 86400,      "Relationships Deepen",   "In-person connection quality markedly improves."),
            ]
        case .substance:
            return [
                (24 * 3600,        "Acute Phase Begins",     "The first 24 hours are the hardest — seek professional support."),
                (72 * 3600,        "Acute Phase Passes",     "For most substances, the acute withdrawal window closes."),
                (7 * 86400,        "Physical Stabilising",   "Body begins returning to homeostasis without the substance."),
                (14 * 86400,       "Mental Clarity",         "Cognitive fog lifts; concentration and memory start improving."),
                (30 * 86400,       "Mood Normalises",        "Dopamine and serotonin production begin natural recovery."),
                (90 * 86400,       "PAWS Eases",             "Post-acute withdrawal symptoms (mood swings, cravings) reduce."),
                (180 * 86400,      "Brain Healing",          "Neuroplasticity enables significant structural brain recovery."),
                (365 * 86400,      "One Year Milestone",     "Risk of relapse drops significantly after the first full year."),
            ]
        case .other:
            return [
                (24 * 3600,        "First Day Done",         "You have completed 24 hours. Every hour of resolve counts."),
                (72 * 3600,        "Three Days Strong",      "Early cravings are easing; your brain is adjusting."),
                (7 * 86400,        "One Week Free",          "A full week of cleaner habits is building new neural pathways."),
                (14 * 86400,       "Two Weeks Clear",        "The habit loop is weakening with each day you don't reinforce it."),
                (30 * 86400,       "One Month Milestone",    "Research shows habits lose significant grip after 30 days."),
                (90 * 86400,       "Quarter Year",           "Three months of consistent choices have reshaped your routine."),
                (180 * 86400,      "Half Year",              "Six months in, the new version of you is the default."),
                (365 * 86400,      "Full Year",              "One full year free. You have proved it to yourself."),
            ]
        }
    }
}
