import Foundation
import SwiftData

struct CryptoPuzzle {
    let id: Int
    let quote: String
    let author: String
    let theme: String
}

struct CipherEngine {
    // Seeded LCG for deterministic cipher per puzzle ID
    static func makeCipher(seed: Int) -> [Character: Character] {
        var state: UInt64 = UInt64(bitPattern: Int64(seed &* 6364136223846793005 &+ 1442695040888963407))
        let letters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var shuffled = letters
        for i in stride(from: shuffled.count - 1, through: 1, by: -1) {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let j = Int(state >> 33) % (i + 1)
            shuffled.swapAt(i, j)
        }
        var map: [Character: Character] = [:]
        for (a, b) in zip(letters, shuffled) {
            map[a] = b
        }
        return map
    }

    static func encode(text: String, cipher: [Character: Character]) -> String {
        String(text.uppercased().map { ch in
            cipher[ch] ?? ch
        })
    }

    static func decode(encoded: String, mapping: [Character: Character]) -> String {
        let reverse = Dictionary(uniqueKeysWithValues: mapping.map { ($0.value, $0.key) })
        return String(encoded.map { ch in
            if ch.isLetter { return reverse[ch] ?? ch }
            return ch
        })
    }

    static func checkSolution(encoded: String, userMapping: [Character: Character], cipher: [Character: Character]) -> Bool {
        let reverse = Dictionary(uniqueKeysWithValues: cipher.map { ($0.value, $0.key) })
        for (cipherChar, userChar) in userMapping {
            if let correct = reverse[cipherChar], correct != userChar { return false }
        }
        let needed = Set(encoded.filter(\.isLetter))
        for ch in needed {
            if userMapping[ch] == nil { return false }
        }
        return true
    }
}

@Model
final class PuzzleProgress {
    var puzzleId: Int
    var letterMappingData: Data
    var isSolved: Bool
    var solvedDate: Date?
    var hintsUsed: Int
    var elapsedSeconds: Int
    var lastPlayedDate: Date

    init(puzzleId: Int) {
        self.puzzleId = puzzleId
        self.letterMappingData = Data()
        self.isSolved = false
        self.solvedDate = nil
        self.hintsUsed = 0
        self.elapsedSeconds = 0
        self.lastPlayedDate = Date()
    }

    var letterMapping: [Character: Character] {
        get {
            guard let dict = try? JSONDecoder().decode([String: String].self, from: letterMappingData) else { return [:] }
            return Dictionary(uniqueKeysWithValues: dict.compactMap { k, v -> (Character, Character)? in
                guard let kc = k.first, let vc = v.first else { return nil }
                return (kc, vc)
            })
        }
        set {
            let dict = Dictionary(uniqueKeysWithValues: newValue.map { (String($0.key), String($0.value)) })
            letterMappingData = (try? JSONEncoder().encode(dict)) ?? Data()
        }
    }
}

