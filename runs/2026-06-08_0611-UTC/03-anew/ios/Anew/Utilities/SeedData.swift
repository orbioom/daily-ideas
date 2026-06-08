import Foundation
import SwiftData

enum SeedData {

    static func insert(into context: ModelContext) {
        let now = Date()
        let cal = Calendar.current

        // ── Helper: date relative to now ────────────────────────────────
        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: now) ?? now
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // QUIT 1 — Alcohol (current streak: 86 days)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        let alcohol = Quit(
            name: "Alcohol",
            symbol: "wineglass",
            colorHex: 0x4FB98C,
            category: .alcohol,
            startDate: daysAgo(86),
            costPerUnit: 12.50,
            unitsPerDay: 2.5,
            unitLabel: "drinks",
            motivation: "Be present for my family and wake up clear every day.",
            order: 0,
            active: true
        )
        context.insert(alcohol)

        // Relapse: once at day 12 (streak of 12 before reset)
        let r1 = Relapse(
            date: daysAgo(86 + 24),
            previousCleanDays: 12,
            note: "Had a bad week at work and slipped at a colleague's party.",
            quit: alcohol
        )
        context.insert(r1)
        alcohol.relapses.append(r1)

        // Check-ins for alcohol — 22 entries over last 86 days
        let alcoholMoods: [(Int, Int, String, Bool)] = [
            (85, 2, "Craving hit hard this morning but I rode it out.", true),
            (83, 3, "Tired but holding on.", true),
            (80, 4, "Starting to feel better physically.", true),
            (77, 3, "Some social pressure at dinner. Stayed strong.", true),
            (74, 4, "Slept 8 hours — can't remember the last time that happened.", true),
            (70, 4, "Energy levels are noticeably better.", true),
            (66, 5, "Ran 5k this morning. Feeling strong.", true),
            (62, 4, "Craving passed quickly today.", true),
            (58, 4, "Work stress but managed without drinking.", true),
            (54, 5, "Hit 60 days — huge milestone.", true),
            (50, 4, "Noticing my skin looks clearer.", false),
            (46, 3, "Low mood but no urge to drink.", true),
            (42, 4, "Friends impressed by my streak.", true),
            (38, 5, "Blood pressure check — doctor said it looks great.", true),
            (34, 4, "Replaced evening drink with tea routine.", true),
            (30, 5, "Three months of mostly clean — nearly there.", true),
            (26, 3, "Anxious week at work.", false),
            (21, 4, "Weekend was fine — didn't even think about it much.", true),
            (16, 4, "Almost at 3 months.", true),
            (11, 5, "Feeling like a new person.", true),
            (6, 4, "Week was calm and productive.", true),
            (1, 5, "85 days — grateful.", true),
        ]
        for (daysBack, mood, note, pledged) in alcoholMoods {
            let ci = CheckIn(
                date: cal.startOfDay(for: daysAgo(daysBack)),
                mood: mood,
                note: note,
                pledged: pledged,
                quit: alcohol
            )
            context.insert(ci)
            alcohol.checkIns.append(ci)
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // QUIT 2 — Nicotine (current streak: 312 days)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        let nicotine = Quit(
            name: "Nicotine",
            symbol: "lungs.fill",
            colorHex: 0x4E6BA8,
            category: .nicotine,
            startDate: daysAgo(312),
            costPerUnit: 14.00,
            unitsPerDay: 1.0,
            unitLabel: "packs",
            motivation: "Run a 10k without gasping. Live to see my kids graduate.",
            order: 1,
            active: true
        )
        context.insert(nicotine)

        // Two past relapses before the current streak
        let r2 = Relapse(
            date: daysAgo(312 + 45),
            previousCleanDays: 41,
            note: "Stressful trip abroad. Bummed a cigarette and that was it.",
            quit: nicotine
        )
        context.insert(r2)
        nicotine.relapses.append(r2)

        let r3 = Relapse(
            date: daysAgo(312 + 120),
            previousCleanDays: 68,
            note: "Wedding weekend — old habits returned briefly.",
            quit: nicotine
        )
        context.insert(r3)
        nicotine.relapses.append(r3)

        // Check-ins — 24 entries
        let nicotineMoods: [(Int, Int, String, Bool)] = [
            (310, 2, "Withdrawal headache but I am not giving in.", true),
            (306, 3, "Lungs feel raw but no cigarette.", true),
            (300, 4, "Sense of smell is back — coffee smells incredible.", true),
            (290, 4, "Running easier already.", true),
            (280, 4, "Haven't coughed in a week.", true),
            (270, 5, "Nine months! CHD risk halving.", true),
            (260, 4, "Energy through the roof compared to a year ago.", true),
            (250, 5, "Ran my first 5k.", true),
            (240, 4, "Not even a craving today.", true),
            (230, 3, "Stressful day — was tempted but walked instead.", true),
            (220, 4, "Dentist said teeth look better.", true),
            (210, 5, "Seven months. People keep saying I look younger.", true),
            (200, 4, "No longer thinking about it daily.", true),
            (190, 4, "200 days soon!", true),
            (180, 5, "Six months. Milestone locked.", true),
            (160, 4, "Breathing is now effortless during exercise.", true),
            (140, 4, "Cough completely gone.", true),
            (120, 5, "Four months. Money saved is astounding.", true),
            (90, 5, "Three months. Longest streak ever.", true),
            (60, 4, "Two months smoke-free.", true),
            (30, 4, "One month. Taking it one day at a time.", true),
            (14, 5, "Two weeks. Taste returning.", true),
            (7, 5, "One week done.", true),
            (1, 5, "311 days — almost a year.", true),
        ]
        for (daysBack, mood, note, pledged) in nicotineMoods {
            let ci = CheckIn(
                date: cal.startOfDay(for: daysAgo(daysBack)),
                mood: mood,
                note: note,
                pledged: pledged,
                quit: nicotine
            )
            context.insert(ci)
            nicotine.checkIns.append(ci)
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // QUIT 3 — Sugar (current streak: 21 days)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        let sugar = Quit(
            name: "Added Sugar",
            symbol: "birthday.cake",
            colorHex: 0xC08A3E,
            category: .sugar,
            startDate: daysAgo(21),
            costPerUnit: 3.00,
            unitsPerDay: 3.0,
            unitLabel: "sweets",
            motivation: "Clear skin, stable energy, no afternoon crashes.",
            order: 2,
            active: true
        )
        context.insert(sugar)

        // One brief relapse — chocolate bar on day 5
        let r4 = Relapse(
            date: daysAgo(21 + 5),
            previousCleanDays: 5,
            note: "Birthday cake at the office. Slipped but got back on track.",
            quit: sugar
        )
        context.insert(r4)
        sugar.relapses.append(r4)

        // Check-ins — 21 entries
        let sugarMoods: [(Int, Int, String, Bool)] = [
            (20, 2, "Cravings intense — brain demanding sugar constantly.", true),
            (19, 2, "Headache from withdrawal. Drinking lots of water.", true),
            (18, 3, "Slightly easier. Finding fruit helps.", true),
            (17, 3, "Energy dipped in the afternoon but no candy.", true),
            (16, 3, "Cravings peaking and then fading faster.", true),
            (15, 4, "One week — blood sugar feeling more stable.", true),
            (13, 4, "Skin clearing noticeably.", true),
            (11, 4, "No afternoon crash today for the first time in months.", true),
            (9, 4, "Finding natural sweetness in berries now.", true),
            (7, 5, "Two weeks! Energy steadied.", true),
            (6, 4, "Mood is much more consistent.", true),
            (5, 3, "Tempted by the biscuit tin but resisted.", true),
            (4, 4, "Sleeping better.", true),
            (3, 4, "Cravings now feel manageable.", true),
            (2, 5, "19 days. Almost at three weeks.", true),
            (1, 5, "Feeling great, 20 days done.", true),
        ]
        for (daysBack, mood, note, pledged) in sugarMoods {
            let ci = CheckIn(
                date: cal.startOfDay(for: daysAgo(daysBack)),
                mood: mood,
                note: note,
                pledged: pledged,
                quit: sugar
            )
            context.insert(ci)
            sugar.checkIns.append(ci)
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // QUIT 4 — Social Media (current streak: 47 days, inactive)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        let screens = Quit(
            name: "Social Media",
            symbol: "iphone",
            colorHex: 0x7C5EA8,
            category: .screen,
            startDate: daysAgo(47),
            costPerUnit: 0,
            unitsPerDay: 0,
            unitLabel: "hours",
            motivation: "Reclaim focus and stop comparing myself to curated feeds.",
            order: 3,
            active: false
        )
        context.insert(screens)

        // Check-ins — 12 entries
        let screenMoods: [(Int, Int, String, Bool)] = [
            (46, 3, "Keep reaching for my phone out of habit.", true),
            (42, 3, "Restless in the evenings without scrolling.", true),
            (38, 4, "Started reading instead. First book in 2 years.", true),
            (34, 4, "Noticed I'm more present at meals.", true),
            (30, 5, "One month. Anxiety noticeably lower.", true),
            (26, 4, "Focus improving at work.", true),
            (22, 4, "Barely miss it now.", true),
            (18, 5, "Sleep improved substantially.", true),
            (14, 4, "Two weeks. Feels good.", true),
            (10, 4, "Reconnected with a friend via actual phone call.", true),
            (5, 4, "Still going strong.", true),
            (1, 5, "46 days off social media.", true),
        ]
        for (daysBack, mood, note, pledged) in screenMoods {
            let ci = CheckIn(
                date: cal.startOfDay(for: daysAgo(daysBack)),
                mood: mood,
                note: note,
                pledged: pledged,
                quit: screens
            )
            context.insert(ci)
            screens.checkIns.append(ci)
        }
    }
}
