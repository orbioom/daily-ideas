import Foundation

/// The ten classic cognitive distortions (Burns/Beck), each with a plain
/// description and a reframing question to challenge it.
struct Distortion: Identifiable, Hashable {
    let id: String
    let name: String
    let blurb: String
    let challenge: String
}

enum Distortions {

    static func named(_ id: String) -> Distortion? { all.first { $0.id == id } }

    static let all: [Distortion] = [
        Distortion(id: "allornothing", name: "All-or-nothing thinking",
                   blurb: "Seeing things in black-and-white — anything short of perfect is total failure.",
                   challenge: "Where's the middle ground here? What would 'partly' look like?"),
        Distortion(id: "overgeneralization", name: "Overgeneralization",
                   blurb: "Treating one event as a never-ending pattern (‘always’, ‘never’).",
                   challenge: "Is this really every time, or is this one specific moment?"),
        Distortion(id: "mentalfilter", name: "Mental filter",
                   blurb: "Dwelling on a single negative and screening out everything positive.",
                   challenge: "What am I leaving out of the picture right now?"),
        Distortion(id: "discounting", name: "Discounting the positive",
                   blurb: "Insisting good things ‘don't count’ so the negative view survives.",
                   challenge: "If a friend did this, would I call it nothing?"),
        Distortion(id: "jumping", name: "Jumping to conclusions",
                   blurb: "Mind-reading others or fortune-telling the future with no evidence.",
                   challenge: "What do I actually know versus what am I guessing?"),
        Distortion(id: "magnification", name: "Magnification / catastrophizing",
                   blurb: "Blowing things up out of proportion — or shrinking your own strengths.",
                   challenge: "What's the most likely outcome, not the worst one?"),
        Distortion(id: "emotional", name: "Emotional reasoning",
                   blurb: "‘I feel it, so it must be true.’ Feelings stand in for facts.",
                   challenge: "Would this hold up if I weren't feeling this way?"),
        Distortion(id: "should", name: "Should statements",
                   blurb: "Rigid rules — ‘must’, ‘should’, ‘ought’ — that breed guilt and pressure.",
                   challenge: "Says who? What would I prefer, rather than demand?"),
        Distortion(id: "labeling", name: "Labeling",
                   blurb: "Turning a mistake into an identity: ‘I'm a failure’ instead of ‘I failed at this’.",
                   challenge: "Can I describe the behavior instead of branding myself?"),
        Distortion(id: "personalization", name: "Personalization & blame",
                   blurb: "Holding yourself responsible for things outside your control.",
                   challenge: "What part was actually mine, and what wasn't?")
    ]
}

/// A small library of common emotions to pick from (custom allowed too).
enum EmotionLibrary {
    static let common = [
        "Anxious", "Sad", "Angry", "Frustrated", "Ashamed", "Guilty",
        "Lonely", "Overwhelmed", "Embarrassed", "Hopeless", "Stressed",
        "Insecure", "Disappointed", "Hurt", "Nervous", "Irritated"
    ]
}

/// Short grounding/coping exercises for moments before a record makes sense.
struct CopingTool: Identifiable {
    let id: String
    let title: String
    let duration: String
    let symbol: String
    let steps: [String]
}

enum CopingTools {
    static let all: [CopingTool] = [
        CopingTool(id: "54321", title: "5-4-3-2-1 Grounding", duration: "2 min", symbol: "eye",
                   steps: ["Name 5 things you can see.",
                           "Name 4 things you can feel.",
                           "Name 3 things you can hear.",
                           "Name 2 things you can smell.",
                           "Name 1 thing you can taste.",
                           "Notice your feet on the floor. You're here, now."]),
        CopingTool(id: "box", title: "Box Breathing", duration: "3 min", symbol: "square",
                   steps: ["Breathe in through the nose for 4 counts.",
                           "Hold gently for 4 counts.",
                           "Breathe out slowly for 4 counts.",
                           "Hold empty for 4 counts.",
                           "Repeat the square six times.",
                           "Let the out-breath be a little longer than the in-breath."]),
        CopingTool(id: "ts", title: "Thought vs. Fact", duration: "1 min", symbol: "scalemass",
                   steps: ["Write the thought exactly as it sounded.",
                           "Ask: is this a fact, or a thought about a fact?",
                           "Find one piece of evidence it might be false.",
                           "Restate it as a guess, not a verdict.",
                           "Notice you don't have to believe every thought you have."]),
        CopingTool(id: "self", title: "Talk to a Friend", duration: "2 min", symbol: "heart.text.square",
                   steps: ["Picture a friend saying this exact thought about themselves.",
                           "What would you genuinely say back to them?",
                           "Notice the gap between that and how you talk to yourself.",
                           "Offer yourself the friend's version, in your own words."]),
        CopingTool(id: "urge", title: "Urge Surfing", duration: "5 min", symbol: "water.waves",
                   steps: ["Notice the urge or feeling without acting on it.",
                           "Locate it in your body — where, how big, what shape?",
                           "Breathe into it; let it rise like a wave.",
                           "Waves crest and fall. Watch this one fall.",
                           "You can feel something fully without obeying it."])
    ]
}
