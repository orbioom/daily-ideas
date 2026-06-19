import SwiftUI

enum LessonType: String, CaseIterable {
    case noteIdentify = "noteIdentify"
    case playNote = "playNote"
    case scale = "scale"
    case chord = "chord"
    case song = "song"
    case earTrain = "earTrain"

    var displayName: String {
        switch self {
        case .noteIdentify: return "Identify"
        case .playNote:     return "Play"
        case .scale:        return "Scale"
        case .chord:        return "Chord"
        case .song:         return "Song"
        case .earTrain:     return "Ear"
        }
    }

    var color: Color {
        switch self {
        case .noteIdentify: return .blue
        case .playNote:     return KeysTheme.accent
        case .scale:        return .purple
        case .chord:        return .orange
        case .song:         return .pink
        case .earTrain:     return .teal
        }
    }
}

struct LessonContent: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let type: LessonType
    let exerciseNotes: [Int] // MIDI note numbers
    let description: String
    let tips: [String]
}

struct CurriculumModule: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let lessons: [LessonContent]
}

enum Curriculum {
    static let modules: [CurriculumModule] = [
        gettingStarted,
        noteMastery,
        melodies,
        chords,
        earTraining
    ]

    // MARK: - Module 1: Getting Started
    static let gettingStarted = CurriculumModule(
        id: "getting-started",
        title: "Getting Started",
        icon: "hand.point.right.fill",
        color: KeysTheme.accent,
        lessons: [
            LessonContent(
                id: "gs-1",
                title: "Meet Middle C",
                subtitle: "Your first note",
                type: .playNote,
                exerciseNotes: [60],
                description: "Middle C (C4) is the most important note on the piano. It sits right in the middle of the keyboard and is where most beginners start.",
                tips: ["Look for the C key just to the left of the two black keys", "Middle C is MIDI note 60", "Press it gently with your right-hand index finger"]
            ),
            LessonContent(
                id: "gs-2",
                title: "The White Keys C-D-E",
                subtitle: "First three notes",
                type: .playNote,
                exerciseNotes: [60, 62, 64],
                description: "Learn C, D, and E — the first three white keys starting from Middle C.",
                tips: ["C is left of the two black keys", "D is between the two black keys", "E is right of the two black keys"]
            ),
            LessonContent(
                id: "gs-3",
                title: "F-G-A-B",
                subtitle: "The next four notes",
                type: .playNote,
                exerciseNotes: [65, 67, 69, 71],
                description: "Learn F, G, A, and B — completing the full white key set.",
                tips: ["F is left of the three black keys", "G is between 1st and 2nd of the three black keys", "A is between 2nd and 3rd", "B is right of all three black keys"]
            ),
            LessonContent(
                id: "gs-4",
                title: "Full Octave",
                subtitle: "C through C",
                type: .playNote,
                exerciseNotes: [60, 62, 64, 65, 67, 69, 71, 72],
                description: "Play all 8 white keys from C4 to C5 in sequence.",
                tips: ["Take it slowly — accuracy beats speed", "Keep your wrist relaxed and level", "Each finger gets its own key"]
            ),
            LessonContent(
                id: "gs-5",
                title: "C Major Scale",
                subtitle: "The most important scale",
                type: .scale,
                exerciseNotes: [60, 62, 64, 65, 67, 69, 71, 72],
                description: "The C Major scale — all white keys, no sharps or flats. This is the foundation of Western music.",
                tips: ["Pattern: W-W-H-W-W-W-H (W=whole step, H=half step)", "Practice going up then back down", "Try to keep a steady tempo"]
            ),
            LessonContent(
                id: "gs-6",
                title: "Right Hand Position",
                subtitle: "Proper technique",
                type: .noteIdentify,
                exerciseNotes: [60, 62, 64, 65, 67],
                description: "Place your thumb on C, index on D, middle on E, ring on F, pinky on G. Identify each note as it's highlighted.",
                tips: ["Curved fingers, not flat", "Keep your wrist slightly elevated", "Thumb plays C, pinky plays G"]
            )
        ]
    )

