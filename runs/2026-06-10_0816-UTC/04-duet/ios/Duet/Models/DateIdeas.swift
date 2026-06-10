import Foundation

enum IdeaCost: Int, CaseIterable, Identifiable {
    case free = 0, low = 1, treat = 2
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .free: return "Free"
        case .low: return "$"
        case .treat: return "$$"
        }
    }
}

enum IdeaSetting: String, CaseIterable, Identifiable {
    case home = "At home"
    case outside = "Outside"
    case out = "Out on the town"
    var id: String { rawValue }
}

enum IdeaEnergy: String, CaseIterable, Identifiable {
    case chill = "Chill"
    case active = "Active"
    var id: String { rawValue }
}

struct DateIdea: Identifiable, Hashable {
    let id: Int
    let title: String
    let blurb: String
    let cost: IdeaCost
    let setting: IdeaSetting
    let energy: IdeaEnergy
}

/// 36 built-in date ideas, filterable by cost, setting, and energy.
enum DateIdeaCatalog {

    static func idea(id: Int) -> DateIdea? { all.first { $0.id == id } }

    static let all: [DateIdea] = [
        DateIdea(id: 1, title: "Question-jar dinner", blurb: "Cook something simple, phones away, and answer three Duet questions over candles.", cost: .low, setting: .home, energy: .chill),
        DateIdea(id: 2, title: "Sunrise coffee mission", blurb: "Alarm, blankets, thermos. Watch the day arrive from the best viewpoint within reach.", cost: .free, setting: .outside, energy: .active),
        DateIdea(id: 3, title: "Cook-off: one pantry, two dishes", blurb: "Split the kitchen, same ingredients, 45 minutes. Loser does dishes for a week.", cost: .free, setting: .home, energy: .active),
        DateIdea(id: 4, title: "Bookshop wager", blurb: "Pick a book for each other under $15. Read the first chapters together after.", cost: .low, setting: .out, energy: .chill),
        DateIdea(id: 5, title: "Neighborhood you've never walked", blurb: "Pick a district neither of you knows. Walk it end to end and rate the best door.", cost: .free, setting: .outside, energy: .active),
        DateIdea(id: 6, title: "Living-room film festival", blurb: "Three short films or one classic neither has seen. Tickets, intermission snacks, reviews after.", cost: .low, setting: .home, energy: .chill),
        DateIdea(id: 7, title: "The $10 market challenge", blurb: "Ten dollars each at a market. Buy the other person the best tiny thing you can find.", cost: .low, setting: .out, energy: .active),
        DateIdea(id: 8, title: "Memory-lane walk", blurb: "Revisit where you met, first kissed, or first lived. Tell the story like strangers who weren't there.", cost: .free, setting: .outside, energy: .chill),
        DateIdea(id: 9, title: "Breakfast for dinner", blurb: "Pancakes at 8pm, pajamas mandatory, weekday be damned.", cost: .low, setting: .home, energy: .chill),
        DateIdea(id: 10, title: "Gallery speed-run", blurb: "One museum or gallery, 45 minutes, then coffee: each must defend one favorite piece.", cost: .treat, setting: .out, energy: .active),
        DateIdea(id: 11, title: "Stargazing properly", blurb: "Drive past the streetlights with blankets and a sky app. Find three constellations.", cost: .free, setting: .outside, energy: .chill),
        DateIdea(id: 12, title: "Build the dream-house board", blurb: "One hour, one shared moodboard: rooms, gardens, absurd features welcome.", cost: .free, setting: .home, energy: .chill),
        DateIdea(id: 13, title: "Two-wheel picnic", blurb: "Bikes or a long walk, basket of snacks, no destination decided until the second turn.", cost: .low, setting: .outside, energy: .active),
        DateIdea(id: 14, title: "Learn one dance", blurb: "One video tutorial, one living room, one song mastered badly but together.", cost: .free, setting: .home, energy: .active),
        DateIdea(id: 15, title: "The taster's menu", blurb: "Three street-food stops, one shared dish at each, scored out of ten.", cost: .treat, setting: .out, energy: .active),
        DateIdea(id: 16, title: "Letters to next year", blurb: "Write each other a letter to open in twelve months. Seal them. No peeking.", cost: .free, setting: .home, energy: .chill),
        DateIdea(id: 17, title: "Board-game gauntlet", blurb: "Best of three games. The champion picks next week's date.", cost: .free, setting: .home, energy: .chill),
        DateIdea(id: 18, title: "Golden-hour photo walk", blurb: "Phones allowed for once: shoot ten photos of each other, pick a favorite, print it.", cost: .low, setting: .outside, energy: .active),
        DateIdea(id: 19, title: "Tiny concert night", blurb: "Find the smallest live act in town tonight. Front row of forty people.", cost: .treat, setting: .out, energy: .chill),
        DateIdea(id: 20, title: "Swap-playlist drive", blurb: "Each builds the other a 40-minute playlist. Drive nowhere in particular and listen to both.", cost: .low, setting: .outside, energy: .chill),
        DateIdea(id: 21, title: "Pasta from absolute scratch", blurb: "Flour, eggs, chaos. The shape doesn't matter; the sauce does.", cost: .low, setting: .home, energy: .active),
        DateIdea(id: 22, title: "Thrift-store alter egos", blurb: "Find each other a full outfit under $20. Wear it to dinner. No vetoes.", cost: .low, setting: .out, energy: .active),
        DateIdea(id: 23, title: "The slow morning", blurb: "No alarms, market pastries, crossword, zero plans before noon.", cost: .low, setting: .home, energy: .chill),
        DateIdea(id: 24, title: "Climb something", blurb: "A hill, a tower, a climbing gym — earn the view, take the summit photo.", cost: .treat, setting: .outside, energy: .active),
        DateIdea(id: 25, title: "Childhood-favorites dinner", blurb: "Each cooks the dish you loved at eight years old. Trade plates, trade stories.", cost: .low, setting: .home, energy: .chill),
        DateIdea(id: 26, title: "First-date reenactment", blurb: "Same place if you can, same order if you dare. Compare notes on who was more nervous.", cost: .treat, setting: .out, energy: .chill),
        DateIdea(id: 27, title: "Rainy-day fort", blurb: "Blankets, fairy lights, snacks inside the fort only. Films optional, naps encouraged.", cost: .free, setting: .home, energy: .chill),
        DateIdea(id: 28, title: "Farmers'-market roulette", blurb: "Buy whatever the stallholder says is best today. Cook it together tonight.", cost: .low, setting: .out, energy: .active),
        DateIdea(id: 29, title: "Sunset swim or sauna", blurb: "Water at golden hour — sea, lake, pool, or sauna. Warm drinks after.", cost: .low, setting: .outside, energy: .active),
        DateIdea(id: 30, title: "The interview", blurb: "Record a 20-minute interview with each other about this exact season of life. Keep it forever.", cost: .free, setting: .home, energy: .chill),
        DateIdea(id: 31, title: "Karaoke, but committed", blurb: "Two duets minimum. Points for choreography, none for skill.", cost: .treat, setting: .out, energy: .active),
        DateIdea(id: 32, title: "Plant a thing together", blurb: "Herbs on the sill or a tree if you have the ground. Name it something stupid.", cost: .low, setting: .outside, energy: .chill),
        DateIdea(id: 33, title: "Dessert crawl", blurb: "Skip dinner. Three dessert spots, one shared order each, crown a winner.", cost: .treat, setting: .out, energy: .active),
        DateIdea(id: 34, title: "Puzzle and podcast", blurb: "A 500-piece puzzle, one great series, tea refills until it's done or you are.", cost: .low, setting: .home, energy: .chill),
        DateIdea(id: 35, title: "Volunteer hour", blurb: "Give a morning to something local, together. Debrief over lunch.", cost: .free, setting: .out, energy: .active),
        DateIdea(id: 36, title: "Map-pin mystery", blurb: "Close your eyes, drop a pin within an hour of home, go see what's there.", cost: .low, setting: .outside, energy: .active)
    ]
}
