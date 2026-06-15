import SwiftUI

/// A friendly, named archetype derived from the four-letter type code.
/// The four letters are: Mind (E/I), Energy (N/S → here O/G for Open/Grounded),
/// Nature (T/F), Tactics (J/P). Identity (Assertive/Turbulent) is appended separately.
struct Archetype: Identifiable {
    let code: String          // 4-letter code, e.g. "INFJ"-style mapped to Facet's dimensions
    let name: String
    let tagline: String
    let description: String
    let strengths: [String]
    let growthAreas: [String]
    let careers: [String]
    let relationshipNotes: String
    let hex: UInt

    var id: String { code }
    var color: Color { Color(hex: hex) }

    static func forCode(_ code: String) -> Archetype {
        catalog.first { $0.code == code } ?? fallback
    }

    /// Used only if a code somehow has no match (should not occur — all 16 are covered).
    static let fallback = Archetype(
        code: "----",
        name: "The Explorer",
        tagline: "A unique blend all your own.",
        description: "Your pattern of traits forms a distinctive blend. Explore each trait below to understand the facets that make you, you.",
        strengths: ["Adaptable", "Open-minded", "Self-aware"],
        growthAreas: ["Define what matters most to you"],
        careers: ["Roles that reward versatility"],
        relationshipNotes: "You bring a flexible, considerate presence to your relationships.",
        hex: 0x5A52C8
    )