    // MARK: - Module 2: Note Mastery
    static let noteMastery = CurriculumModule(
        id: "note-mastery",
        title: "Note Mastery",
        icon: "music.note",
        color: .blue,
        lessons: [
            LessonContent(
                id: "nm-1",
                title: "Find C",
                subtitle: "Note identification drill",
                type: .noteIdentify,
                exerciseNotes: [48, 60, 72, 84],
                description: "The note C appears multiple times on the keyboard. Each C is always left of the two black keys.",
                tips: ["C is always left of a pair of black keys", "Look for groupings of 2 then 3 black keys to orient yourself"]
            ),
            LessonContent(
                id: "nm-2",
                title: "Find D",
                subtitle: "Note identification drill",
                type: .noteIdentify,
                exerciseNotes: [50, 62, 74],
                description: "D sits between the two black keys. Find it across the keyboard.",
                tips: ["D is sandwiched between the two black keys", "Once you know C, D is one white key to the right"]
            ),
            LessonContent(
                id: "nm-3",
                title: "Find E",
                subtitle: "Note identification drill",
                type: .noteIdentify,
                exerciseNotes: [52, 64, 76],
                description: "E is right of the two black keys and left of the next group of three.",
                tips: ["E is right of the pair of black keys", "E and F are always adjacent white keys"]
            ),
            LessonContent(
                id: "nm-4",
                title: "Find F",
                subtitle: "Note identification drill",
                type: .noteIdentify,
                exerciseNotes: [53, 65, 77],
                description: "F is always left of the three black keys.",
                tips: ["F starts the group of three black keys", "F is directly right of E"]
            ),
            LessonContent(
                id: "nm-5",
                title: "Find G",
                subtitle: "Note identification drill",
                type: .noteIdentify,
                exerciseNotes: [55, 67, 79],
                description: "G is between the 1st and 2nd of the three black keys.",
                tips: ["G is in the middle section of three black keys", "G-A-B fill the spaces between the three black keys and after them"]
            ),
            LessonContent(
                id: "nm-6",
                title: "Find A",
                subtitle: "Note identification drill",
                type: .noteIdentify,
                exerciseNotes: [57, 69, 81],
                description: "A sits between the 2nd and 3rd of the three black keys.",
                tips: ["A440 is the concert tuning pitch", "A is two white keys right of G"]
            ),
            LessonContent(
                id: "nm-7",
                title: "Find B",
                subtitle: "Note identification drill",
                type: .noteIdentify,
                exerciseNotes: [59, 71, 83],
                description: "B is right of the three black keys and is always next to C.",
                tips: ["B and C are always adjacent", "B is the last white key before the next C"]
            ),
            LessonContent(
                id: "nm-8",
                title: "Random Note Drill",
                subtitle: "Mixed identification",
                type: .noteIdentify,
                exerciseNotes: [60, 62, 64, 65, 67, 69, 71, 63, 66, 68],
                description: "Random notes will appear — tap the correct key as fast as you can!",
                tips: ["Use landmarks: C is left of 2 black keys, F is left of 3 black keys", "Everything else is relative to those anchors"]
            )
        ]
    )

