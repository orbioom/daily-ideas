import Foundation

/// The pure question-generation engine. No SwiftUI, no SwiftData — it takes a
/// snapshot of mastery and produces fully-formed `QuizQuestion`s. Selection is
/// adaptive (weighted toward unseen / low-mastery countries) and distractors are
/// drawn from the same continent/region where possible so choices stay plausible.
struct QuizEngine {

    /// A lightweight, value-type snapshot of per-country mastery so the engine
    /// stays decoupled from SwiftData models.
    struct MasterySnapshot {
        /// iso2 -> mastery in 0...1.
        var mastery: [String: Double]
        /// iso2 -> times seen.
        var seen: [String: Int]

        init(mastery: [String: Double] = [:], seen: [String: Int] = [:]) {
            self.mastery = mastery
            self.seen = seen
        }

        func mastery(for iso2: String) -> Double { mastery[iso2] ?? 0 }
        func seen(for iso2: String) -> Int { seen[iso2] ?? 0 }
    }

    // MARK: Configuration

    /// Number of choices presented per question (capped to pool size).
    static let choiceCount = 4

    // MARK: Pool

    /// Countries eligible for a quiz given an optional continent filter.
    static func pool(continent: Continent?) -> [Country] {
        if let continent {
            return CountryData.countries(in: continent)
        }
        return CountryData.all
    }

    // MARK: Adaptive selection

    /// Pick `count` subject countries using mastery-weighted sampling without
    /// replacement. Unseen and low-mastery countries get higher weight so the
    /// quiz drills weak spots. Deterministic when given a seeded generator.
    static func selectSubjects(count: Int,
                               continent: Continent?,
                               snapshot: MasterySnapshot,
                               using rng: inout some RandomNumberGenerator) -> [Country] {
        var available = pool(continent: continent)
        guard !available.isEmpty else { return [] }
        let target = min(count, available.count)
        var chosen: [Country] = []
        chosen.reserveCapacity(target)

        for _ in 0..<target {
            // weight = base + penalty * (1 - mastery); unseen gets a bonus.
            let weights = available.map { country -> Double in
                let m = snapshot.mastery(for: country.iso2)
                let unseenBonus = snapshot.seen(for: country.iso2) == 0 ? 1.2 : 0.0
                return 1.0 + 2.5 * (1.0 - m) + unseenBonus
            }
            let total = weights.reduce(0, +)
            guard total > 0 else {
                // Degenerate fallback: pick the first remaining.
                chosen.append(available.removeFirst())
                continue
            }
            var roll = Double.random(in: 0..<total, using: &rng)
            var pickedIndex = available.count - 1
            for (i, w) in weights.enumerated() {
                roll -= w
                if roll < 0 { pickedIndex = i; break }
            }
            chosen.append(available.remove(at: pickedIndex))
        }
        return chosen
    }

    // MARK: Question building

    /// Build a question for one subject country in the given mode. Distractors
    /// are preferentially same-region, then same-continent, then anywhere.
    static func makeQuestion(mode: QuizMode,
                             subject: Country,
                             pool: [Country],
                             using rng: inout some RandomNumberGenerator) -> QuizQuestion {
        switch mode {
        case .biggerPopulation:
            return makePopulationQuestion(subject: subject, pool: pool, using: &rng)
        default:
            return makeMultipleChoice(mode: mode, subject: subject, pool: pool, using: &rng)
        }
    }

    private static func makeMultipleChoice(mode: QuizMode,
                                           subject: Country,
                                           pool: [Country],
                                           using rng: inout some RandomNumberGenerator) -> QuizQuestion {
        // The "answer text" extractor for this mode.
        let answerText: (Country) -> String
        switch mode {
        case .flagToCountry, .capitalToCountry:
            answerText = { $0.name }
        case .countryToCapital:
            answerText = { $0.capital }
        case .flagToContinent:
            answerText = { $0.continent.title }
        case .biggerPopulation:
            answerText = { $0.name } // unreachable here
        }

        var labels: [String] = [answerText(subject)]

        if mode == .flagToContinent {
            // Choices are continents, not countries.
            var continents = Continent.displayOrder.filter { $0 != subject.continent }
            continents.shuffle(using: &rng)
            for c in continents where labels.count < choiceCount {
                labels.append(c.title)
            }
        } else {
            let distractors = distractorCountries(for: subject, pool: pool,
                                                  needed: choiceCount - 1,
                                                  answerText: answerText, using: &rng)
            for d in distractors { labels.append(answerText(d)) }
        }

        // De-duplicate while preserving the correct label, then shuffle.
        var seen = Set<String>()
        var unique: [String] = []
        for l in labels where seen.insert(l).inserted { unique.append(l) }
        unique.shuffle(using: &rng)

        let answerIndex = unique.firstIndex(of: answerText(subject)) ?? 0
        let choices = unique.map { QuizQuestion.Choice(label: $0, flag: nil) }

        let promptPrimary: String
        let promptSecondary: String?
        let isFlag: Bool
        switch mode {
        case .flagToCountry:
            promptPrimary = subject.flag; promptSecondary = "Which country?"; isFlag = true
        case .flagToContinent:
            promptPrimary = subject.flag; promptSecondary = "Which continent?"; isFlag = true
        case .countryToCapital:
            promptPrimary = subject.name; promptSecondary = "What is the capital?"; isFlag = false
        case .capitalToCountry:
            promptPrimary = subject.capital; promptSecondary = "Capital of which country?"; isFlag = false
        case .biggerPopulation:
            promptPrimary = subject.name; promptSecondary = nil; isFlag = false
        }

        return QuizQuestion(mode: mode,
                            subjectISO2: subject.iso2,
                            promptPrimary: promptPrimary,
                            promptSecondary: promptSecondary,
                            promptIsFlag: isFlag,
                            choices: choices,
                            answerIndex: answerIndex)
    }

