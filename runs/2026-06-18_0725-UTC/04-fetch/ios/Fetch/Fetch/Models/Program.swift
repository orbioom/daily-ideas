import Foundation

/// A static training program — an ordered curriculum of trick ids.
struct TrainingProgram: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let icon: String
    let durationWeeks: Int
    let trickIDs: [String]
    /// Whether this program requires Pro (free users get the first one or two).
    let requiresPro: Bool

    static func == (lhs: TrainingProgram, rhs: TrainingProgram) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Resolved tricks, skipping any unknown ids defensively.
    var tricks: [Trick] { trickIDs.compactMap { TrickCatalog.trick($0) } }
}

enum ProgramCatalog {
    static func program(_ id: String) -> TrainingProgram? { byID[id] }
    static let byID: [String: TrainingProgram] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }()

    static let all: [TrainingProgram] = [
        TrainingProgram(
            id: "puppy-starter",
            title: "Puppy Starter",
            subtitle: "Your dog's first two weeks of school",
            detail: "Build the foundation every dog needs: focus, their name, and the core commands. Short, positive sessions that set your puppy up for a lifetime of good habits.",
            icon: "graduationcap.fill",
            durationWeeks: 2,
            trickIDs: ["name", "watch-me", "touch", "sit", "down", "come"],
            requiresPro: false
        ),
        TrainingProgram(
            id: "good-manners",
            title: "Good Manners",
            subtitle: "A polite, easy-to-live-with dog",
            detail: "Stop the jumping, the door-bolting, and the grabbing. This program turns daily life into a series of calm, well-mannered routines you'll both enjoy.",
            icon: "hand.raised.fill",
            durationWeeks: 4,
            trickIDs: ["leave-it", "drop-it", "stay", "wait-at-door", "leave-greeting", "go-to-bed"],
            requiresPro: false
        ),
        TrainingProgram(
            id: "leash-mastery",
            title: "Leash Mastery",
            subtitle: "Enjoyable walks, every time",
            detail: "Trade pulling and zig-zagging for a relaxed, connected walk. Progress from indoor focus to a polished heel you can use anywhere.",
            icon: "figure.walk",
            durationWeeks: 4,
            trickIDs: ["watch-me", "name", "loose-leash", "back-up", "heel"],
            requiresPro: true
        ),
        TrainingProgram(
            id: "party-tricks",
            title: "Party Tricks",
            subtitle: "Show-stoppers that wow a crowd",
            detail: "Once the basics are solid, have fun. Shake, spin, roll over, play dead and weave \u{2014} a repertoire of crowd-pleasers that strengthens your bond.",
            icon: "sparkles",
            durationWeeks: 6,
            trickIDs: ["shake", "high-five", "spin", "roll-over", "play-dead", "weave", "wave"],
            requiresPro: true
        ),
        TrainingProgram(
            id: "calm-focus",
            title: "Calm & Focus",
            subtitle: "An off-switch for busy dogs",
            detail: "Teach your dog to relax on cue, settle anywhere, and choose calm over chaos. Perfect for excitable dogs and anyone who wants a peaceful household.",
            icon: "moon.zzz.fill",
            durationWeeks: 4,
            trickIDs: ["settle", "place", "go-to-bed", "find-it", "stay"],
            requiresPro: true
        )
    ]
}
