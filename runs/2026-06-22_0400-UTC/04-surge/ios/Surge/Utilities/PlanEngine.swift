import Foundation

struct PlannedRunTemplate {
    let weekNumber: Int
    let dayOfWeek: Int           // 0=Mon, 6=Sun
    let runType: RunType
    let distanceKm: Double
    let paceTargetSecondsPerKm: Double
    let notes: String
}

struct PlanEngine {

    // MARK: - Public API

    static func generatePlan(
        raceType: RaceType,
        goalTimeSeconds: Int,
        startDate: Date
    ) -> [PlannedRunTemplate] {
        let paces = PaceEngine.trainingPaces(goalRaceSeconds: goalTimeSeconds, raceType: raceType)
        switch raceType {
        case .marathon:
            return generateMarathonPlan(paces: paces)
        case .halfMarathon:
            return generateHalfMarathonPlan(paces: paces)
        }
    }

    // MARK: - Marathon Plan (16 Weeks)

    private static func generateMarathonPlan(paces: TrainingPaces) -> [PlannedRunTemplate] {
        var runs: [PlannedRunTemplate] = []

        // Week schedules: [Mon=0, Tue=1, Wed=2, Thu=3, Fri=4, Sat=5, Sun=6]
        // Format: (dayOfWeek, runType, distanceKm, notes)
        let weeklyPlans: [[(Int, RunType, Double, String)]] = [
            // Week 1 - Base building (~31km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 5, "Easy effort, conversational pace"),
                (2, .crossTrain, 0, "Cross-train 30–45 min"),
                (3, .easy, 6, "Easy effort"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 8, "Easy effort"),
                (6, .long, 12, "Easy long run, build endurance")
            ],
            // Week 2 (~34km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 6, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 30–45 min"),
                (3, .easy, 6, "Easy effort"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 8, "Easy effort"),
                (6, .long, 14, "Easy long run")
            ],
            // Week 3 (~37km) — introduce tempo
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 6, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 30–45 min"),
                (3, .tempo, 6, "Tempo: 2km warm-up, 3km at tempo, 1km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 9, "Easy effort"),
                (6, .long, 16, "Easy long run")
            ],
            // Week 4 — Recovery week (~29km)
            [
                (0, .rest, 0, "Recovery week — reduce volume"),
                (1, .easy, 5, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 30 min"),
                (3, .easy, 5, "Easy effort"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 6, "Easy effort"),
                (6, .long, 13, "Easy long run — enjoy the lighter load")
            ],
            // Week 5 (~42km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 8, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 45 min"),
                (3, .tempo, 8, "Tempo: 2km warm-up, 4km at tempo, 2km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 10, "Easy effort"),
                (6, .long, 18, "Easy long run")
            ],
            // Week 6 (~46km) — introduce intervals
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 8, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 45 min"),
                (3, .interval, 8, "6×800m at interval pace with 90s recovery jog"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 10, "Easy effort"),
                (6, .long, 20, "Easy long run — first 20km!")
            ],
            // Week 7 (~49km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 8, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 45 min"),
                (3, .tempo, 10, "Tempo: 2km warm-up, 6km at tempo, 2km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 11, "Easy effort"),
                (6, .long, 22, "Easy long run")
            ],
            // Week 8 — Recovery (~36km)
            [
                (0, .rest, 0, "Recovery week"),
                (1, .easy, 6, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 30 min"),
                (3, .easy, 6, "Easy effort"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 8, "Easy effort"),
                (6, .long, 16, "Easy long run")
            ],
            // Week 9 (~54km) — building to peak
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 10, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 45 min"),
                (3, .interval, 10, "8×400m at interval pace with 90s recovery"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 10, "Easy effort"),
                (6, .long, 24, "Easy long run")
            ],
            // Week 10 (~57km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 10, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 45 min"),
                (3, .tempo, 11, "Tempo: 2km warm-up, 7km at tempo, 2km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 11, "Easy effort"),
                (6, .long, 26, "Easy long run")
            ],
            // Week 11 (~60km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 11, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 45 min"),
                (3, .interval, 11, "6×1km at interval pace with 2 min recovery"),
                (4, .rest, 0, "Rest day"),
                (5, .racePace, 10, "Race pace miles — feel the rhythm"),
                (6, .long, 29, "Easy long run")
            ],
            // Week 12 — Recovery (~45km)
            [
                (0, .rest, 0, "Recovery week"),
                (1, .easy, 8, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 30 min"),
                (3, .easy, 8, "Easy effort"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 8, "Easy effort"),
                (6, .long, 21, "Easy long run")
            ],
            // Week 13 (~64km) — Peak week approach
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 11, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 45 min"),
                (3, .tempo, 12, "Tempo: 2km warm-up, 8km at tempo, 2km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .racePace, 11, "Race pace run — build confidence"),
                (6, .long, 32, "Peak long run — you've got this!")
            ],
            // Week 14 — Taper begins (~48km)
            [
                (0, .rest, 0, "Taper begins — trust the process"),
                (1, .easy, 10, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 30 min"),
                (3, .tempo, 8, "Tempo: 2km warm-up, 4km at tempo, 2km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 8, "Easy effort"),
                (6, .long, 22, "Easy long run")
            ],
            // Week 15 — Deep taper (~35km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 8, "Easy effort"),
                (2, .crossTrain, 0, "Light cross-train 20–30 min"),
                (3, .racePace, 6, "Race pace: 2km warm-up, 3km at race pace, 1km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 6, "Easy shakeout"),
                (6, .long, 14, "Easy long run — feel fresh!")
            ],
            // Week 16 — Race week (~13km before race)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 5, "Easy shakeout, stay loose"),
                (2, .rest, 0, "Rest day"),
                (3, .easy, 4, "Easy 4km, strides at the end"),
                (4, .rest, 0, "Rest — eat well, hydrate!"),
                (5, .easy, 3, "Easy 3km shakeout, race day tomorrow!"),
                (6, .racePace, 42.195, "RACE DAY — Go get your marathon! 🎉")
            ]
        ]

        for (weekIndex, weekPlan) in weeklyPlans.enumerated() {
            let weekNumber = weekIndex + 1
            for (day, runType, distance, notes) in weekPlan {
                let paceTarget = runType.isRunningWorkout ? paces.pace(for: runType) : 0
                runs.append(PlannedRunTemplate(
                    weekNumber: weekNumber,
                    dayOfWeek: day,
                    runType: runType,
                    distanceKm: distance,
                    paceTargetSecondsPerKm: paceTarget,
                    notes: notes
                ))
            }
        }

        return runs
    }

    // MARK: - Half Marathon Plan (12 Weeks)

    private static func generateHalfMarathonPlan(paces: TrainingPaces) -> [PlannedRunTemplate] {
        var runs: [PlannedRunTemplate] = []

        let weeklyPlans: [[(Int, RunType, Double, String)]] = [
            // Week 1 (~24km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 4, "Easy effort, conversational pace"),
                (2, .crossTrain, 0, "Cross-train 30 min"),
                (3, .easy, 5, "Easy effort"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 6, "Easy effort"),
                (6, .long, 9, "Easy long run")
            ],
            // Week 2 (~27km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 5, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 30 min"),
                (3, .easy, 5, "Easy effort"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 6, "Easy effort"),
                (6, .long, 11, "Easy long run")
            ],
            // Week 3 (~31km) — introduce tempo
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 5, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 30 min"),
                (3, .tempo, 6, "Tempo: 1.5km warm-up, 3km at tempo, 1.5km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 6, "Easy effort"),
                (6, .long, 13, "Easy long run")
            ],
            // Week 4 — Recovery (~22km)
            [
                (0, .rest, 0, "Recovery week"),
                (1, .easy, 4, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 25 min"),
                (3, .easy, 4, "Easy effort"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 5, "Easy effort"),
                (6, .long, 9, "Easy long run")
            ],
            // Week 5 (~37km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 6, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 40 min"),
                (3, .interval, 7, "6×400m at interval pace with 90s recovery"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 8, "Easy effort"),
                (6, .long, 15, "Easy long run")
            ],
            // Week 6 (~42km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 6, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 40 min"),
                (3, .tempo, 8, "Tempo: 2km warm-up, 4km at tempo, 2km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 9, "Easy effort"),
                (6, .long, 17, "Easy long run")
            ],
            // Week 7 (~46km) — approaching peak
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 8, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 40 min"),
                (3, .interval, 8, "5×800m at interval pace with 90s recovery"),
                (4, .rest, 0, "Rest day"),
                (5, .racePace, 8, "Race pace run — practice your goal pace"),
                (6, .long, 19, "Easy long run")
            ],
            // Week 8 — Recovery (~33km)
            [
                (0, .rest, 0, "Recovery week"),
                (1, .easy, 5, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 30 min"),
                (3, .easy, 6, "Easy effort"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 6, "Easy effort"),
                (6, .long, 14, "Easy long run")
            ],
            // Week 9 (~50km) — Peak week
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 8, "Easy effort"),
                (2, .crossTrain, 0, "Cross-train 40 min"),
                (3, .tempo, 10, "Tempo: 2km warm-up, 6km at tempo, 2km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .racePace, 8, "Race pace run"),
                (6, .long, 21, "Peak long run — half marathon distance! You're ready.")
            ],
            // Week 10 — Taper starts (~38km)
            [
                (0, .rest, 0, "Taper begins — trust the process"),
                (1, .easy, 6, "Easy effort"),
                (2, .crossTrain, 0, "Light cross-train 25 min"),
                (3, .tempo, 7, "Tempo: 2km warm-up, 3km at tempo, 2km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 8, "Easy effort"),
                (6, .long, 16, "Easy long run")
            ],
            // Week 11 — Deep taper (~26km)
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 5, "Easy effort"),
                (2, .crossTrain, 0, "Light cross-train 20 min"),
                (3, .racePace, 5, "Race pace: 1km warm-up, 3km at race pace, 1km cool-down"),
                (4, .rest, 0, "Rest day"),
                (5, .easy, 4, "Easy shakeout"),
                (6, .long, 11, "Easy run — feel fresh!")
            ],
            // Week 12 — Race week
            [
                (0, .rest, 0, "Rest day"),
                (1, .easy, 4, "Easy shakeout"),
                (2, .rest, 0, "Rest day"),
                (3, .easy, 3, "Easy 3km with strides"),
                (4, .rest, 0, "Rest — eat well, hydrate!"),
                (5, .easy, 2, "Easy 2km shakeout, race tomorrow!"),
                (6, .racePace, 21.0975, "RACE DAY — Run your best half marathon! 🎉")
            ]
        ]

        for (weekIndex, weekPlan) in weeklyPlans.enumerated() {
            let weekNumber = weekIndex + 1
            for (day, runType, distance, notes) in weekPlan {
                let paceTarget = runType.isRunningWorkout ? paces.pace(for: runType) : 0
                runs.append(PlannedRunTemplate(
                    weekNumber: weekNumber,
                    dayOfWeek: day,
                    runType: runType,
                    distanceKm: distance,
                    paceTargetSecondsPerKm: paceTarget,
                    notes: notes
                ))
            }
        }

        return runs
    }

    // MARK: - Helpers

    /// Calculate what date a given week+day falls on given a training start date
    static func date(for weekNumber: Int, dayOfWeek: Int, startDate: Date) -> Date {
        let calendar = Calendar.current
        let weekOffset = (weekNumber - 1) * 7
        let dayOffset = dayOfWeek
        let totalOffset = weekOffset + dayOffset
        return calendar.date(byAdding: .day, value: totalOffset, to: startDate) ?? startDate
    }

    /// Get the week number for today based on training start date
    static func currentWeek(startDate: Date, totalWeeks: Int) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(1, min(totalWeeks, (days / 7) + 1))
    }

    /// Get today's day of week index (0=Mon, 6=Sun)
    static func currentDayOfWeek() -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Calendar: 1=Sun, 2=Mon ... 7=Sat → convert to 0=Mon, 6=Sun
        return (weekday + 5) % 7
    }

    /// Total planned km for a given week
    static func totalKm(for weekTemplates: [PlannedRunTemplate]) -> Double {
        return weekTemplates.reduce(0) { $0 + $1.distanceKm }
    }
}
