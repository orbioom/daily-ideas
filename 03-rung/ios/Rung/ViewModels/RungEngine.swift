import Foundation
import Observation

// MARK: - Word Dictionary

let rungWordList: Set<String> = [
    "able","acid","aged","also","area","army","away","baby","back","ball",
    "band","bank","base","bath","bear","beat","been","belt","best","bird",
    "bite","blow","blue","boat","body","bold","bolt","bone","book","bore",
    "both","bull","burn","busy","cage","cake","call","calm","came","camp",
    "card","care","cart","case","cash","cast","cave","cell","chat","chin",
    "chip","chop","city","clad","clam","clap","claw","clay","clue","coal",
    "coat","code","coil","cold","come","cook","cool","cope","copy","cord",
    "core","cork","corn","cost","cozy","crab","crop","crow","cube","cure",
    "curl","cute","damp","dark","dart","dash","data","date","dead","deal",
    "dean","dear","debt","deed","deep","deny","desk","dial","dice","diet",
    "dirt","dish","disk","dock","does","done","door","dose","down","drag",
    "draw","drew","drip","drop","drug","drum","dual","duel","duke","dull",
    "dump","dusk","dust","duty","each","earl","earn","ease","east","edge",
    "else","emit","epic","even","ever","evil","exam","exit","face","fact",
    "fail","fair","fall","fame","fang","fare","farm","fast","fate","fear",
    "feat","feed","feel","feet","fell","felt","fern","file","fill","film",
    "find","fine","fire","firm","fish","fist","flag","flat","flaw","flea",
    "fled","flew","flip","flit","flow","foam","fold","folk","fond","font",
    "food","fool","foot","ford","fore","fork","form","fort","foul","four",
    "free","from","fuel","full","fund","furl","fury","fuse","gain","gale",
    "game","gang","gate","gave","gaze","gear","germ","gift","girl","give",
    "glad","glee","glow","glue","goal","goat","gold","gone","good","gown",
    "grab","gray","grew","grid","grin","grip","grit","grow","gulf","gust",
    "hack","hail","half","hall","halt","hand","hang","hard","hare","harm",
    "harp","hash","hast","hate","have","hawk","heal","heap","heat","heel",
    "held","helm","help","herb","herd","here","hero","hide","high","hill",
    "hint","hire","hold","hole","holy","home","hood","hook","hope","horn",
    "host","hour","huge","hull","hung","hunt","hurt","hymn","icon","idea",
    "idle","inch","into","iron","isle","item","jail","jolt","jump","just",
    "keen","keep","kind","king","knew","knit","knob","know","lace","lack",
    "laid","lake","lamb","lamp","land","lane","lark","last","late","lava",
    "lawn","lead","leaf","leak","lean","leap","left","legs","lend","lens",
    "lest","lick","life","lift","like","limb","lime","line","link","lion",
    "list","live","load","lock","loft","lone","long","look","loom","lore",
    "lose","loss","lost","loud","love","luck","lull","lump","lung","lurk",
    "mace","made","mail","main","make","male","mall","mane","many","mark",
    "mars","mart","mast","mate","maze","meal","mean","meat","meet","melt",
    "memo","mere","mesh","mild","milk","mill","mind","mine","mint","miss",
    "mist","mode","mole","molt","moon","moor","more","most","move","much",
    "muck","mule","must","nail","name","nape","near","neat","need","nest",
    "news","next","nice","nine","node","none","noon","norm","nose","note",
    "noun","null","oath","obey","odds","once","only","open","oral","oven",
    "over","pace","pack","page","paid","pain","pair","pale","palm","park",
    "part","pass","past","path","pave","pawn","peak","peel","peer","pest",
    "pick","pile","pine","pink","pipe","pity","plan","play","plot","plow",
    "plum","poem","poet","pole","poll","pool","pore","port","pose","post",
    "pour","pray","prey","prod","pull","pump","pure","push","quit","race",
    "rack","rage","raid","rail","rain","rake","ramp","rank","rant","rape",
    "rare","rash","rate","rave","read","real","reap","reed","reel","rein",
    "rely","rent","rest","rice","rich","ride","rife","ring","riot","ripe",
    "rise","risk","road","roam","roar","robe","rock","role","roll","roof",
    "rook","room","root","rope","rose","ruin","rule","rush","rust","safe",
    "sage","sail","sake","salt","same","sand","sane","sang","sank","sash",
    "save","seal","seam","seed","seek","seem","seen","seep","self","sell",
    "send","shed","ship","shoe","shop","shot","show","shut","side","sift",
    "silk","sill","silo","sing","sink","site","size","skin","skip","slab",
    "slam","slap","slim","slip","slow","slum","snap","snow","soak","soar",
    "sock","soft","soil","sole","some","song","soon","sore","sort","soul",
    "sour","span","spar","spin","spit","spot","spur","star","stay","stem",
    "step","stir","stop","stub","stun","such","suit","sulk","sung","sunk",
    "sway","swim","tail","take","tale","talk","tall","tame","tang","task",
    "taut","teak","teal","team","tear","tell","tend","tent","term","test",
    "text","than","that","them","then","they","thin","this","tide","tilt",
    "time","tire","toll","tomb","tone","tool","tops","tore","torn","toss",
    "tour","town","trap","tree","trim","trio","trip","true","tube","tuck",
    "tune","turf","turn","tusk","twig","twin","type","ugly","undo","unit",
    "upon","used","vale","vane","vast","veil","vein","very","vest","veto",
    "view","vile","vine","volt","vote","wade","wage","wake","walk","wall",
    "wand","want","ward","warm","warp","wart","wary","wash","wave","weak",
    "weal","wean","weed","week","well","welt","went","were","west","when",
    "whim","whip","wide","wild","will","wilt","wind","wine","wing","wink",
    "wire","wise","wish","with","woke","wolf","wood","wool","word","wore",
    "work","worm","worn","writ","yard","yarn","year","yell","your","zone"
]