extension CryptoPuzzle {
    static let catalog: [CryptoPuzzle] = [
        CryptoPuzzle(id: 0,  quote: "THE ONLY WAY TO DO GREAT WORK IS TO LOVE WHAT YOU DO", author: "Steve Jobs", theme: "Inspiration"),
        CryptoPuzzle(id: 1,  quote: "IN THE MIDDLE OF DIFFICULTY LIES OPPORTUNITY", author: "Albert Einstein", theme: "Perseverance"),
        CryptoPuzzle(id: 2,  quote: "IT ALWAYS SEEMS IMPOSSIBLE UNTIL IT IS DONE", author: "Nelson Mandela", theme: "Achievement"),
        CryptoPuzzle(id: 3,  quote: "LIFE IS WHAT HAPPENS WHEN YOU ARE BUSY MAKING OTHER PLANS", author: "John Lennon", theme: "Life"),
        CryptoPuzzle(id: 4,  quote: "THE FUTURE BELONGS TO THOSE WHO BELIEVE IN THE BEAUTY OF THEIR DREAMS", author: "Eleanor Roosevelt", theme: "Dreams"),
        CryptoPuzzle(id: 5,  quote: "SPREAD LOVE EVERYWHERE YOU GO LET NO ONE EVER COME TO YOU WITHOUT LEAVING HAPPIER", author: "Mother Teresa", theme: "Kindness"),
        CryptoPuzzle(id: 6,  quote: "WHEN YOU REACH THE END OF YOUR ROPE TIE A KNOT IN IT AND HANG ON", author: "Franklin D. Roosevelt", theme: "Resilience"),
        CryptoPuzzle(id: 7,  quote: "ALWAYS REMEMBER THAT YOU ARE ABSOLUTELY UNIQUE JUST LIKE EVERYONE ELSE", author: "Margaret Mead", theme: "Humor"),
        CryptoPuzzle(id: 8,  quote: "DO NOT GO WHERE THE PATH MAY LEAD GO INSTEAD WHERE THERE IS NO PATH AND LEAVE A TRAIL", author: "Ralph Waldo Emerson", theme: "Leadership"),
        CryptoPuzzle(id: 9,  quote: "YOU WILL FACE MANY DEFEATS IN LIFE BUT NEVER LET YOURSELF BE DEFEATED", author: "Maya Angelou", theme: "Courage"),
        CryptoPuzzle(id: 10, quote: "THE GREATEST GLORY IN LIVING LIES NOT IN NEVER FALLING BUT IN RISING EVERY TIME WE FALL", author: "Nelson Mandela", theme: "Resilience"),
        CryptoPuzzle(id: 11, quote: "IN THE END IT IS NOT THE YEARS IN YOUR LIFE THAT COUNT IT IS THE LIFE IN YOUR YEARS", author: "Abraham Lincoln", theme: "Life"),
        CryptoPuzzle(id: 12, quote: "NEVER LET THE FEAR OF STRIKING OUT KEEP YOU FROM PLAYING THE GAME", author: "Babe Ruth", theme: "Courage"),
        CryptoPuzzle(id: 13, quote: "LIFE IS EITHER A DARING ADVENTURE OR NOTHING AT ALL", author: "Helen Keller", theme: "Adventure"),
        CryptoPuzzle(id: 14, quote: "MANY OF LIFE FAILURES ARE PEOPLE WHO DID NOT REALIZE HOW CLOSE THEY WERE TO SUCCESS WHEN THEY GAVE UP", author: "Thomas Edison", theme: "Perseverance"),
        CryptoPuzzle(id: 15, quote: "YOU HAVE BRAINS IN YOUR HEAD YOU HAVE FEET IN YOUR SHOES YOU CAN STEER YOURSELF ANY DIRECTION YOU CHOOSE", author: "Dr. Seuss", theme: "Self-reliance"),
        CryptoPuzzle(id: 16, quote: "IF LIFE WERE PREDICTABLE IT WOULD CEASE TO BE LIFE AND BE WITHOUT FLAVOR", author: "Eleanor Roosevelt", theme: "Life"),
        CryptoPuzzle(id: 17, quote: "IF YOU LOOK AT WHAT YOU HAVE IN LIFE YOU WILL ALWAYS HAVE MORE", author: "Oprah Winfrey", theme: "Gratitude"),
        CryptoPuzzle(id: 18, quote: "IF YOU SET YOUR GOALS RIDICULOUSLY HIGH AND IT IS A FAILURE YOU WILL FAIL ABOVE EVERYONE ELSE SUCCESS", author: "James Cameron", theme: "Ambition"),
        CryptoPuzzle(id: 19, quote: "LIFE IS NOT MEASURED BY THE NUMBER OF BREATHS WE TAKE BUT BY THE MOMENTS THAT TAKE OUR BREATH AWAY", author: "Maya Angelou", theme: "Moments"),
        CryptoPuzzle(id: 20, quote: "IF YOU WANT TO LIVE A HAPPY LIFE TIE IT TO A GOAL NOT TO PEOPLE OR OBJECTS", author: "Albert Einstein", theme: "Happiness"),
        CryptoPuzzle(id: 21, quote: "NEVER LET THE FEAR OF STRIKING OUT STOP YOU FROM PLAYING THE GAME", author: "Cinderella", theme: "Courage"),
        CryptoPuzzle(id: 22, quote: "MONEY AND SUCCESS DON'T CHANGE PEOPLE THEY MERELY AMPLIFY WHAT IS ALREADY THERE", author: "Will Smith", theme: "Character"),
        CryptoPuzzle(id: 23, quote: "YOUR TIME IS LIMITED SO DON'T WASTE IT LIVING SOMEONE ELSE'S LIFE", author: "Steve Jobs", theme: "Authenticity"),
        CryptoPuzzle(id: 24, quote: "NOT HOW LONG BUT HOW WELL YOU HAVE LIVED IS THE MAIN THING", author: "Seneca", theme: "Wisdom"),
        CryptoPuzzle(id: 25, quote: "THE SECRET OF GETTING AHEAD IS GETTING STARTED", author: "Mark Twain", theme: "Action"),
        CryptoPuzzle(id: 26, quote: "IT DOES NOT MATTER HOW SLOWLY YOU GO AS LONG AS YOU DO NOT STOP", author: "Confucius", theme: "Persistence"),
        CryptoPuzzle(id: 27, quote: "OUR GREATEST WEAKNESS LIES IN GIVING UP THE MOST CERTAIN WAY TO SUCCEED IS ALWAYS TO TRY JUST ONE MORE TIME", author: "Thomas Edison", theme: "Determination"),
        CryptoPuzzle(id: 28, quote: "YOU DON'T HAVE TO BE GREAT TO START BUT YOU HAVE TO START TO BE GREAT", author: "Zig Ziglar", theme: "Beginning"),
        CryptoPuzzle(id: 29, quote: "THE MIND IS EVERYTHING WHAT YOU THINK YOU BECOME", author: "Buddha", theme: "Mindset"),
        CryptoPuzzle(id: 30, quote: "AN UNEXAMINED LIFE IS NOT WORTH LIVING", author: "Socrates", theme: "Philosophy"),
        CryptoPuzzle(id: 31, quote: "SPREAD LOVE EVERYWHERE YOU GO FIRST OF ALL IN YOUR OWN HOUSE", author: "Mother Teresa", theme: "Love"),
        CryptoPuzzle(id: 32, quote: "WHEN I LET GO OF WHAT I AM I BECOME WHAT I MIGHT BE", author: "Lao Tzu", theme: "Growth"),
        CryptoPuzzle(id: 33, quote: "HAPPINESS IS NOT SOMETHING READY MADE IT COMES FROM YOUR OWN ACTIONS", author: "Dalai Lama", theme: "Happiness"),
        CryptoPuzzle(id: 34, quote: "IF YOU WANT TO MAKE YOUR DREAMS COME TRUE THE FIRST THING YOU HAVE TO DO IS WAKE UP", author: "J.M. Power", theme: "Dreams"),
        CryptoPuzzle(id: 35, quote: "THE BEST TIME TO PLANT A TREE WAS TWENTY YEARS AGO THE SECOND BEST TIME IS NOW", author: "Chinese Proverb", theme: "Action"),
        CryptoPuzzle(id: 36, quote: "AN OUNCE OF PREVENTION IS WORTH A POUND OF CURE", author: "Benjamin Franklin", theme: "Wisdom"),
        CryptoPuzzle(id: 37, quote: "I HAVE NOT FAILED I HAVE JUST FOUND TEN THOUSAND WAYS THAT WON'T WORK", author: "Thomas Edison", theme: "Perseverance"),
        CryptoPuzzle(id: 38, quote: "THE ONLY IMPOSSIBLE JOURNEY IS THE ONE YOU NEVER BEGIN", author: "Tony Robbins", theme: "Beginning"),
        CryptoPuzzle(id: 39, quote: "IN THREE WORDS I CAN SUM UP EVERYTHING I HAVE LEARNED ABOUT LIFE IT GOES ON", author: "Robert Frost", theme: "Life")
    ]

    static func todayPuzzle() -> CryptoPuzzle {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return catalog[day % catalog.count]
    }

    static func puzzle(for date: Date) -> CryptoPuzzle {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return catalog[day % catalog.count]
    }
}