    private static func makePopulationQuestion(subject: Country,
                                               pool: [Country],
                                               using rng: inout some RandomNumberGenerator) -> QuizQuestion {
        // Find an opponent with a meaningfully different population, ideally from
        // the same continent so the contrast is interesting.
        let candidates = pool.filter {
            $0.iso2 != subject.iso2 &&
            abs($0.populationMillions - subject.populationMillions) > 0.01
        }
        let sameContinent = candidates.filter { $0.continent == subject.continent }
        let opponentSource = sameContinent.isEmpty ? candidates : sameContinent
        // Fall back to the whole dataset if the filtered pool was too small.
        let finalSource = opponentSource.isEmpty
            ? CountryData.all.filter { $0.iso2 != subject.iso2 }
            : opponentSource
        let opponent = finalSource.randomElement(using: &rng) ?? subject

        let bigger = subject.populationMillions >= opponent.populationMillions ? subject : opponent
        let pair = [subject, opponent].shuffled(using: &rng)
        let choices = pair.map { QuizQuestion.Choice(label: $0.name, flag: $0.flag) }
        let answerIndex = pair.firstIndex(where: { $0.iso2 == bigger.iso2 }) ?? 0

        return QuizQuestion(mode: .biggerPopulation,
                            subjectISO2: bigger.iso2,
                            promptPrimary: "Which has more people?",
                            promptSecondary: nil,
                            promptIsFlag: false,
                            choices: choices,
                            answerIndex: answerIndex)
    }

    /// Distractors preferring same region, then continent, then global. Avoids
    /// any country whose answer text collides with the subject's.
    private static func distractorCountries(for subject: Country,
                                            pool: [Country],
                                            needed: Int,
                                            answerText: (Country) -> String,
                                            using rng: inout some RandomNumberGenerator) -> [Country] {
        guard needed > 0 else { return [] }
        let subjectAnswer = answerText(subject)
        var result: [Country] = []
        var usedAnswers: Set<String> = [subjectAnswer]

        let basePool = pool.isEmpty ? CountryData.all : pool
        // Tiered sources: same region first, then same continent, then global.
        let tiers: [[Country]] = [
            basePool.filter { $0.region == subject.region && $0.iso2 != subject.iso2 },
            basePool.filter { $0.continent == subject.continent && $0.iso2 != subject.iso2 },
            CountryData.all.filter { $0.iso2 != subject.iso2 }
        ]

        for tier in tiers where result.count < needed {
            var shuffled = tier.shuffled(using: &rng)
            while result.count < needed, let next = shuffled.popLast() {
                let a = answerText(next)
                guard usedAnswers.insert(a).inserted else { continue }
                result.append(next)
            }
        }
        return result
    }

    // MARK: Full quiz assembly

    /// Build a complete quiz: select subjects adaptively, then a question each.
    static func makeQuiz(mode: QuizMode,
                         count: Int,
                         continent: Continent?,
                         snapshot: MasterySnapshot,
                         using rng: inout some RandomNumberGenerator) -> [QuizQuestion] {
        let questionPool = pool(continent: continent)
        guard questionPool.count >= 2 else { return [] }
        let subjects = selectSubjects(count: count, continent: continent,
                                      snapshot: snapshot, using: &rng)
        var questions: [QuizQuestion] = []
        questions.reserveCapacity(subjects.count)
        for subject in subjects {
            questions.append(makeQuestion(mode: mode, subject: subject,
                                          pool: questionPool, using: &rng))
        }
        return questions
    }

    // MARK: Daily challenge (deterministic)

    /// The fixed 10-question daily set. Same for everyone on a given date — it
    /// ignores personal mastery and uses a date-seeded generator. Cycles through
    /// the multiple-choice modes for variety.
    static func dailyChallenge(for date: Date = Date(),
                               calendar: Calendar = .current) -> [QuizQuestion] {
        let key = dailyKey(for: date, calendar: calendar)
        var rng = SeededRandom(seed: key.stableSeed)
        let modes: [QuizMode] = [.flagToCountry, .countryToCapital, .capitalToCountry, .flagToContinent]
        let all = CountryData.all
        guard all.count >= 2 else { return [] }

        var pickedISO = Set<String>()
        var questions: [QuizQuestion] = []
        var attempts = 0
        while questions.count < 10 && attempts < 200 {
            attempts += 1
            guard let subject = all.randomElement(using: &rng) else { break }
            if pickedISO.contains(subject.iso2) { continue }
            pickedISO.insert(subject.iso2)
            let mode = modes[questions.count % modes.count]
            questions.append(makeQuestion(mode: mode, subject: subject,
                                          pool: all, using: &rng))
        }
        return questions
    }

    /// Deterministic yyyy-MM-dd key for the daily seed.
    static func dailyKey(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2000
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
