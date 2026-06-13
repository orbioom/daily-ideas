import Foundation

/// A self-contained list of common five-letter words used both as daily
/// answers and as the set of accepted guesses. No network, no bundled file.
enum WordList {
    static let words: [String] = [
        "about", "above", "abuse", "actor", "acute", "admit", "adopt", "adult", "after", "again",
        "agent", "agree", "ahead", "alarm", "album", "alert", "alike", "alive", "allow", "alone",
        "along", "alter", "among", "anger", "angle", "angry", "apart", "apple", "apply", "arena",
        "argue", "arise", "array", "aside", "asset", "audio", "audit", "avoid", "award", "aware",
        "badly", "baker", "bases", "basic", "basis", "beach", "began", "begin", "begun", "being",
        "below", "bench", "billy", "birth", "black", "blame", "blank", "blast", "blind", "block",
        "blood", "board", "boost", "booth", "bound", "brain", "brand", "brass", "brave", "bread",
        "break", "breed", "brief", "bring", "broad", "broke", "brown", "brush", "build", "built",
        "buyer", "cable", "carry", "catch", "cause", "chain", "chair", "chaos", "charm", "chart",
        "chase", "cheap", "check", "chest", "chief", "child", "chill", "china", "chose", "civil",
        "claim", "class", "clean", "clear", "click", "climb", "clock", "close", "cloth", "cloud",
        "coach", "coast", "could", "count", "court", "cover", "craft", "crash", "crazy", "cream",
        "crime", "cross", "crowd", "crown", "crude", "curve", "cycle", "daily", "dance", "dated",
        "dealt", "death", "debut", "delay", "depth", "doing", "doubt", "dozen", "draft", "drama",
        "drank", "drawn", "dream", "dress", "dried", "drill", "drink", "drive", "drove", "dying",
        "eager", "early", "earth", "eight", "elite", "empty", "enemy", "enjoy", "enter", "entry",
        "equal", "error", "event", "every", "exact", "exist", "extra", "faith", "false", "fault",
        "fiber", "field", "fifth", "fifty", "fight", "final", "first", "fixed", "flame", "flash",
        "fleet", "floor", "fluid", "focus", "force", "forge", "forth", "forty", "forum", "found",
        "frame", "frank", "fraud", "fresh", "front", "frost", "fruit", "fully", "funny", "ghost",
        "giant", "given", "glass", "globe", "glory", "grace", "grade", "grain", "grand", "grant",
        "grass", "grave", "great", "green", "greet", "grief", "gross", "group", "grown", "guard",
        "guess", "guest", "guide", "happy", "harsh", "heart", "heavy", "hedge", "hence", "horse",
        "hotel", "house", "human", "ideal", "image", "index", "inner", "input", "irony", "issue",
        "joint", "judge", "juice", "known", "label", "labor", "large", "laser", "later", "laugh",
        "layer", "learn", "lease", "least", "leave", "legal", "lemon", "level", "lewis", "light",
        "limit", "links", "liver", "lobby", "local", "logic", "loose", "lower", "lucky", "lunch",
        "lying", "magic", "major", "maker", "march", "match", "mayor", "meant", "medal", "media",
        "metal", "meter", "might", "minor", "minus", "mixed", "model", "money", "month", "moral",
        "motor", "mount", "mouse", "mouth", "movie", "music", "needs", "nerve", "never", "newly",
        "night", "noble", "noise", "north", "noted", "novel", "nurse", "occur", "ocean", "offer",
        "often", "order", "other", "ought", "paint", "panel", "paper", "party", "peace", "peter",
        "phase", "phone", "photo", "piano", "piece", "pilot", "pitch", "place", "plain", "plane",
        "plant", "plate", "point", "pound", "power", "press", "price", "pride", "prime", "print",
        "prior", "prize", "proof", "proud", "prove", "queen", "quick", "quiet", "quite", "radio",
        "raise", "range", "rapid", "ratio", "reach", "ready", "realm", "rebel", "refer", "relax",
        "repay", "reply", "right", "rigid", "risky", "rival", "river", "roman", "rough", "round",
        "route", "royal", "rural", "scale", "scare", "scene", "scope", "score", "sense", "serve",
        "seven", "shade", "shall", "shape", "share", "sharp", "sheet", "shelf", "shell", "shift",
        "shine", "shirt", "shock", "shoot", "shore", "short", "shown", "sight", "silly", "since",
        "sixth", "sixty", "sized", "skill", "sleep", "slice", "slide", "small", "smart", "smile",
        "smoke", "snake", "solid", "solve", "sorry", "sound", "south", "space", "spare", "speak",
        "speed", "spell", "spend", "spent", "spice", "spike", "split", "spoke", "sport", "staff",
        "stage", "stair", "stake", "stand", "stark", "start", "state", "steam", "steel", "steep",
        "steer", "stern", "stick", "still", "stock", "stone", "stood", "store", "storm", "story",
        "strip", "stuck", "study", "stuff", "style", "sugar", "suite", "super", "sweet", "swept",
        "swift", "swing", "sword", "table", "taken", "taste", "taxes", "teach", "teeth", "terms",
        "theft", "their", "theme", "there", "these", "thick", "thing", "think", "third", "those",
        "three", "threw", "throw", "thumb", "tiger", "tight", "timer", "tired", "title", "today",
        "token", "tooth", "topic", "total", "touch", "tough", "tower", "trace", "track", "trade",
        "trail", "train", "trait", "trash", "treat", "trend", "trial", "tribe", "trick", "tried",
        "truck", "truly", "trunk", "trust", "truth", "twice", "twist", "tyler", "ultra", "uncle",
        "under", "union", "unity", "until", "upper", "upset", "urban", "usage", "usual", "valid",
        "value", "video", "virus", "visit", "vital", "vocal", "voice", "voter", "wagon", "waste",
        "watch", "water", "wedge", "weigh", "wheel", "where", "which", "while", "white", "whole",
        "whose", "woman", "world", "worry", "worse", "worst", "worth", "would", "wound", "write",
        "wrong", "wrote", "yield", "young", "youth",
    ]

    static let valid: Set<String> = Set(words)

    static func isValid(_ word: String) -> Bool {
        valid.contains(word.lowercased())
    }
}
