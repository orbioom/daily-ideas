import Foundation

/// Static, on-device reference for each gestational week — size comparison,
/// approximate length/weight, a development note, and a gentle tip. No network.
struct WeekInfo: Identifiable {
    let week: Int
    let fruit: String       // size comparison
    let symbol: String      // SF Symbol for the comparison
    let lengthCm: Double    // crown-to-rump early, crown-to-heel later (approx)
    let weightG: Double
    let summary: String
    let tip: String

    var id: Int { week }

    var lengthString: String {
        lengthCm <= 0 ? "—" : String(format: "%.1f cm", lengthCm)
    }
    var weightString: String {
        if weightG <= 0 { return "—" }
        if weightG < 1000 { return String(format: "%.0f g", weightG) }
        return String(format: "%.2f kg", weightG / 1000)
    }
}

enum WeekCatalog {
    static func info(for week: Int) -> WeekInfo {
        let clamped = min(max(week, 4), 40)
        return all.first { $0.week == clamped } ?? all[0]
    }

    static let all: [WeekInfo] = [
        WeekInfo(week: 4,  fruit: "Poppy seed", symbol: "circle.fill", lengthCm: 0.1, weightG: 0,
                 summary: "The embryo implants and the placenta begins to form.",
                 tip: "Start (or continue) a prenatal vitamin with folic acid."),
        WeekInfo(week: 5,  fruit: "Sesame seed", symbol: "circle.fill", lengthCm: 0.2, weightG: 0,
                 summary: "The neural tube — baby's brain and spine — starts to develop.",
                 tip: "Hydrate well; early fatigue is normal."),
        WeekInfo(week: 6,  fruit: "Lentil", symbol: "circle.fill", lengthCm: 0.5, weightG: 0,
                 summary: "A tiny heart begins to beat this week.",
                 tip: "Eat small, frequent meals if nausea appears."),
        WeekInfo(week: 7,  fruit: "Blueberry", symbol: "circle.fill", lengthCm: 1.0, weightG: 0,
                 summary: "Arm and leg buds emerge; the brain grows rapidly.",
                 tip: "Rest when you can — your body is working hard."),
        WeekInfo(week: 8,  fruit: "Raspberry", symbol: "circle.fill", lengthCm: 1.6, weightG: 1,
                 summary: "Fingers and toes begin to form; baby is now a fetus.",
                 tip: "Book your first prenatal appointment if you haven't."),
        WeekInfo(week: 9,  fruit: "Cherry", symbol: "circle.fill", lengthCm: 2.3, weightG: 2,
                 summary: "Essential organs are forming and the tail disappears.",
                 tip: "Gentle movement like walking can ease symptoms."),
        WeekInfo(week: 10, fruit: "Strawberry", symbol: "circle.fill", lengthCm: 3.1, weightG: 4,
                 summary: "Tiny nails start to form and joints can bend.",
                 tip: "Add fiber-rich foods to help digestion."),
        WeekInfo(week: 11, fruit: "Lime", symbol: "circle.fill", lengthCm: 4.1, weightG: 7,
                 summary: "Baby can open and close their fists.",
                 tip: "Keep snacks nearby for steady energy."),
        WeekInfo(week: 12, fruit: "Plum", symbol: "circle.fill", lengthCm: 5.4, weightG: 14,
                 summary: "Reflexes develop; the end of the first trimester nears.",
                 tip: "Many feel nausea ease soon — hang in there."),
        WeekInfo(week: 13, fruit: "Peach", symbol: "circle.fill", lengthCm: 7.4, weightG: 23,
                 summary: "Vocal cords and fingerprints are forming.",
                 tip: "Welcome to the second trimester — energy often returns."),
        WeekInfo(week: 14, fruit: "Lemon", symbol: "circle.fill", lengthCm: 8.7, weightG: 43,
                 summary: "Baby can make facial expressions now.",
                 tip: "A good time for gentle prenatal exercise."),
        WeekInfo(week: 15, fruit: "Apple", symbol: "circle.fill", lengthCm: 10.1, weightG: 70,
                 summary: "Baby is sensing light and moving more.",
                 tip: "Sleep on your side for better circulation."),
        WeekInfo(week: 16, fruit: "Avocado", symbol: "circle.fill", lengthCm: 11.6, weightG: 100,
                 summary: "Tiny bones are hardening and ears are in place.",
                 tip: "You may feel the first flutters soon."),
        WeekInfo(week: 17, fruit: "Pear", symbol: "circle.fill", lengthCm: 13.0, weightG: 140,
                 summary: "Baby is developing a layer of fat.",
                 tip: "Stay mindful of posture as your center shifts."),
        WeekInfo(week: 18, fruit: "Bell pepper", symbol: "circle.fill", lengthCm: 14.2, weightG: 190,
                 summary: "Baby can hear sounds from outside the womb.",
                 tip: "Talk or play music — baby is listening."),
        WeekInfo(week: 19, fruit: "Mango", symbol: "circle.fill", lengthCm: 15.3, weightG: 240,
                 summary: "A protective coating (vernix) covers the skin.",
                 tip: "Moisturize to ease skin stretching and itch."),
        WeekInfo(week: 20, fruit: "Banana", symbol: "circle.fill", lengthCm: 25.6, weightG: 300,
                 summary: "Halfway there — the anatomy scan often happens now.",
                 tip: "You may learn the sex at your scan if you wish."),
        WeekInfo(week: 21, fruit: "Carrot", symbol: "circle.fill", lengthCm: 26.7, weightG: 360,
                 summary: "Baby's movements grow stronger and more regular.",
                 tip: "Note patterns of movement as they emerge."),
        WeekInfo(week: 22, fruit: "Papaya", symbol: "circle.fill", lengthCm: 27.8, weightG: 430,
                 summary: "Lips, eyelids and eyebrows are more distinct.",
                 tip: "Keep up balanced meals with iron and protein."),
        WeekInfo(week: 23, fruit: "Grapefruit", symbol: "circle.fill", lengthCm: 28.9, weightG: 500,
                 summary: "Baby's hearing is sharpening week by week.",
                 tip: "Stay active within comfort; rest as needed."),
        WeekInfo(week: 24, fruit: "Corn cob", symbol: "circle.fill", lengthCm: 30.0, weightG: 600,
                 summary: "Lungs are developing air sacs — a key milestone.",
                 tip: "Ask about glucose screening timing."),
        WeekInfo(week: 25, fruit: "Rutabaga", symbol: "circle.fill", lengthCm: 34.6, weightG: 660,
                 summary: "Baby is putting on baby fat and looking rounder.",
                 tip: "Watch for swelling; elevate your feet."),
        WeekInfo(week: 26, fruit: "Lettuce head", symbol: "circle.fill", lengthCm: 35.6, weightG: 760,
                 summary: "Eyes begin to open and respond to light.",
                 tip: "Start thinking about your birth preferences."),
        WeekInfo(week: 27, fruit: "Cauliflower", symbol: "circle.fill", lengthCm: 36.6, weightG: 875,
                 summary: "Brain activity increases as the third trimester begins.",
                 tip: "Begin counting kicks daily if advised."),
        WeekInfo(week: 28, fruit: "Eggplant", symbol: "circle.fill", lengthCm: 37.6, weightG: 1000,
                 summary: "Baby can blink and may dream during sleep.",
                 tip: "Appointments often become more frequent now."),
        WeekInfo(week: 29, fruit: "Butternut squash", symbol: "circle.fill", lengthCm: 38.6, weightG: 1150,
                 summary: "Muscles and lungs continue to mature.",
                 tip: "Keep tracking movement patterns."),
        WeekInfo(week: 30, fruit: "Cabbage", symbol: "circle.fill", lengthCm: 39.9, weightG: 1320,
                 summary: "Baby's brain is growing fast and getting wrinklier.",
                 tip: "Practice relaxation and breathing techniques."),
        WeekInfo(week: 31, fruit: "Coconut", symbol: "circle.fill", lengthCm: 41.1, weightG: 1500,
                 summary: "Baby can turn their head and is gaining steadily.",
                 tip: "Consider a hospital bag checklist."),
        WeekInfo(week: 32, fruit: "Squash", symbol: "circle.fill", lengthCm: 42.4, weightG: 1700,
                 summary: "Baby often settles head-down around now.",
                 tip: "Rest on your left side for best blood flow."),
        WeekInfo(week: 33, fruit: "Pineapple", symbol: "circle.fill", lengthCm: 43.7, weightG: 1920,
                 summary: "Bones harden while the skull stays soft for birth.",
                 tip: "Stay hydrated to help with Braxton Hicks."),
        WeekInfo(week: 34, fruit: "Cantaloupe", symbol: "circle.fill", lengthCm: 45.0, weightG: 2150,
                 summary: "Central nervous system and lungs keep maturing.",
                 tip: "Finalize your birth plan and contacts."),
        WeekInfo(week: 35, fruit: "Honeydew", symbol: "circle.fill", lengthCm: 46.2, weightG: 2380,
                 summary: "Baby is filling out and running out of room.",
                 tip: "Pack your hospital bag this week."),
        WeekInfo(week: 36, fruit: "Romaine lettuce", symbol: "circle.fill", lengthCm: 47.4, weightG: 2620,
                 summary: "Baby is considered nearly full term soon.",
                 tip: "Install and check the car seat."),
        WeekInfo(week: 37, fruit: "Swiss chard", symbol: "circle.fill", lengthCm: 48.6, weightG: 2860,
                 summary: "Early term — baby practices breathing motions.",
                 tip: "Know the signs of labor and when to call."),
        WeekInfo(week: 38, fruit: "Leek", symbol: "circle.fill", lengthCm: 49.8, weightG: 3080,
                 summary: "Organs are ready; baby is mostly just growing now.",
                 tip: "Rest up and watch for labor signs."),
        WeekInfo(week: 39, fruit: "Watermelon (small)", symbol: "circle.fill", lengthCm: 50.7, weightG: 3290,
                 summary: "Full term — baby could arrive any day.",
                 tip: "Keep your phone charged and bag ready."),
        WeekInfo(week: 40, fruit: "Pumpkin", symbol: "circle.fill", lengthCm: 51.2, weightG: 3460,
                 summary: "Your due date is here — most babies arrive close to now.",
                 tip: "Stay in touch with your care team about next steps."),
    ]
}