// MARK: - Daily Puzzles

let rungDailyPuzzles: [(String, String, Int)] = [
    // (start, target, par)
    ("cold","warm",4), ("hate","love",4), ("card","game",4),
    ("dark","lite",4), ("fast","slow",4), ("hard","easy",5),
    ("word","play",4), ("fire","cool",4), ("head","tail",4),
    ("bold","mild",4), ("hand","foot",5), ("back","face",4),
    ("lead","gold",4), ("land","sand",3), ("bird","cage",4),
    ("lake","boat",4), ("ring","bell",4), ("door","lock",4),
    ("book","worm",4), ("blue","gray",4), ("coat","boot",4),
    ("mile","road",4), ("fork","road",4), ("palm","tree",4),
    ("leaf","fall",4), ("rose","thorn",5), ("note","book",4),
    ("road","trip",4), ("hunt","prey",4), ("trap","door",4),
]

// MARK: - Engine

@Observable
@MainActor
final class RungEngine {
    var startWord: String = ""
    var targetWord: String = ""
    var currentWord: String = ""
    var chain: [String] = []
    var parSteps: Int = 0
    var errorMessage: String = ""
    var isSolved: Bool = false
    var elapsedSeconds: Int = 0
    var hintsUsed: Int = 0
    var hint: String = ""
    var isComputing: Bool = false

    private var timerTask: Task<Void, Never>?
    private var startTime: Date = Date()

    func startDaily() {
        let idx = dayIndex() % rungDailyPuzzles.count
        let puzzle = rungDailyPuzzles[idx]
        begin(start: puzzle.0, target: puzzle.1, par: puzzle.2)
    }

    func startRandom() {
        let common = Array(rungWordList).filter { rungWordList.contains($0) }
        guard common.count > 10 else { return }
        var s = common.randomElement()!
        var t = common.randomElement()!
        var tries = 0
        while (s == t || !isReachable(from: s, to: t)) && tries < 30 {
            s = common.randomElement()!
            t = common.randomElement()!
            tries += 1
        }
        let dist = bfsDistance(from: s, to: t) ?? 4
        begin(start: s, target: t, par: dist)
    }

