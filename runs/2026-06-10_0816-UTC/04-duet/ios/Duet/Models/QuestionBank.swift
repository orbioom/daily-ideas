import Foundation

enum QuestionCategory: String, CaseIterable, Identifiable {
    case fun = "Fun"
    case deep = "Deep"
    case memoryLane = "Memory lane"
    case future = "Future"
    case gratitude = "Gratitude"
    case spark = "Spark"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .fun: return "face.smiling"
        case .deep: return "water.waves"
        case .memoryLane: return "photo.on.rectangle.angled"
        case .future: return "binoculars"
        case .gratitude: return "heart.text.square"
        case .spark: return "flame"
        }
    }
}

struct Question: Identifiable, Hashable {
    let id: Int
    let text: String
    let category: QuestionCategory
}

/// 72 curated daily questions. The day's pick is deterministic, so both of
/// you always see the same card.
enum QuestionBank {

    static func question(id: Int) -> Question? {
        all.first { $0.id == id }
    }

    static let all: [Question] = [
        // Fun
        Question(id: 1, text: "If we had a completely free day tomorrow and unlimited money, what would we do?", category: .fun),
        Question(id: 2, text: "What's a tiny habit of mine you secretly find funny?", category: .fun),
        Question(id: 3, text: "If our relationship were a movie, what genre would it be — and what's the title?", category: .fun),
        Question(id: 4, text: "Which fictional couple are we most like?", category: .fun),
        Question(id: 5, text: "What's the most ridiculous thing we've ever argued about?", category: .fun),
        Question(id: 6, text: "If you could swap one of my chores for anything else, what would you give me?", category: .fun),
        Question(id: 7, text: "What song would play when I walk into a room?", category: .fun),
        Question(id: 8, text: "What would our couple's reality show be called?", category: .fun),
        Question(id: 9, text: "If we opened a tiny shop together, what would we sell?", category: .fun),
        Question(id: 10, text: "What animal does the other person turn into when hungry?", category: .fun),
        Question(id: 11, text: "What's one food opinion of mine you'll never accept?", category: .fun),
        Question(id: 12, text: "If we could teleport anywhere for dinner tonight, where are we eating?", category: .fun),
        // Deep
        Question(id: 13, text: "What's something you've been carrying lately that I might not have noticed?", category: .deep),
        Question(id: 14, text: "When do you feel most understood by me?", category: .deep),
        Question(id: 15, text: "What's a fear you've never said out loud to me?", category: .deep),
        Question(id: 16, text: "What does 'home' mean to you right now?", category: .deep),
        Question(id: 17, text: "What part of yourself are you still learning to accept?", category: .deep),
        Question(id: 18, text: "When did you last feel truly proud of yourself — and did you tell anyone?", category: .deep),
        Question(id: 19, text: "What do you need more of from me when you're stressed?", category: .deep),
        Question(id: 20, text: "What belief of yours has changed the most since we met?", category: .deep),
        Question(id: 21, text: "What's something hard from your past that made you better at loving?", category: .deep),
        Question(id: 22, text: "If you could be certain about one thing in life, what would you choose?", category: .deep),
        Question(id: 23, text: "What does being loved well look like, in really practical terms?", category: .deep),
        Question(id: 24, text: "What's one thing you wish I asked you about more often?", category: .deep),
        // Memory lane
        Question(id: 25, text: "What was the exact moment you knew this was something real?", category: .memoryLane),
        Question(id: 26, text: "What detail from our first date do you remember that I might have forgotten?", category: .memoryLane),
        Question(id: 27, text: "What's the hardest we've ever laughed together?", category: .memoryLane),
        Question(id: 28, text: "Which trip or outing together would you relive exactly as it was?", category: .memoryLane),
        Question(id: 29, text: "What's a small everyday moment with me you hope you never forget?", category: .memoryLane),
        Question(id: 30, text: "What first impression of me turned out to be completely wrong?", category: .memoryLane),
        Question(id: 31, text: "Which photo of us means the most to you, and why?", category: .memoryLane),
        Question(id: 32, text: "What's the kindest thing I've done that I probably don't remember?", category: .memoryLane),
        Question(id: 33, text: "What was our hardest season together, and what got us through it?", category: .memoryLane),
        Question(id: 34, text: "What's a meal we shared that you still think about?", category: .memoryLane),
        Question(id: 35, text: "What did your friends or family say about me at the start?", category: .memoryLane),
        Question(id: 36, text: "Which version of us — from any year — would you like to have dinner with?", category: .memoryLane),
        // Future
        Question(id: 37, text: "What's one place we absolutely have to see together in this lifetime?", category: .future),
        Question(id: 38, text: "What do you hope our weekends look like in ten years?", category: .future),
        Question(id: 39, text: "What's a skill you'd love us to learn together?", category: .future),
        Question(id: 40, text: "If we designed our dream kitchen, what's the one non-negotiable feature?", category: .future),
        Question(id: 41, text: "What tradition should we start this year?", category: .future),
        Question(id: 42, text: "What's something scary-but-exciting you want us to try?", category: .future),
        Question(id: 43, text: "How do you want us to handle hard seasons when they come?", category: .future),
        Question(id: 44, text: "What would a perfect ordinary Tuesday look like for us in five years?", category: .future),
        Question(id: 45, text: "What's one thing you want to be true about us when we're old?", category: .future),
        Question(id: 46, text: "If we took a month off together next year, how would we spend it?", category: .future),
        Question(id: 47, text: "What's a goal of yours I can actively help with this month?", category: .future),
        Question(id: 48, text: "What kind of hosts do you want us to be — what's our signature?", category: .future),
        // Gratitude
        Question(id: 49, text: "What's something I did this week that made your life easier?", category: .gratitude),
        Question(id: 50, text: "What quality of mine do you hope never changes?", category: .gratitude),
        Question(id: 51, text: "When did I last make you feel really seen?", category: .gratitude),
        Question(id: 52, text: "What's a way you've grown that you partly credit to us?", category: .gratitude),
        Question(id: 53, text: "What's the most useful thing you've learned from me?", category: .gratitude),
        Question(id: 54, text: "Which of my quirks have you come to genuinely love?", category: .gratitude),
        Question(id: 55, text: "What's one thing about our everyday life most people would envy?", category: .gratitude),
        Question(id: 56, text: "Who in our life are you grateful for, and should we tell them?", category: .gratitude),
        Question(id: 57, text: "What did I say once that you still think about?", category: .gratitude),
        Question(id: 58, text: "What's a sacrifice I made that you noticed, even if I downplayed it?", category: .gratitude),
        Question(id: 59, text: "What part of your day is better because I'm in it?", category: .gratitude),
        Question(id: 60, text: "What's something my family or upbringing gave me that you benefit from?", category: .gratitude),
        // Spark
        Question(id: 61, text: "What was I wearing the last time you caught yourself staring?", category: .spark),
        Question(id: 62, text: "What's a date from our past you'd like a sequel to?", category: .spark),
        Question(id: 63, text: "When do you find me most attractive — be specific?", category: .spark),
        Question(id: 64, text: "What's a compliment you've thought about me but never said out loud?", category: .spark),
        Question(id: 65, text: "Describe our ideal slow morning together.", category: .spark),
        Question(id: 66, text: "What little thing do I do that still gives you butterflies?", category: .spark),
        Question(id: 67, text: "If tonight were a first date, where would you take me to impress me?", category: .spark),
        Question(id: 68, text: "What's something new you'd love us to do together, just the two of us?", category: .spark),
        Question(id: 69, text: "Which of my features did you notice first?", category: .spark),
        Question(id: 70, text: "What's our best kiss so far — and what made it the best?", category: .spark),
        Question(id: 71, text: "How can I make you feel more adored this week?", category: .spark),
        Question(id: 72, text: "What's a tiny gesture from me that feels surprisingly romantic?", category: .spark)
    ]
}