    // MARK: - Module 3: Melodies
    static let melodies = CurriculumModule(
        id: "melodies",
        title: "Simple Melodies",
        icon: "music.quarternote.3",
        color: .pink,
        lessons: [
            LessonContent(
                id: "mel-1",
                title: "Twinkle Twinkle",
                subtitle: "Little Star",
                type: .song,
                exerciseNotes: [60, 60, 67, 67, 69, 69, 67, 65, 65, 64, 64, 62, 62, 60],
                description: "One of the most recognizable melodies. C-C-G-G-A-A-G then F-F-E-E-D-D-C.",
                tips: ["'Twin-kle twin-kle lit-tle star' maps to C-C-G-G-A-A-G", "Take each phrase slowly before speeding up"]
            ),
            LessonContent(
                id: "mel-2",
                title: "Mary Had a Little Lamb",
                subtitle: "Classic nursery rhyme",
                type: .song,
                exerciseNotes: [64, 62, 60, 62, 64, 64, 64, 62, 62, 62, 64, 67, 67],
                description: "E-D-C-D-E-E-E, D-D-D, E-G-G — a gentle intro to melodic phrasing.",
                tips: ["Starts on E (the 3rd note of the scale)", "The rhythm is even quarter notes — very steady"]
            ),
            LessonContent(
                id: "mel-3",
                title: "Hot Cross Buns",
                subtitle: "Three-note melody",
                type: .song,
                exerciseNotes: [64, 62, 60, 64, 62, 60, 60, 60, 60, 62, 62, 62, 64, 62, 60],
                description: "Only uses E, D, and C. Perfect for beginners. E-D-C repeated twice, then a run of C's and D's.",
                tips: ["Only three notes: C, D, and E", "Great for getting your fingers used to the keys"]
            ),
            LessonContent(
                id: "mel-4",
                title: "Ode to Joy",
                subtitle: "Beethoven's classic",
                type: .song,
                exerciseNotes: [64, 64, 65, 67, 67, 65, 64, 62, 60, 60, 62, 64, 64, 62, 62],
                description: "From Beethoven's 9th Symphony. E-E-F-G-G-F-E-D-C-C-D-E-E-D-D.",
                tips: ["Starts on E — same as Mary Had a Little Lamb", "The first phrase goes up to G, then comes back down"]
            ),
            LessonContent(
                id: "mel-5",
                title: "Jingle Bells",
                subtitle: "Holiday favorite",
                type: .song,
                exerciseNotes: [64, 64, 64, 64, 64, 64, 64, 67, 60, 62, 64, 65, 65, 65, 65, 65, 64, 64, 64, 62, 62, 64, 62, 67],
                description: "The famous chorus: E-E-E, E-E-E, E-G-C-D-E, F-F-F-F, F-E-E-E-E, D-D-E-D-G.",
                tips: ["The rhythm has a bouncy feeling — short-short-long", "Watch for the jump from E down to C at the end of the first phrase"]
            ),
            LessonContent(
                id: "mel-6",
                title: "Happy Birthday",
                subtitle: "Everyone's favorite",
                type: .song,
                exerciseNotes: [60, 60, 62, 60, 65, 64, 60, 60, 62, 60, 67, 65, 60, 60, 72, 69, 65, 64, 62, 70, 70, 69, 65, 67, 65],
                description: "The most-played song in the world. Starts on C and has an upward leap on 'to you'.",
                tips: ["The rhythm starts with: short-short-LONG-long", "'Hap-py BIRTH-day' uses an upward jump — that's the fun part"]
            )
        ]
    )

    // MARK: - Module 4: Basic Chords
    static let chords = CurriculumModule(
        id: "chords",
        title: "Basic Chords",
        icon: "pianokeys",
        color: .orange,
        lessons: [
            LessonContent(
                id: "ch-1",
                title: "C Major",
                subtitle: "The foundational chord",
                type: .chord,
                exerciseNotes: [60, 64, 67],
                description: "C-E-G played together. This is the most fundamental chord in Western music.",
                tips: ["Thumb on C, middle finger on E, pinky on G", "Press all three keys simultaneously", "This chord appears in thousands of songs"]
            ),
            LessonContent(
                id: "ch-2",
                title: "G Major",
                subtitle: "The second most common",
                type: .chord,
                exerciseNotes: [67, 71, 74],
                description: "G-B-D. Together with C Major, you can play hundreds of songs.",
                tips: ["Thumb on G, middle on B, pinky on D", "G Major is the V chord in the key of C", "Think of it as 'resolving' back to C Major"]
            ),
            LessonContent(
                id: "ch-3",
                title: "F Major",
                subtitle: "The IV chord",
                type: .chord,
                exerciseNotes: [65, 69, 72],
                description: "F-A-C. With C, F, and G major you can play I-IV-V progressions.",
                tips: ["Thumb on F, middle on A, pinky on C", "C-F-G-C is one of the most used chord progressions ever"]
            ),
            LessonContent(
                id: "ch-4",
                title: "A Minor",
                subtitle: "Your first minor chord",
                type: .chord,
                exerciseNotes: [57, 60, 64],
                description: "A-C-E. Minor chords have a sadder, more emotional sound than major chords.",
                tips: ["Thumb on A, middle on C, pinky on E", "Notice how lowering the middle note (vs A major) changes the feel", "Am is the relative minor of C major"]
            ),
            LessonContent(
                id: "ch-5",
                title: "D Minor",
                subtitle: "Melancholic beauty",
                type: .chord,
                exerciseNotes: [62, 65, 69],
                description: "D-F-A. Dm is used in countless emotional pieces.",
                tips: ["Thumb on D, middle on F, pinky on A", "Dm sounds darker than Am", "Try C-Am-F-G — a very common progression"]
            ),
            LessonContent(
                id: "ch-6",
                title: "E Minor",
                subtitle: "Completing the set",
                type: .chord,
                exerciseNotes: [64, 67, 71],
                description: "E-G-B. Em adds a lush, open sound to your chord vocabulary.",
                tips: ["Thumb on E, middle on G, pinky on B", "Em is very common in guitar-based songs", "Try the C-G-Am-Em progression for a classic pop sound"]
            )
        ]
    )