    private func begin(start: String, target: String, par: Int) {
        startWord = start
        targetWord = target
        currentWord = start
        parSteps = par
        chain = [start]
        isSolved = false
        errorMessage = ""
        hint = ""
        hintsUsed = 0
        elapsedSeconds = 0
        startTime = Date()
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !isSolved else { break }
                elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            }
        }
    }

    func submit(word: String) {
        let w = word.lowercased().trimmingCharacters(in: .whitespaces)
        guard w.count == 4 else { errorMessage = "Words must be 4 letters."; return }
        guard rungWordList.contains(w) else { errorMessage = "\"\(w)\" is not in the word list."; return }
        guard isOneLetterAway(currentWord, w) else { errorMessage = "Must change exactly one letter."; return }
        guard !chain.contains(w) else { errorMessage = "You already used \"\(w)\"."; return }

        errorMessage = ""
        hint = ""
        chain.append(w)
        currentWord = w

        if w == targetWord {
            isSolved = true
            timerTask?.cancel()
        }
    }

    func undo() {
        guard chain.count > 1 else { return }
        chain.removeLast()
        currentWord = chain.last!
        errorMessage = ""
        hint = ""
        isSolved = false
    }

    func requestHint(maxHints: Int) {
        guard hintsUsed < maxHints, !isSolved else { return }
        isComputing = true
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let cur = await self.currentWord
            let tgt = await self.targetWord
            let next = Self.bfsNextStep(from: cur, to: tgt)
            await MainActor.run {
                self.isComputing = false
                if let n = next {
                    self.hint = "Try a word starting with '\(n.first!)'"
                    self.hintsUsed += 1
                } else {
                    self.hint = "No path found from here!"
                }
            }
        }
    }

    private func dayIndex() -> Int {
        let ref = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 0))
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.dateComponents([.day], from: ref, to: today).day ?? 0
    }

    private func isOneLetterAway(_ a: String, _ b: String) -> Bool {
        guard a.count == b.count else { return false }
        return zip(a, b).filter { $0 != $1 }.count == 1
    }

    private func neighbors(of word: String) -> [String] {
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        var chars = Array(word)
        var result: [String] = []
        for i in chars.indices {
            let orig = chars[i]
            for l in letters where l != orig {
                chars[i] = l
                let candidate = String(chars)
                if rungWordList.contains(candidate) { result.append(candidate) }
            }
            chars[i] = orig
        }
        return result
    }

    private func bfsDistance(from start: String, to target: String) -> Int? {
        var visited: Set<String> = [start]
        var queue: [(String, Int)] = [(start, 0)]
        while !queue.isEmpty {
            let (word, dist) = queue.removeFirst()
            if word == target { return dist }
            for n in neighbors(of: word) where !visited.contains(n) {
                visited.insert(n)
                queue.append((n, dist + 1))
            }
        }
        return nil
    }

    private func isReachable(from: String, to: String) -> Bool {
        bfsDistance(from: from, to: to) != nil
    }

    static func bfsNextStep(from start: String, to target: String) -> String? {
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        func neighbors(_ word: String) -> [String] {
            var chars = Array(word)
            var result: [String] = []
            for i in chars.indices {
                let orig = chars[i]
                for l in letters where l != orig {
                    chars[i] = l
                    let c = String(chars)
                    if rungWordList.contains(c) { result.append(c) }
                }
                chars[i] = orig
            }
            return result
        }
        var prev: [String: String] = [:]
        var visited: Set<String> = [start]
        var queue: [String] = [start]
        while !queue.isEmpty {
            let word = queue.removeFirst()
            if word == target {
                var cur = target
                while let p = prev[cur], p != start { cur = p }
                return prev[cur] != nil ? cur : nil
            }
            for n in neighbors(word) where !visited.contains(n) {
                visited.insert(n)
                prev[n] = word
                queue.append(n)
            }
        }
        return nil
    }
}
