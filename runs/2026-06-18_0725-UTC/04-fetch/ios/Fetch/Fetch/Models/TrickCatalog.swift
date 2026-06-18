import Foundation

/// The fixed catalog of ~40 tricks/commands with genuinely useful step-by-step content.
enum TrickCatalog {

    /// Fast lookup by id. Returns nil for unknown ids (caller must handle).
    static func trick(_ id: String) -> Trick? { byID[id] }

    static func tricks(in category: TrickCategory) -> [Trick] {
        all.filter { $0.category == category }
    }

    static let byID: [String: Trick] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }()

    static let all: [Trick] = [

        // MARK: - Basics
        Trick(id: "name", name: "Name Recognition", category: .basics, difficulty: .beginner,
              icon: "quote.bubble.fill",
              summary: "Teach your dog that their name means \u{201C}look at me, good things are coming.\u{201D}",
              steps: [
                "Stand close to your dog in a quiet, low-distraction room.",
                "Say their name once in a warm, upbeat tone.",
                "The instant they turn toward you, mark with \u{201C}yes!\u{201D} and give a treat.",
                "Repeat 8\u{2013}10 times, then take a short break.",
                "Practice at slowly increasing distances around the house.",
                "Add mild distractions (a toy on the floor) and reward the look-back."
              ],
              tips: [
                "Never repeat the name over and over \u{2014} say it once.",
                "Never use the name for scolding, or it loses its magic."
              ],
              estimatedDays: 3, prerequisites: []),

        Trick(id: "watch-me", name: "Watch Me", category: .basics, difficulty: .beginner,
              icon: "eye.fill",
              summary: "Build focus and eye contact \u{2014} the foundation for every other cue.",
              steps: [
                "Hold a treat at your dog's nose, then slowly raise it to your eyes.",
                "As their eyes follow to your face, say \u{201C}watch me\u{201D} and mark \u{201C}yes!\u{201D}",
                "Reward the moment of eye contact.",
                "Repeat, gradually expecting a half-second longer of contact.",
                "Fade the lure: point to your eyes with an empty hand and reward the look.",
                "Practice in new rooms and then outdoors."
              ],
              tips: [
                "Keep sessions to 2\u{2013}3 minutes so focus stays sharp.",
                "Build duration in tiny increments \u{2014} a second at a time."
              ],
              estimatedDays: 4, prerequisites: ["name"]),

        Trick(id: "sit", name: "Sit", category: .basics, difficulty: .beginner,
              icon: "dog.fill",
              summary: "The classic first command \u{2014} a calm default position on cue.",
              steps: [
                "Hold a treat just above your dog's nose.",
                "Slowly move it back over their head; their nose lifts and rear lowers.",
                "The moment their bottom touches the floor, say \u{201C}yes!\u{201D} and treat.",
                "Repeat several times with the lure.",
                "Add the word \u{201C}sit\u{201D} right as they begin to sit.",
                "Fade the treat lure to an empty-hand gesture.",
                "Practice in different rooms and positions."
              ],
              tips: [
                "Don't push their rear down \u{2014} let them figure it out.",
                "Reward fast at first, then ask for a brief hold before treating."
              ],
              estimatedDays: 3, prerequisites: []),

        Trick(id: "down", name: "Down", category: .basics, difficulty: .easy,
              icon: "arrow.down.to.line",
              summary: "Lie down on cue \u{2014} a relaxed position great for settling.",
              steps: [
                "Start with your dog in a sit.",
                "Hold a treat at their nose, lower it straight to the floor between their paws.",
                "Slide it slowly along the floor away from them.",
                "As elbows and belly reach the floor, mark \u{201C}yes!\u{201D} and treat.",
                "Add the cue \u{201C}down\u{201D} as the motion becomes reliable.",
                "Fade the lure into a flat-hand downward gesture."
              ],
              tips: [
                "Use a soft surface for comfort on hard floors.",
                "If they pop up, treat earlier \u{2014} reward the elbows touching first."
              ],
              estimatedDays: 5, prerequisites: ["sit"]),

        Trick(id: "come", name: "Come (Recall)", category: .basics, difficulty: .easy,
              icon: "figure.walk.arrival",
              summary: "A reliable recall \u{2014} possibly the most important safety skill you'll teach.",
              steps: [
                "In a hallway or small room, crouch and open your arms invitingly.",
                "Say \u{201C}come!\u{201D} once in a happy, excited voice.",
                "Reward generously the instant they arrive \u{2014} make it a party.",
                "Gently hold their collar before treating (so being grabbed is positive).",
                "Increase distance gradually, then add a long line outdoors.",
                "Practice with another person doing back-and-forth recalls."
              ],
              tips: [
                "Always pay big for a recall \u{2014} this is the cue you never want to weaken.",
                "Never call \u{201C}come\u{201D} for something unpleasant like nail trims."
              ],
              estimatedDays: 10, prerequisites: ["name"]),

        Trick(id: "stay", name: "Stay", category: .basics, difficulty: .intermediate,
              icon: "hand.raised.fill",
              summary: "Hold position until released \u{2014} built on the three D's: duration, distance, distraction.",
              steps: [
                "Ask for a sit. Say \u{201C}stay\u{201D} with a flat-palm hand signal.",
                "Wait one second, mark \u{201C}yes!\u{201D}, reward, then release with \u{201C}okay!\u{201D}",
                "Slowly build duration: 2s, 4s, 8s, always returning to reward.",
                "Add distance: take one step back, return, reward. Build up gradually.",
                "Add distractions only after duration and distance are solid.",
                "Always end the stay with a clear release word."
              ],
              tips: [
                "Increase only ONE of the three D's at a time.",
                "If they break, you raised the bar too fast \u{2014} make it easier."
              ],
              estimatedDays: 14, prerequisites: ["sit", "down"]),

        // MARK: - Manners
        Trick(id: "leave-it", name: "Leave It", category: .manners, difficulty: .easy,
              icon: "nosign",
              summary: "Ignore something tempting on cue \u{2014} keeps your dog safe from hazards.",
              steps: [
                "Place a treat in a closed fist; let your dog sniff and nudge it.",
                "Wait. The moment they back off, mark \u{201C}yes!\u{201D} and reward from your OTHER hand.",
                "Add the cue \u{201C}leave it\u{201D} as they learn to pull back.",
                "Progress to an open palm, then a treat on the floor (cover with your foot if needed).",
                "Practice with the treat fully exposed on the floor.",
                "Generalize to objects on walks."
              ],
              tips: [
                "Always reward from a different source than the forbidden item.",
                "The reward should be better than what they left."
              ],
              estimatedDays: 7, prerequisites: ["watch-me"]),

        Trick(id: "drop-it", name: "Drop It", category: .manners, difficulty: .easy,
              icon: "arrow.down.circle.fill",
              summary: "Release an object from the mouth on cue \u{2014} vital for safety and fetch.",
              steps: [
                "Offer a toy your dog likes to hold.",
                "Present a high-value treat near their nose and say \u{201C}drop it.\u{201D}",
                "When they release the toy for the treat, mark \u{201C}yes!\u{201D} and reward.",
                "Return the toy so they learn dropping doesn't mean losing it.",
                "Repeat, then begin to fade the food lure.",
                "Practice with a variety of objects."
              ],
              tips: [
                "Make trading a great deal so they want to drop.",
                "Never chase or pry \u{2014} it teaches them to guard."
              ],
              estimatedDays: 6, prerequisites: []),

        Trick(id: "place", name: "Place / Mat", category: .manners, difficulty: .intermediate,
              icon: "square.dashed",
              summary: "Go to and stay on a mat \u{2014} an off-switch for busy moments.",
              steps: [
                "Set down a distinct mat or bed.",
                "Lure your dog onto it and reward the moment all four paws are on.",
                "Add the cue \u{201C}place\u{201D} as they step on reliably.",
                "Reward a down on the mat; build duration like a stay.",
                "Send them from a step away, then across the room.",
                "Practice during distractions like doorbells and mealtimes."
              ],
              tips: [
                "The mat should be portable so \u{201C}place\u{201D} travels anywhere.",
                "Reward heavily on the mat to make it the best spot in the house."
              ],
              estimatedDays: 12, prerequisites: ["down", "stay"]),

        Trick(id: "wait-at-door", name: "Wait at the Door", category: .manners, difficulty: .intermediate,
              icon: "door.left.hand.closed",
              summary: "Pause at thresholds instead of bolting \u{2014} a key safety manner.",
              steps: [
                "Approach a closed door with your dog.",
                "Say \u{201C}wait\u{201D} and begin to open the door slowly.",
                "If they move forward, calmly close it. Open again when they hold still.",
                "Reward holding position with the door open.",
                "Release with \u{201C}okay\u{201D} to go through together.",
                "Practice at the front door, car door, and gates."
              ],
              tips: [
                "Patience wins \u{2014} the door closing is the only consequence needed.",
                "Always release deliberately so they never self-release."
              ],
              estimatedDays: 10, prerequisites: ["stay"]),

        Trick(id: "settle", name: "Settle", category: .manners, difficulty: .intermediate,
              icon: "moon.zzz.fill",
              summary: "Relax calmly on cue \u{2014} teach your dog an \u{201C}off switch.\u{201D}",
              steps: [
                "With your dog on a lie-down, reward slow, calm breathing.",
                "Add the word \u{201C}settle\u{201D} during quiet moments.",
                "Reward staying relaxed for gradually longer stretches.",
                "Practice on a mat during low-key household activity.",
                "Add gentle real-life situations: a cafe patio, a visitor arriving.",
                "Reward calmness, never excitement, during this cue."
              ],
              tips: [
                "Use slow, low-energy delivery of treats to keep arousal down.",
                "Pair with the Calm & Focus program for best results."
              ],
              estimatedDays: 14, prerequisites: ["down", "place"]),

        Trick(id: "loose-leash", name: "Loose-Leash Walking", category: .manners, difficulty: .intermediate,
              icon: "figure.walk",
              summary: "Walk without pulling \u{2014} a relaxed leash makes every walk better.",
              steps: [
                "Start indoors. Reward your dog for standing beside you with a loose leash.",
                "Take one step; reward if the leash stays slack.",
                "If the leash tightens, stop moving \u{2014} pulling never gets them forward.",
                "When the leash loosens, resume and reward.",
                "Add turns and change pace to keep them attentive.",
                "Gradually move to quiet outdoor areas, then busier ones."
              ],
              tips: [
                "Reward generously when they're in the sweet spot beside you.",
                "Short, frequent sessions beat one long frustrating walk."
              ],
              estimatedDays: 21, prerequisites: ["watch-me", "name"]),

        Trick(id: "crate", name: "Crate Comfort", category: .manners, difficulty: .easy,
              icon: "tray.fill",
              summary: "Love the crate as a cozy den \u{2014} great for rest and travel.",
              steps: [
                "Leave the crate open and toss treats inside for free exploration.",
                "Feed meals just inside, then fully inside, the crate.",
                "Add a cue like \u{201C}crate\u{201D} as they walk in.",
                "Close the door for a few seconds while they eat, then open.",
                "Slowly build closed-door duration with a chew toy.",
                "Practice short departures so alone-time stays calm."
              ],
              tips: [
                "Never use the crate as punishment.",
                "Go at the dog's pace \u{2014} forcing creates fear."
              ],
              estimatedDays: 14, prerequisites: []),

        // MARK: - Tricks
        Trick(id: "shake", name: "Shake / Paw", category: .tricks, difficulty: .easy,
              icon: "pawprint.fill",
              summary: "Offer a paw on cue \u{2014} a crowd-pleasing first trick.",
              steps: [
                "Ask for a sit.",
                "Hold a treat in a closed fist near their paw.",
                "Most dogs paw at the fist \u{2014} mark \u{201C}yes!\u{201D} the moment they do and reward.",
                "Add the cue \u{201C}shake\u{201D} as the paw lifts.",
                "Offer an open hand instead of a fist and reward the paw touch.",
                "Practice with each paw to build coordination."
              ],
              tips: [
                "If they don't paw, gently tickle behind the paw to prompt a lift.",
                "Keep your hand low so they don't have to reach uncomfortably."
              ],
              estimatedDays: 4, prerequisites: ["sit"]),

        Trick(id: "high-five", name: "High Five", category: .tricks, difficulty: .easy,
              icon: "hand.raised.fingers.spread.fill",
              summary: "Turn \u{201C}shake\u{201D} into a flashy high five.",
              steps: [
                "Start from a solid \u{201C}shake.\u{201D}",
                "Raise your open hand a little higher and turn the palm toward them.",
                "As their paw meets your palm, say \u{201C}high five!\u{201D} and reward.",
                "Gradually raise the target height.",
                "Fade extra prompts so the palm itself is the cue.",
                "Practice until it's snappy and reliable."
              ],
              tips: [
                "Keep the target within easy reach to avoid strain.",
                "Big enthusiasm makes this trick pop for an audience."
              ],
              estimatedDays: 5, prerequisites: ["shake"]),

        Trick(id: "spin", name: "Spin", category: .tricks, difficulty: .easy,
              icon: "arrow.clockwise",
              summary: "A full circle spin on cue \u{2014} fun and great for body awareness.",
              steps: [
                "With your dog standing, hold a treat at their nose.",
                "Lure a slow circle so their body follows the treat around.",
                "Mark \u{201C}yes!\u{201D} and reward once they complete the turn.",
                "Add the cue \u{201C}spin\u{201D} as the circle becomes smooth.",
                "Shrink the hand motion into a small finger circle.",
                "Teach the other direction with a different word like \u{201C}twist.\u{201D}"
              ],
              tips: [
                "Go slow at first so they don't get dizzy or sloppy.",
                "Reward in the direction of travel to keep momentum."
              ],
              estimatedDays: 6, prerequisites: ["sit"]),

        Trick(id: "roll-over", name: "Roll Over", category: .tricks, difficulty: .intermediate,
              icon: "arrow.2.circlepath",
              summary: "A complete roll \u{2014} a classic show-stopper built from \u{201C}down.\u{201D}",
              steps: [
                "Start in a down. Lure a treat from their nose toward their shoulder.",
                "As they turn their head and flop onto a hip, reward.",
                "Continue the lure over the back so they roll fully over.",
                "Mark and reward the complete roll.",
                "Add the cue \u{201C}roll over\u{201D} once the motion is fluid.",
                "Shrink the hand signal into a small circular gesture."
              ],
              tips: [
                "Use a soft surface \u{2014} hard floors discourage rolling.",
                "Break it into half-rolls if the full roll is too much at first."
              ],
              estimatedDays: 12, prerequisites: ["down"]),

        Trick(id: "play-dead", name: "Play Dead", category: .tricks, difficulty: .intermediate,
              icon: "heart.slash.fill",
              summary: "Flop dramatically onto the side on cue \u{2014} \u{201C}bang!\u{201D}",
              steps: [
                "Start in a down.",
                "Lure their nose toward their shoulder so they roll onto one hip, then their side.",
                "Mark and reward when they're lying flat on their side.",
                "Add a fun cue like \u{201C}bang!\u{201D} with a finger-gun gesture.",
                "Build duration so they hold the pose.",
                "Add a release word to \u{201C}come back to life.\u{201D}"
              ],
              tips: [
                "Reward staying still \u{2014} the drama is in the hold.",
                "Keep it light and playful for the best stage presence."
              ],
              estimatedDays: 12, prerequisites: ["down", "settle"]),

        Trick(id: "speak", name: "Speak", category: .tricks, difficulty: .intermediate,
              icon: "speaker.wave.2.fill",
              summary: "Bark on cue \u{2014} and the foundation for teaching \u{201C}quiet.\u{201D}",
              steps: [
                "Find what makes your dog bark (a knock, a held-back toy).",
                "The moment they bark, mark \u{201C}yes!\u{201D} and reward.",
                "Add the cue \u{201C}speak\u{201D} right before the trigger.",
                "Reward a single bark, not a barking fit.",
                "Then teach \u{201C}quiet\u{201D}: reward silence after a speak.",
                "Alternate speak and quiet for great vocal control."
              ],
              tips: [
                "Keep sessions short to avoid over-arousal.",
                "Only reward one crisp bark so it stays controlled."
              ],
              estimatedDays: 10, prerequisites: ["sit"]),

        Trick(id: "bow", name: "Take a Bow", category: .tricks, difficulty: .intermediate,
              icon: "figure.bowing",
              summary: "Front end down, rear up \u{2014} an elegant stretch and a great finale.",
              steps: [
                "Start with your dog standing.",
                "Lure a treat down and slightly back toward their chest.",
                "As their elbows drop while the rear stays up, mark and reward.",
                "Add the cue \u{201C}bow\u{201D} as the position appears.",
                "Build a short hold before rewarding.",
                "Fade the lure into a small downward hand cue."
              ],
              tips: [
                "Catch the bow they naturally do after a nap.",
                "Reward before they collapse into a full down."
              ],
              estimatedDays: 12, prerequisites: ["down"]),

        Trick(id: "fetch", name: "Fetch", category: .tricks, difficulty: .intermediate,
              icon: "tennisball.fill",
              summary: "Chase, grab, and bring back \u{2014} the game that named this app.",
              steps: [
                "Toss a favorite toy a short distance and cheer them on.",
                "When they pick it up, encourage them back with an excited voice.",
                "Reward returning with the toy \u{2014} trade for a treat using \u{201C}drop it.\u{201D}",
                "Immediately throw again so the game is its own reward.",
                "Gradually increase distance.",
                "Add the cue \u{201C}fetch\u{201D} as you toss."
              ],
              tips: [
                "Two identical toys keep reluctant retrievers coming back.",
                "Stop while it's still fun \u{2014} end on a high note."
              ],
              estimatedDays: 14, prerequisites: ["drop-it"]),

        Trick(id: "beg", name: "Beg / Sit Pretty", category: .tricks, difficulty: .advanced,
              icon: "hands.sparkles.fill",
              summary: "Sit up on the haunches with paws tucked \u{2014} cute and great for core strength.",
              steps: [
                "Start in a sit, ideally near a wall or sofa for back support.",
                "Hold a treat just above their nose and raise it slowly.",
                "Reward small lifts of the front paws at first.",
                "Gradually shape a balanced upright sit.",
                "Add the cue \u{201C}sit pretty\u{201D} as balance improves.",
                "Build duration slowly to protect their back."
              ],
              tips: [
                "Build core strength gradually \u{2014} don't force long holds.",
                "A wall behind them helps with early balance."
              ],
              estimatedDays: 18, prerequisites: ["sit", "watch-me"]),

        Trick(id: "weave", name: "Leg Weave", category: .tricks, difficulty: .advanced,
              icon: "figure.walk.motion",
              summary: "Figure-eight through your legs \u{2014} a flashy, athletic trick.",
              steps: [
                "Stand with legs apart. Lure your dog through the gap with a treat.",
                "Reward each pass through your legs.",
                "Step forward and lure them around your other leg for a figure eight.",
                "Build a rhythm of weaving as you walk.",
                "Add the cue \u{201C}weave.\u{201D}",
                "Fade the lure into a small hand guide."
              ],
              tips: [
                "Use both hands to hand off the lure smoothly leg to leg.",
                "Walk slowly until the pattern is smooth."
              ],
              estimatedDays: 18, prerequisites: ["spin", "watch-me"]),

        // MARK: - Agility & Advanced
        Trick(id: "heel", name: "Heel", category: .advanced, difficulty: .advanced,
              icon: "figure.walk.diamond.fill",
              summary: "Walk attentively in the heel position \u{2014} precision walking on cue.",
              steps: [
                "Reward your dog for being at your left side, facing forward.",
                "Take a step with a treat at your seam; reward staying in position.",
                "Add the cue \u{201C}heel\u{201D} as you start to move.",
                "Build several steps in position before rewarding.",
                "Add turns, halts, and pace changes.",
                "Generalize to busier environments gradually."
              ],
              tips: [
                "Reward frequently in early stages to define the exact position.",
                "Keep your hands and rewards consistent on one side."
              ],
              estimatedDays: 28, prerequisites: ["loose-leash", "watch-me"]),

        Trick(id: "jump-arms", name: "Jump Through Arms", category: .advanced, difficulty: .advanced,
              icon: "figure.gymnastics",
              summary: "Leap through a hoop made by your arms \u{2014} a high-energy showpiece.",
              steps: [
                "Kneel and make a low arch with one arm to the floor.",
                "Lure your dog through the gap and reward on the far side.",
                "Slowly raise the arch as they gain confidence.",
                "Form a full circle with both arms once they're comfortable jumping.",
                "Add the cue \u{201C}through\u{201D} or \u{201C}jump.\u{201D}",
                "Keep heights safe and appropriate for their size and age."
              ],
              tips: [
                "Only jump healthy adult dogs \u{2014} protect growing joints.",
                "Keep the height low for small or senior dogs."
              ],
              estimatedDays: 21, prerequisites: ["come", "watch-me"]),

        Trick(id: "fetch-named", name: "Fetch a Named Toy", category: .advanced, difficulty: .advanced,
              icon: "bag.fill",
              summary: "Retrieve a specific toy by name \u{2014} a genuinely impressive cognitive skill.",
              steps: [
                "Pick one toy and play with it while repeating its name often.",
                "Ask your dog to \u{201C}fetch\u{201D} that single toy and reward.",
                "Place it among 1\u{2013}2 boring objects; reward choosing the named toy.",
                "Add a second named toy and practice each separately.",
                "Mix both named toys and ask for one by name.",
                "Slowly expand the vocabulary of named toys."
              ],
              tips: [
                "Teach one name solidly before adding another.",
                "If they err, make it easier \u{2014} go back to one toy."
              ],
              estimatedDays: 30, prerequisites: ["fetch", "fetch-named-prereq"]),

        Trick(id: "find-it", name: "Find It (Nosework)", category: .advanced, difficulty: .intermediate,
              icon: "magnifyingglass",
              summary: "Use the nose to search out hidden treats \u{2014} mentally tiring and confidence-building.",
              steps: [
                "Toss a treat and say \u{201C}find it\u{201D} so they learn the cue means \u{201C}search.\u{201D}",
                "Hide a treat in plain sight while they watch; release to find it.",
                "Hide it slightly out of view and let them sniff it out.",
                "Increase difficulty: behind furniture, under a cup.",
                "Hide several and send them on a hunt.",
                "Move searches to new rooms and the yard."
              ],
              tips: [
                "Let the nose do the work \u{2014} resist helping too soon.",
                "Great rainy-day enrichment that tires the brain."
              ],
              estimatedDays: 10, prerequisites: ["leave-it"]),

        Trick(id: "back-up", name: "Back Up", category: .advanced, difficulty: .intermediate,
              icon: "arrow.uturn.backward",
              summary: "Walk backwards on cue \u{2014} excellent body awareness and rear-end control.",
              steps: [
                "Stand facing your dog in a narrow space like a hallway.",
                "Step gently toward them; as they step back, mark \u{201C}yes!\u{201D} and reward.",
                "Reward one backward step at a time.",
                "Add the cue \u{201C}back up\u{201D} as they move.",
                "Build to several steps before rewarding.",
                "Fade your forward pressure so a hand cue is enough."
              ],
              tips: [
                "A hallway keeps them straight while learning.",
                "Reward by tossing the treat low so they stay back."
              ],
              estimatedDays: 12, prerequisites: ["watch-me"]),

        Trick(id: "touch", name: "Touch (Targeting)", category: .basics, difficulty: .beginner,
              icon: "hand.point.up.left.fill",
              summary: "Touch their nose to your palm \u{2014} a versatile building block for many tricks.",
              steps: [
                "Hold your open palm a few inches from your dog's nose.",
                "Most dogs sniff it \u{2014} the instant their nose touches, mark \u{201C}yes!\u{201D} and reward.",
                "Add the cue \u{201C}touch\u{201D} as the nose makes contact.",
                "Move your hand to different positions and reward the follow.",
                "Use touch to guide movement without a food lure.",
                "Practice in new locations to generalize."
              ],
              tips: [
                "Touch is a gentle way to move a shy dog without luring.",
                "Keep your palm still so the target is clear."
              ],
              estimatedDays: 3, prerequisites: []),

        Trick(id: "stand", name: "Stand", category: .basics, difficulty: .easy,
              icon: "figure.stand",
              summary: "Stand up from a sit or down on cue \u{2014} handy for grooming and vet visits.",
              steps: [
                "Start in a sit.",
                "Hold a treat at nose level and draw it straight forward.",
                "As they rise into a stand, mark \u{201C}yes!\u{201D} and reward.",
                "Add the cue \u{201C}stand\u{201D} as the motion becomes reliable.",
                "Practice from a down position too.",
                "Build a brief hold in the stand before rewarding."
              ],
              tips: [
                "Keep the lure horizontal so they don't pop up or sit back.",
                "Useful for towel-drying muddy paws."
              ],
              estimatedDays: 5, prerequisites: ["sit"]),

        Trick(id: "wave", name: "Wave", category: .tricks, difficulty: .intermediate,
              icon: "hand.wave.fill",
              summary: "A friendly paw wave \u{2014} built naturally from \u{201C}shake.\u{201D}",
              steps: [
                "Start from a reliable \u{201C}shake.\u{201D}",
                "Offer your hand but pull back slightly before contact.",
                "Reward the paw lifting into the air without touching.",
                "Add the cue \u{201C}wave\u{201D} and a waving hand gesture.",
                "Build a couple of paw lifts for a real wave.",
                "Polish the timing so it looks like a greeting."
              ],
              tips: [
                "Reward the airborne paw, not a touch, to get the wave look.",
                "Keep your gesture consistent so the cue is clear."
              ],
              estimatedDays: 8, prerequisites: ["shake"]),

        Trick(id: "go-around", name: "Go Around", category: .advanced, difficulty: .intermediate,
              icon: "arrow.triangle.turn.up.right.circle.fill",
              summary: "Circle around an object on cue \u{2014} a useful agility and distance skill.",
              steps: [
                "Place a cone, chair, or post in an open space.",
                "Lure your dog around the object and reward on return.",
                "Reduce the lure to a pointing gesture.",
                "Add the cue \u{201C}around.\u{201D}",
                "Send them from increasing distances.",
                "Practice around different objects to generalize."
              ],
              tips: [
                "Reward a full clean loop, not a partial turn.",
                "Great foundation for agility course handling."
              ],
              estimatedDays: 12, prerequisites: ["touch", "come"]),

        Trick(id: "fetch-named-prereq", name: "Object Hold", category: .advanced, difficulty: .intermediate,
              icon: "hand.draw.fill",
              summary: "Take and hold an object calmly \u{2014} the bridge to retrieve-based tricks.",
              steps: [
                "Offer an object and reward any mouth contact.",
                "Reward holding it for a moment before taking it back.",
                "Add the cue \u{201C}hold.\u{201D}",
                "Build duration of the hold gradually.",
                "Pair with \u{201C}drop it\u{201D} for a clean release.",
                "Practice with different objects."
              ],
              tips: [
                "Reward calm holds, not chewing or tossing.",
                "Trade fairly so they're happy to give it back."
              ],
              estimatedDays: 14, prerequisites: ["drop-it"]),

        Trick(id: "tidy-up", name: "Tidy Up Toys", category: .advanced, difficulty: .advanced,
              icon: "shippingbox.fill",
              summary: "Put toys in a basket on cue \u{2014} a genuinely useful party-trick chain.",
              steps: [
                "Teach your dog to hold a toy reliably.",
                "Position a basket and reward holding the toy over it.",
                "Cue \u{201C}drop it\u{201D} so the toy lands in the basket; reward.",
                "Chain: fetch a toy, carry it, drop it in the basket.",
                "Add the cue \u{201C}tidy up.\u{201D}",
                "Build up to clearing several toys in a row."
              ],
              tips: [
                "Reward heavily at the basket so dropping there is the goal.",
                "Use a low, wide basket so success is easy at first."
              ],
              estimatedDays: 30, prerequisites: ["fetch-named-prereq", "fetch"]),

        Trick(id: "go-to-bed", name: "Go to Bed", category: .manners, difficulty: .easy,
              icon: "bed.double.fill",
              summary: "Send your dog to their bed on cue \u{2014} a calm, useful household manner.",
              steps: [
                "Stand near the bed and lure your dog onto it.",
                "Reward all four paws on the bed.",
                "Add the cue \u{201C}go to bed.\u{201D}",
                "Send from a step away, then across the room.",
                "Reward lying down and settling there.",
                "Use it when guests arrive or during meals."
              ],
              tips: [
                "Make the bed rewarding so it's a destination, not a timeout.",
                "Pair with \u{201C}settle\u{201D} for a calm result."
              ],
              estimatedDays: 8, prerequisites: ["place"]),

        Trick(id: "leave-greeting", name: "Polite Greeting", category: .manners, difficulty: .intermediate,
              icon: "person.2.fill",
              summary: "Greet people with four paws on the floor \u{2014} no more jumping up.",
              steps: [
                "Approach a calm helper. Reward your dog for keeping paws down.",
                "If they jump, the person turns away and attention stops.",
                "Reward a sit for greeting.",
                "Practice with the dog on a sit as people approach.",
                "Add mildly exciting greeters as they improve.",
                "Generalize to visitors at your door."
              ],
              tips: [
                "Everyone must follow the same rules \u{2014} consistency is key.",
                "Reward the sit before excitement builds."
              ],
              estimatedDays: 18, prerequisites: ["sit", "settle"]),

        Trick(id: "cross-paws", name: "Cross Paws", category: .tricks, difficulty: .advanced,
              icon: "pawprint.circle.fill",
              summary: "Elegantly cross one paw over the other in a down \u{2014} a refined finishing trick.",
              steps: [
                "Start in a down.",
                "Lure one paw to slide over the other with a treat.",
                "Reward the smallest cross at first.",
                "Add the cue \u{201C}cross.\u{201D}",
                "Shape a fuller, neater crossing.",
                "Build a brief hold for a polished look."
              ],
              tips: [
                "Reward tiny progress \u{2014} this is a precise, shaped behavior.",
                "Keep sessions short to avoid frustration."
              ],
              estimatedDays: 21, prerequisites: ["down", "shake"]),

        Trick(id: "potty-bell", name: "Ring to Go Out", category: .manners, difficulty: .easy,
              icon: "bell.fill",
              summary: "Ring a bell at the door to signal a potty break \u{2014} a tidy house-training aid.",
              steps: [
                "Hang a bell at nose height by the door you use for potty breaks.",
                "Each time you head out, encourage a nose or paw touch to the bell.",
                "Reward the ring, then immediately open the door and go out.",
                "Repeat at every outing so the bell predicts going outside.",
                "Wait for your dog to ring on their own before opening the door.",
                "Only open for genuine potty trips so the bell stays meaningful."
              ],
              tips: [
                "Pair with the \u{201C}touch\u{201D} cue for a fast start.",
                "Don't reward ringing for play \u{2014} keep it tied to potty breaks."
              ],
              estimatedDays: 14, prerequisites: ["touch"]),

        Trick(id: "chin-rest", name: "Chin Rest", category: .basics, difficulty: .intermediate,
              icon: "hand.point.up.braille.fill",
              summary: "Rest the chin in your palm \u{2014} a calm cooperative-care position for grooming and vet checks.",
              steps: [
                "Cup your open hand and let your dog investigate it.",
                "Reward any moment their chin lowers toward your palm.",
                "Build to a light chin rest in your hand and reward the contact.",
                "Add the cue \u{201C}chin.\u{201D}",
                "Slowly extend the duration of the rest.",
                "Practice while gently handling ears or paws to build cooperation."
              ],
              tips: [
                "A relaxed chin rest signals consent \u{2014} stop if they lift away.",
                "Great foundation for stress-free nail trims and exams."
              ],
              estimatedDays: 14, prerequisites: ["touch", "settle"]),

        Trick(id: "jump-hoop", name: "Jump Through a Hoop", category: .advanced, difficulty: .advanced,
              icon: "circle.circle.fill",
              summary: "Leap through a hoop on cue \u{2014} an athletic agility-style showpiece.",
              steps: [
                "Hold a hoop on the ground and lure your dog to step through it.",
                "Reward each pass through the hoop.",
                "Raise the hoop slightly so they step over the bottom edge.",
                "Build to a small hop through the raised hoop.",
                "Add the cue \u{201C}hoop\u{201D} or \u{201C}through.\u{201D}",
                "Keep the height safe and appropriate for their size and joints."
              ],
              tips: [
                "Only jump healthy adult dogs and keep heights modest.",
                "Reward enthusiastically on the far side to build drive."
              ],
              estimatedDays: 21, prerequisites: ["go-around", "come"])
    ]
}