    // MARK: - Module 5: Ear Training
    static let earTraining = CurriculumModule(
        id: "ear-training",
        title: "Ear Training",
        icon: "ear.fill",
        color: .teal,
        lessons: [
            LessonContent(
                id: "et-1",
                title: "Identify C",
                subtitle: "The root note",
                type: .earTrain,
                exerciseNotes: [60, 60, 60, 60, 60],
                description: "Listen to the note played and identify it as C. Train your ear to recognize this foundational pitch.",
                tips: ["C has a clear, bright sound", "Hum along after you hear it", "C is the 'home base' of Western music"]
            ),
            LessonContent(
                id: "et-2",
                title: "Identify D",
                subtitle: "One step up",
                type: .earTrain,
                exerciseNotes: [62, 62, 62, 62],
                description: "Listen for D — one whole step above C. It sounds slightly brighter.",
                tips: ["D is a whole step above C", "Compare it to C to hear the difference", "D has an open, airy quality"]
            ),
            LessonContent(
                id: "et-3",
                title: "Identify E",
                subtitle: "The major third",
                type: .earTrain,
                exerciseNotes: [64, 64, 64, 64],
                description: "E is the major third above C — the note that makes major chords sound bright and happy.",
                tips: ["E is two whole steps above C", "This is the 'happy' note in a C Major chord", "Sing 'Mi' (from Do-Re-Mi) to remember its sound"]
            ),
            LessonContent(
                id: "et-4",
                title: "Identify F",
                subtitle: "The fourth",
                type: .earTrain,
                exerciseNotes: [65, 65, 65, 65],
                description: "F is a perfect fourth above C. It has a strong, stable sound.",
                tips: ["F is a perfect 4th above C", "Think of 'Here Comes the Bride' — that's a perfect 4th leap", "F has a slightly darker quality than E"]
            ),
            LessonContent(
                id: "et-5",
                title: "Identify G",
                subtitle: "The fifth",
                type: .earTrain,
                exerciseNotes: [67, 67, 67, 67],
                description: "G is a perfect fifth above C — the most harmonious interval after the octave.",
                tips: ["G is a perfect 5th above C", "Think of 'Twinkle Twinkle' — the jump from C to G", "Perfect 5ths sound open and strong"]
            ),
            LessonContent(
                id: "et-6",
                title: "Mixed Note Drill",
                subtitle: "Test your ear",
                type: .earTrain,
                exerciseNotes: [60, 62, 64, 65, 67, 69, 71, 60, 64, 67],
                description: "Random notes will play — identify each one by ear. The ultimate ear training test!",
                tips: ["Use C as your reference point", "Count intervals from C if unsure", "Practice makes perfect — this gets easier over time"]
            )
        ]
    )
}