    static let catalog: [Archetype] = [
        Archetype(code: "INTJ", name: "The Architect", tagline: "Quietly turns big ideas into working plans.",
                  description: "Reserved, inventive, and highly organized, Architects pair a love of abstract ideas with the discipline to execute them. You think in systems and prefer a small circle of trusted people.",
                  strengths: ["Strategic thinking", "Independence", "Long-range planning", "Decisiveness"],
                  growthAreas: ["Sharing the reasoning behind decisions", "Allowing for messiness and play", "Asking for help sooner"],
                  careers: ["Research scientist", "Software architect", "Strategy consultant", "Investment analyst"],
                  relationshipNotes: "You value depth over breadth and show care through reliability and well-thought-out support more than spontaneous affection.",
                  hex: 0x4B3FA0),
        Archetype(code: "INTP", name: "The Theorist", tagline: "Endlessly curious, allergic to assumptions.",
                  description: "Theorists are imaginative, analytical, and comfortable in their own minds. You love exploring how things work and resist accepting ideas before you've examined them yourself.",
                  strengths: ["Original thinking", "Objectivity", "Curiosity", "Problem-solving"],
                  growthAreas: ["Following through on routine tasks", "Voicing feelings", "Setting deadlines that stick"],
                  careers: ["Researcher", "Engineer", "Data scientist", "Philosopher or writer"],
                  relationshipNotes: "You connect through ideas and shared curiosity, and appreciate partners who give you room to think.",
                  hex: 0x3F6FB0),
        Archetype(code: "ENTJ", name: "The Commander", tagline: "Sees the goal and builds the road to it.",
                  description: "Commanders are bold, structured, and energized by leading. You combine openness to new ideas with the drive and sociability to rally people around a plan.",
                  strengths: ["Leadership", "Confidence", "Efficiency", "Strategic drive"],
                  growthAreas: ["Patience with slower processes", "Softening directness", "Making space for others' input"],
                  careers: ["Executive", "Entrepreneur", "Project director", "Management consultant"],
                  relationshipNotes: "You're loyal and invested, and you express love by helping the people you care about grow and succeed.",
                  hex: 0x9A3F8A),
        Archetype(code: "ENTP", name: "The Innovator", tagline: "A spark factory who loves a good debate.",
                  description: "Innovators are quick, inventive, and socially fearless. You thrive on possibility, enjoy challenging conventions, and can argue any side of an idea for fun.",
                  strengths: ["Idea generation", "Charisma", "Adaptability", "Quick thinking"],
                  growthAreas: ["Finishing what you start", "Reading the room emotionally", "Committing to one path"],
                  careers: ["Founder", "Marketer", "Product manager", "Creative director"],
                  relationshipNotes: "You keep things lively and intellectually rich, and connect best with people who can banter and grow alongside you.",
                  hex: 0xB55C3A),
        Archetype(code: "INFJ", name: "The Advocate", tagline: "Quiet conviction with a vision for people.",
                  description: "Advocates are imaginative, principled, and deeply attuned to others. You combine inner depth with a sense of purpose, often quietly working toward a better way of doing things.",
                  strengths: ["Insight into people", "Conviction", "Creativity", "Dedication"],
                  growthAreas: ["Setting boundaries", "Accepting imperfection", "Not over-extending for others"],
                  careers: ["Counselor", "Writer", "Nonprofit leader", "UX researcher"],
                  relationshipNotes: "You seek meaningful, authentic bonds and give partners rare emotional understanding and loyalty.",
                  hex: 0x2E8C7A),
        Archetype(code: "INFP", name: "The Dreamer", tagline: "Guided by values and a vivid inner world.",
                  description: "Dreamers are gentle, creative, and idealistic. You're driven by deeply held values and a rich imagination, and you care about authenticity above almost anything.",
                  strengths: ["Empathy", "Imagination", "Idealism", "Open-mindedness"],
                  growthAreas: ["Practical follow-through", "Handling criticism", "Grounding ideals in action"],
                  careers: ["Writer or artist", "Therapist", "Designer", "Social worker"],
                  relationshipNotes: "You love deeply and selectively, offering warmth, acceptance, and a partner who truly sees the real you.",
                  hex: 0x4FA08C),
        Archetype(code: "ENFJ", name: "The Mentor", tagline: "Warm, persuasive, and people-first.",
                  description: "Mentors are charismatic, caring, and organized. You read people well and naturally guide, encourage, and bring out the best in those around you.",
                  strengths: ["Empathy", "Communication", "Reliability", "Inspiring others"],
                  growthAreas: ["Saying no", "Tending to your own needs", "Tolerating conflict"],
                  careers: ["Teacher", "Team lead", "HR or coaching", "Community organizer"],
                  relationshipNotes: "You're devoted and nurturing, often the emotional anchor for the people you love.",
                  hex: 0x2E9E6B),
        Archetype(code: "ENFP", name: "The Spark", tagline: "Enthusiasm that's contagious.",
                  description: "Sparks are warm, imaginative, and full of energy. You see potential everywhere, connect easily with people, and bring play and possibility into any room.",
                  strengths: ["Enthusiasm", "Warmth", "Creativity", "Connection"],
                  growthAreas: ["Focus and follow-through", "Routine and detail", "Managing overcommitment"],
                  careers: ["Storyteller", "Brand strategist", "Event creator", "Public relations"],
                  relationshipNotes: "You bring spontaneity and affection, and you flourish with partners who share your sense of adventure.",
                  hex: 0xE0A23A),
        Archetype(code: "ISTJ", name: "The Steward", tagline: "Dependable to the core.",
                  description: "Stewards are practical, dependable, and thorough. You value tradition, honor your commitments, and quietly keep things running well.",
                  strengths: ["Reliability", "Diligence", "Practical judgment", "Integrity"],
                  growthAreas: ["Embracing change", "Expressing emotion", "Considering new approaches"],
                  careers: ["Accountant", "Operations manager", "Engineer", "Logistics lead"],
                  relationshipNotes: "You show love through consistency and follow-through; your word is your bond.",
                  hex: 0x546E91),
        Archetype(code: "ISFJ", name: "The Protector", tagline: "Quiet care, fiercely loyal.",
                  description: "Protectors are warm, conscientious, and grounded. You notice what others need and provide steady, practical support without seeking the spotlight.",
                  strengths: ["Loyalty", "Attentiveness", "Patience", "Practical care"],
                  growthAreas: ["Asserting your needs", "Adapting to change", "Avoiding self-sacrifice"],
                  careers: ["Nurse", "Teacher", "Administrator", "Customer care lead"],
                  relationshipNotes: "You're devoted and dependable, remembering the small things that make people feel cared for.",
                  hex: 0x3E8E84),
        Archetype(code: "ESTJ", name: "The Director", tagline: "Gets things organized and done.",
                  description: "Directors are decisive, structured, and sociable. You value order and results, and you're comfortable taking charge to keep things on track.",
                  strengths: ["Organization", "Leadership", "Dedication", "Directness"],
                  growthAreas: ["Flexibility", "Patience with ambiguity", "Acknowledging feelings"],
                  careers: ["Operations director", "Project manager", "Officer", "Business owner"],
                  relationshipNotes: "You're a stable, committed partner who shows care by creating security and structure.",
                  hex: 0x8A5C2E),
        Archetype(code: "ESFJ", name: "The Host", tagline: "Builds belonging wherever they go.",
                  description: "Hosts are warm, dependable, and socially attuned. You create harmony, take care of practical needs, and make people feel they belong.",
                  strengths: ["Warmth", "Reliability", "Cooperation", "Practical support"],
                  growthAreas: ["Handling criticism", "Setting boundaries", "Welcoming change"],
                  careers: ["Event manager", "Healthcare", "Teacher", "Community lead"],
                  relationshipNotes: "You're generous and attentive, thriving in close, harmonious relationships.",
                  hex: 0xD08C3A),
        Archetype(code: "ISTP", name: "The Craftsman", tagline: "Calm hands, practical mind.",
                  description: "Craftsmen are independent, observant, and hands-on. You stay cool under pressure and solve real-world problems with practical skill.",
                  strengths: ["Composure", "Practical skill", "Adaptability", "Independence"],
                  growthAreas: ["Long-term planning", "Sharing feelings", "Committing early"],
                  careers: ["Engineer", "Pilot", "Technician", "Athlete or trainer"],
                  relationshipNotes: "You show care through action and presence, and value partners who respect your space.",
                  hex: 0x4F7A8C),
        Archetype(code: "ISFP", name: "The Artisan", tagline: "Lives in the moment, makes it beautiful.",
                  description: "Artisans are gentle, sensitive, and aesthetic. You experience the world vividly and express yourself through creating and through quiet, genuine kindness.",
                  strengths: ["Aesthetic sense", "Empathy", "Flexibility", "Authenticity"],
                  growthAreas: ["Planning ahead", "Speaking up", "Handling stress"],
                  careers: ["Designer", "Chef", "Musician", "Photographer"],
                  relationshipNotes: "You love tenderly and in the present, offering warmth and a deep appreciation of your partner.",
                  hex: 0x4FA0A0),
        Archetype(code: "ESTP", name: "The Dynamo", tagline: "Action first, momentum always.",
                  description: "Dynamos are bold, practical, and energetic. You love action, think on your feet, and bring a magnetic, can-do energy to any challenge.",
                  strengths: ["Boldness", "Quick reactions", "Sociability", "Practicality"],
                  growthAreas: ["Patience", "Long-term focus", "Considering consequences"],
                  careers: ["Sales lead", "Entrepreneur", "Paramedic", "Sports coach"],
                  relationshipNotes: "You keep relationships exciting and grounded, and connect through shared activity and fun.",
                  hex: 0xB5703A),
        Archetype(code: "ESFP", name: "The Entertainer", tagline: "Turns ordinary moments into joy.",
                  description: "Entertainers are vivacious, warm, and spontaneous. You live fully in the present, love being around people, and bring lightness and delight to any gathering.",
                  strengths: ["Warmth", "Spontaneity", "Enthusiasm", "Practical empathy"],
                  growthAreas: ["Planning and focus", "Handling routine", "Sitting with hard feelings"],
                  careers: ["Performer", "Host", "Event planner", "Hospitality lead"],
                  relationshipNotes: "You're affectionate and generous, filling relationships with energy, play, and care.",
                  hex: 0xE08C4A)
    ]
}
