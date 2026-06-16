import Foundation
import SwiftData

/// Seeds realistic study data: 5 decks, 60+ cards with spread SRS state, and ~60 review logs.
enum SeedData {

    private struct CardSeed {
        let front: String
        let back: String
        let hint: String
        let example: String
    }

    private struct DeckSeed {
        let name: String
        let description: String
        let colorSeed: Int
        let category: String
        let cards: [CardSeed]
    }

    /// Seed only when the store is empty (idempotent).
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Deck>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        seed(context: context)
    }

    /// Force a fresh seed (used by Settings → Load sample data).
    static func seed(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        var rng = SeededGenerator(seed: 0x5EED_CAFE)

        var allCardsForLogs: [(card: Card, deck: Deck)] = []

        for (deckIndex, ds) in deckSeeds().enumerated() {
            let deck = Deck(name: ds.name,
                            deckDescription: ds.description,
                            colorSeed: ds.colorSeed,
                            category: ds.category,
                            createdDate: now.addingTimeInterval(Double(-deckIndex) * 86_400 * 3))
            context.insert(deck)

            for (cardIndex, cs) in ds.cards.enumerated() {
                let card = Card(front: cs.front,
                                back: cs.back,
                                hint: cs.hint,
                                example: cs.example,
                                createdDate: now.addingTimeInterval(Double(-(cardIndex + deckIndex)) * 3_600))
                applySpread(to: card,
                            position: cardIndex,
                            total: ds.cards.count,
                            today: today,
                            calendar: calendar,
                            rng: &rng)
                card.deck = deck
                deck.cards.append(card)
                if !card.isNew { allCardsForLogs.append((card, deck)) }
            }
        }

        seedLogs(reviewed: allCardsForLogs, today: today, calendar: calendar, context: context, rng: &rng)

        try? context.save()
    }

    /// Spread SRS state across a deck so Stats and Study look real:
    /// roughly a third new, a third due today/overdue, a third scheduled future.
    private static func applySpread(to card: Card,
                                    position: Int,
                                    total: Int,
                                    today: Date,
                                    calendar: Calendar,
                                    rng: inout SeededGenerator) {
        let bucket = position % 6
        switch bucket {
        case 0, 1:
            // Brand new — untouched defaults.
            return
        case 2:
            // Due today / slightly overdue, young.
            card.ease = 2.3 + Double(position % 3) * 0.1
            card.repetitions = 2
            card.intervalDays = 4 + position % 5
            card.lapses = position % 2
            let offset = -(position % 3)
            card.dueDate = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            card.lastReviewed = calendar.date(byAdding: .day, value: -card.intervalDays, to: today)
        case 3:
            // Mature, due today.
            card.ease = 2.6 + Double(position % 4) * 0.05
            card.repetitions = 6 + position % 4
            card.intervalDays = 24 + position % 30
            card.lapses = position % 2
            card.dueDate = today
            card.lastReviewed = calendar.date(byAdding: .day, value: -card.intervalDays, to: today)
        case 4:
            // Scheduled in the near future (young).
            card.ease = 2.45
            card.repetitions = 3
            card.intervalDays = 9 + position % 8
            let ahead = 1 + position % 6
            card.dueDate = calendar.date(byAdding: .day, value: ahead, to: today) ?? today
            card.lastReviewed = calendar.date(byAdding: .day, value: -card.intervalDays, to: today)
        default:
            // Scheduled further out (mature).
            card.ease = 2.7
            card.repetitions = 8
            card.intervalDays = 35 + position % 60
            let ahead = 7 + position % 21
            card.dueDate = calendar.date(byAdding: .day, value: ahead, to: today) ?? today
            card.lastReviewed = calendar.date(byAdding: .day, value: -card.intervalDays, to: today)
        }
    }

    /// Build ~60 review logs over the past 30 days, weighted toward recent days, with a streak.
    private static func seedLogs(reviewed: [(card: Card, deck: Deck)],
                                 today: Date,
                                 calendar: Calendar,
                                 context: ModelContext,
                                 rng: inout SeededGenerator) {
        guard !reviewed.isEmpty else { return }
        // Reviews per day for the last 14 days (a healthy streak), plus scattered older ones.
        let recentPerDay = [6, 4, 7, 5, 8, 3, 6, 5, 4, 7, 6, 5, 9, 4]
        var total = 0
        for (offset, dayCount) in recentPerDay.enumerated() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            for _ in 0..<dayCount {
                let pick = reviewed[Int(rng.next() % UInt64(reviewed.count))]
                let grade = weightedGrade(&rng)
                let secondsIntoDay = Double(rng.next() % 50_000) + 28_000
                let when = day.addingTimeInterval(secondsIntoDay)
                let log = ReviewLog(date: when, grade: grade, cardFront: pick.card.front)
                log.deck = pick.deck
                pick.deck.logs.append(log)
                context.insert(log)
                total += 1
            }
        }
        // A few older scattered reviews (days 16–28) so the 30d chart has depth.
        for offset in [16, 18, 21, 24, 27] {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let n = 2 + Int(rng.next() % 3)
            for _ in 0..<n {
                let pick = reviewed[Int(rng.next() % UInt64(reviewed.count))]
                let grade = weightedGrade(&rng)
                let when = day.addingTimeInterval(Double(rng.next() % 40_000) + 30_000)
                let log = ReviewLog(date: when, grade: grade, cardFront: pick.card.front)
                log.deck = pick.deck
                pick.deck.logs.append(log)
                context.insert(log)
                total += 1
            }
        }
        _ = total
    }

    /// Grade distribution skewed toward success (good retention ~85%).
    private static func weightedGrade(_ rng: inout SeededGenerator) -> Grade {
        let roll = rng.next() % 100
        switch roll {
        case 0..<13: return .again
        case 13..<30: return .hard
        case 30..<82: return .good
        default: return .easy
        }
    }

    /// Wipe all decks (and cascaded cards/logs).
    static func clearAll(context: ModelContext) {
        let descriptor = FetchDescriptor<Deck>()
        if let all = try? context.fetch(descriptor) {
            for deck in all { context.delete(deck) }
            try? context.save()
        }
    }

    // MARK: - Catalog (5 decks, 60+ cards)

    private static func deckSeeds() -> [DeckSeed] {
        [
            DeckSeed(name: "Spanish Essentials",
                     description: "High-frequency Spanish words & phrases for everyday conversation.",
                     colorSeed: 1, category: "Languages",
                     cards: [
                        CardSeed(front: "hola", back: "hello", hint: "greeting", example: "¡Hola! ¿Cómo estás?"),
                        CardSeed(front: "gracias", back: "thank you", hint: "politeness", example: "Muchas gracias por tu ayuda."),
                        CardSeed(front: "por favor", back: "please", hint: "request", example: "Un café, por favor."),
                        CardSeed(front: "buenos días", back: "good morning", hint: "morning greeting", example: "Buenos días, señora."),
                        CardSeed(front: "agua", back: "water", hint: "drink", example: "Quiero un vaso de agua."),
                        CardSeed(front: "comida", back: "food", hint: "what you eat", example: "La comida está deliciosa."),
                        CardSeed(front: "casa", back: "house", hint: "where you live", example: "Mi casa es tu casa."),
                        CardSeed(front: "tiempo", back: "time / weather", hint: "two meanings", example: "No tengo tiempo hoy."),
                        CardSeed(front: "amigo", back: "friend", hint: "person", example: "Él es mi mejor amigo."),
                        CardSeed(front: "trabajo", back: "work / job", hint: "occupation", example: "Voy al trabajo en autobús."),
                        CardSeed(front: "dinero", back: "money", hint: "currency", example: "No tengo suficiente dinero."),
                        CardSeed(front: "ahora", back: "now", hint: "time word", example: "Lo necesito ahora."),
                        CardSeed(front: "siempre", back: "always", hint: "frequency", example: "Siempre llego temprano."),
                        CardSeed(front: "nunca", back: "never", hint: "frequency", example: "Nunca como carne."),
                        CardSeed(front: "ayuda", back: "help", hint: "assistance", example: "¿Puedes darme ayuda?")
                     ]),
            DeckSeed(name: "World Capitals",
                     description: "Match each country to its capital city.",
                     colorSeed: 4, category: "Geography",
                     cards: [
                        CardSeed(front: "France", back: "Paris", hint: "Western Europe", example: "The Eiffel Tower is in the capital."),
                        CardSeed(front: "Japan", back: "Tokyo", hint: "East Asia", example: "The world's largest metro area."),
                        CardSeed(front: "Australia", back: "Canberra", hint: "not Sydney!", example: "Purpose-built capital city."),
                        CardSeed(front: "Canada", back: "Ottawa", hint: "not Toronto!", example: "On the Ottawa River."),
                        CardSeed(front: "Brazil", back: "Brasília", hint: "planned city", example: "Built in the 1950s inland."),
                        CardSeed(front: "Egypt", back: "Cairo", hint: "North Africa", example: "On the Nile near the pyramids."),
                        CardSeed(front: "Kenya", back: "Nairobi", hint: "East Africa", example: "Home to a national park."),
                        CardSeed(front: "Norway", back: "Oslo", hint: "Scandinavia", example: "At the head of a fjord."),
                        CardSeed(front: "Thailand", back: "Bangkok", hint: "Southeast Asia", example: "Known for street food."),
                        CardSeed(front: "Argentina", back: "Buenos Aires", hint: "South America", example: "The 'Paris of the South'."),
                        CardSeed(front: "Turkey", back: "Ankara", hint: "not Istanbul!", example: "Central Anatolia."),
                        CardSeed(front: "South Korea", back: "Seoul", hint: "East Asia", example: "On the Han River."),
                        CardSeed(front: "Morocco", back: "Rabat", hint: "not Casablanca!", example: "On the Atlantic coast."),
                        CardSeed(front: "New Zealand", back: "Wellington", hint: "not Auckland!", example: "Windy harbor capital.")
                     ]),
            DeckSeed(name: "SAT Vocabulary",
                     description: "College-prep words that show up on standardized tests.",
                     colorSeed: 5, category: "Test Prep",
                     cards: [
                        CardSeed(front: "ubiquitous", back: "present everywhere", hint: "omnipresent", example: "Smartphones are ubiquitous today."),
                        CardSeed(front: "ephemeral", back: "lasting a very short time", hint: "fleeting", example: "Fame can be ephemeral."),
                        CardSeed(front: "pragmatic", back: "practical, realistic", hint: "down-to-earth", example: "A pragmatic solution to the budget."),
                        CardSeed(front: "candid", back: "honest and direct", hint: "frank", example: "She gave a candid answer."),
                        CardSeed(front: "meticulous", back: "very careful and precise", hint: "thorough", example: "A meticulous accountant."),
                        CardSeed(front: "ambivalent", back: "having mixed feelings", hint: "torn", example: "He felt ambivalent about moving."),
                        CardSeed(front: "tenacious", back: "persistent, holding firmly", hint: "stubbornly determined", example: "A tenacious competitor."),
                        CardSeed(front: "verbose", back: "using too many words", hint: "wordy", example: "The verbose report lost readers."),
                        CardSeed(front: "frugal", back: "economical, thrifty", hint: "careful with money", example: "Frugal habits build savings."),
                        CardSeed(front: "gregarious", back: "sociable, fond of company", hint: "outgoing", example: "A gregarious host."),
                        CardSeed(front: "lucid", back: "clear and easy to understand", hint: "coherent", example: "A lucid explanation."),
                        CardSeed(front: "obstinate", back: "stubborn", hint: "won't budge", example: "An obstinate refusal."),
                        CardSeed(front: "prudent", back: "wise, showing good judgment", hint: "sensible", example: "A prudent investment."),
                        CardSeed(front: "scrutinize", back: "examine closely", hint: "inspect", example: "Scrutinize the contract first.")
                     ]),
            DeckSeed(name: "Human Anatomy",
                     description: "Core structures of the human body for biology & med prep.",
                     colorSeed: 2, category: "Science",
                     cards: [
                        CardSeed(front: "femur", back: "thigh bone", hint: "longest bone", example: "The femur connects hip to knee."),
                        CardSeed(front: "atrium", back: "upper heart chamber", hint: "receives blood", example: "Blood enters the right atrium."),
                        CardSeed(front: "alveoli", back: "tiny air sacs in the lungs", hint: "gas exchange", example: "Oxygen crosses the alveoli."),
                        CardSeed(front: "nephron", back: "filtering unit of the kidney", hint: "renal", example: "Each kidney has ~1M nephrons."),
                        CardSeed(front: "cerebellum", back: "brain region for balance & coordination", hint: "'little brain'", example: "The cerebellum smooths movement."),
                        CardSeed(front: "patella", back: "kneecap", hint: "front of knee", example: "The patella protects the joint."),
                        CardSeed(front: "trachea", back: "windpipe", hint: "airway", example: "Air passes down the trachea."),
                        CardSeed(front: "aorta", back: "largest artery", hint: "leaves the heart", example: "The aorta carries oxygenated blood."),
                        CardSeed(front: "synapse", back: "gap between two neurons", hint: "signal jump", example: "Neurotransmitters cross the synapse."),
                        CardSeed(front: "cornea", back: "clear front layer of the eye", hint: "focuses light", example: "The cornea bends incoming light."),
                        CardSeed(front: "pancreas", back: "organ making insulin & enzymes", hint: "behind stomach", example: "The pancreas regulates blood sugar."),
                        CardSeed(front: "scapula", back: "shoulder blade", hint: "upper back", example: "Muscles attach to the scapula.")
                     ]),
            DeckSeed(name: "Italian Food Words",
                     description: "Order with confidence — essential Italian culinary vocabulary.",
                     colorSeed: 3, category: "Languages",
                     cards: [
                        CardSeed(front: "formaggio", back: "cheese", hint: "dairy", example: "Vorrei del formaggio."),
                        CardSeed(front: "pane", back: "bread", hint: "bakery", example: "Il pane è fresco."),
                        CardSeed(front: "pollo", back: "chicken", hint: "poultry", example: "Pollo alla griglia, per favore."),
                        CardSeed(front: "pesce", back: "fish", hint: "seafood", example: "Il pesce del giorno."),
                        CardSeed(front: "verdura", back: "vegetables", hint: "produce", example: "Una zuppa di verdura."),
                        CardSeed(front: "dolce", back: "dessert / sweet", hint: "end of meal", example: "Che dolce consiglia?"),
                        CardSeed(front: "vino", back: "wine", hint: "drink", example: "Un bicchiere di vino rosso."),
                        CardSeed(front: "uovo", back: "egg", hint: "breakfast", example: "Un uovo sodo."),
                        CardSeed(front: "burro", back: "butter", hint: "not a donkey!", example: "Pasta al burro."),
                        CardSeed(front: "zucchero", back: "sugar", hint: "sweetener", example: "Caffè senza zucchero."),
                        CardSeed(front: "riso", back: "rice", hint: "risotto base", example: "Il riso per il risotto."),
                        CardSeed(front: "prosciutto", back: "ham", hint: "cured meat", example: "Prosciutto e melone.")
                     ])
        ]
    }
}

/// A small deterministic PRNG so seeded data is stable across runs (xorshift64*).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545_F491_4F6C_DD1D
    }
}
