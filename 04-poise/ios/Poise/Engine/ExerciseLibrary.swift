import Foundation

enum ExerciseCategory: String, CaseIterable, Identifiable {
    case neck = "Neck"
    case shoulders = "Shoulders"
    case eyes = "Eyes"
    case wrists = "Wrists"
    case back = "Back"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .neck: return "person.bust"
        case .shoulders: return "figure.arms.open"
        case .eyes: return "eye"
        case .wrists: return "hand.raised"
        case .back: return "figure.flexibility"
        }
    }

    var color: String {
        switch self {
        case .neck: return "sky"
        case .shoulders: return "teal"
        case .eyes: return "purple"
        case .wrists: return "orange"
        case .back: return "green"
        }
    }
}

struct Exercise: Identifiable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let durationSeconds: Int
    let instruction: String
    let benefits: String
    let steps: [String]
    let sfSymbol: String
}

struct ExerciseLibrary {
    static let all: [Exercise] = neck + shoulders + eyes + wrists + back

    static func exercises(for categories: [String]) -> [Exercise] {
        all.filter { exercise in
            categories.contains(exercise.category.rawValue.lowercased())
        }
    }

    static func randomSession(categories: [String], durationSeconds: Int) -> [Exercise] {
        let pool = exercises(for: categories).shuffled()
        var result: [Exercise] = []
        var totalTime = 0
        for exercise in pool {
            if totalTime + exercise.durationSeconds <= durationSeconds {
                result.append(exercise)
                totalTime += exercise.durationSeconds
            }
            if totalTime >= durationSeconds { break }
        }
        if result.isEmpty, let first = pool.first {
            result = [first]
        }
        return result
    }

    // MARK: - Neck (6 exercises)
    static let neck: [Exercise] = [
        Exercise(
            id: "neck_chin_tuck",
            name: "Chin Tuck",
            category: .neck,
            durationSeconds: 20,
            instruction: "Gently pull your chin straight back, creating a 'double chin'. Hold briefly, then release.",
            benefits: "Strengthens deep neck flexors, reduces forward head posture and text neck.",
            steps: [
                "Sit tall with shoulders relaxed",
                "Looking straight ahead, gently draw your chin straight back",
                "Feel a gentle stretch at the back of your neck",
                "Hold for 3 seconds, then slowly release",
                "Repeat 5–8 times"
            ],
            sfSymbol: "person.bust"
        ),
        Exercise(
            id: "neck_side_tilt_left",
            name: "Neck Side Tilt Left",
            category: .neck,
            durationSeconds: 15,
            instruction: "Slowly tilt your head toward your left shoulder until you feel a gentle stretch on the right side of your neck.",
            benefits: "Releases tension in the upper trapezius and lateral neck muscles.",
            steps: [
                "Sit upright, shoulders down and relaxed",
                "Slowly tilt your left ear toward your left shoulder",
                "Do not rotate — keep your nose pointing forward",
                "Feel the stretch along the right side of your neck",
                "Hold for 10–15 seconds, breathing steadily"
            ],
            sfSymbol: "arrow.left"
        ),
        Exercise(
            id: "neck_side_tilt_right",
            name: "Neck Side Tilt Right",
            category: .neck,
            durationSeconds: 15,
            instruction: "Slowly tilt your head toward your right shoulder until you feel a gentle stretch on the left side of your neck.",
            benefits: "Balances left-side tilt stretch, releases lateral neck and scalene muscles.",
            steps: [
                "Sit upright, shoulders down and relaxed",
                "Slowly tilt your right ear toward your right shoulder",
                "Keep your nose pointing forward — no rotation",
                "Feel the stretch along the left side of your neck",
                "Hold for 10–15 seconds, breathing steadily"
            ],
            sfSymbol: "arrow.right"
        ),
        Exercise(
            id: "neck_forward_tilt",
            name: "Neck Forward Tilt",
            category: .neck,
            durationSeconds: 15,
            instruction: "Gently lower your chin toward your chest to stretch the back of your neck.",
            benefits: "Stretches posterior neck muscles and the cervical spine's extensor muscles.",
            steps: [
                "Sit upright with shoulders relaxed",
                "Slowly lower your chin toward your chest",
                "Feel a stretch at the back of your neck and upper back",
                "Do not force or bounce — let gravity guide you",
                "Hold for 10–15 seconds"
            ],
            sfSymbol: "arrow.down"
        ),
        Exercise(
            id: "neck_rotation_left",
            name: "Neck Rotation Left",
            category: .neck,
            durationSeconds: 15,
            instruction: "Slowly turn your head to look over your left shoulder as far as is comfortable.",
            benefits: "Improves cervical rotation range of motion, releases sternocleidomastoid tension.",
            steps: [
                "Sit tall, chin level with the floor",
                "Slowly rotate your head to look over your left shoulder",
                "Keep your shoulders still and squared forward",
                "Hold at your comfortable end range for 5 seconds",
                "Return to center slowly, then repeat"
            ],
            sfSymbol: "arrow.counterclockwise"
        ),
        Exercise(
            id: "neck_rotation_right",
            name: "Neck Rotation Right",
            category: .neck,
            durationSeconds: 15,
            instruction: "Slowly turn your head to look over your right shoulder as far as is comfortable.",
            benefits: "Mirrors left rotation, ensuring balanced cervical mobility.",
            steps: [
                "Sit tall, chin level with the floor",
                "Slowly rotate your head to look over your right shoulder",
                "Keep your shoulders still and squared forward",
                "Hold at your comfortable end range for 5 seconds",
                "Return to center slowly, then repeat"
            ],
            sfSymbol: "arrow.clockwise"
        ),
    ]

    // MARK: - Shoulders (6 exercises)
    static let shoulders: [Exercise] = [
        Exercise(
            id: "shoulder_rolls_forward",
            name: "Shoulder Rolls Forward",
            category: .shoulders,
            durationSeconds: 20,
            instruction: "Roll both shoulders forward in large, slow circles to release tension and increase circulation.",
            benefits: "Loosens the shoulder girdle, reduces trapezius tightness from prolonged desk work.",
            steps: [
                "Sit or stand with arms relaxed at your sides",
                "Lift both shoulders up toward your ears",
                "Roll them forward and down in a smooth circle",
                "Complete 5 full forward rotations at a slow pace",
                "Focus on making the circles as large as comfortable"
            ],
            sfSymbol: "arrow.2.circlepath"
        ),
        Exercise(
            id: "shoulder_rolls_back",
            name: "Shoulder Rolls Back",
            category: .shoulders,
            durationSeconds: 20,
            instruction: "Roll both shoulders backward in large, slow circles — opposite direction from forward rolls.",
            benefits: "Counteracts rounded-shoulder posture by activating the rhomboids and middle trapezius.",
            steps: [
                "Sit or stand with arms relaxed at your sides",
                "Lift both shoulders up toward your ears",
                "Roll them back and down in a smooth circle",
                "Complete 5 full backward rotations",
                "Squeeze your shoulder blades together at the back of each roll"
            ],
            sfSymbol: "arrow.2.circlepath"
        ),
        Exercise(
            id: "cross_body_left",
            name: "Cross-Body Stretch Left",
            category: .shoulders,
            durationSeconds: 30,
            instruction: "Bring your left arm across your chest and use your right hand to gently deepen the stretch.",
            benefits: "Stretches the posterior deltoid and rotator cuff; relieves tension from mousing.",
            steps: [
                "Extend your left arm straight out",
                "Bring it across your chest at shoulder height",
                "Place your right hand on the outside of your left elbow",
                "Gently draw your left arm closer to your chest",
                "Hold for 25–30 seconds, breathing slowly"
            ],
            sfSymbol: "arrow.left.and.right.righttriangle.left.righttriangle.right"
        ),
        Exercise(
            id: "cross_body_right",
            name: "Cross-Body Stretch Right",
            category: .shoulders,
            durationSeconds: 30,
            instruction: "Bring your right arm across your chest and use your left hand to gently deepen the stretch.",
            benefits: "Mirrors left cross-body stretch for balanced posterior shoulder release.",
            steps: [
                "Extend your right arm straight out",
                "Bring it across your chest at shoulder height",
                "Place your left hand on the outside of your right elbow",
                "Gently draw your right arm closer to your chest",
                "Hold for 25–30 seconds, breathing slowly"
            ],
            sfSymbol: "arrow.left.and.right.righttriangle.left.righttriangle.right"
        ),
        Exercise(
            id: "chest_opener",
            name: "Chest Opener",
            category: .shoulders,
            durationSeconds: 30,
            instruction: "Clasp hands behind your back, straighten arms, and lift them slightly while opening your chest forward.",
            benefits: "Stretches pectoralis major and minor; directly counteracts forward-hunched desk posture.",
            steps: [
                "Sit up straight at the edge of your chair",
                "Clasp your hands together behind your lower back",
                "Straighten your arms as much as comfortable",
                "Gently lift your clasped hands away from your body",
                "Roll your shoulders back and open your chest — hold 20–25 seconds"
            ],
            sfSymbol: "figure.arms.open"
        ),
        Exercise(
            id: "shoulder_blade_squeeze",
            name: "Shoulder Blade Squeeze",
            category: .shoulders,
            durationSeconds: 20,
            instruction: "Draw your shoulder blades together and hold, as if you are trying to hold a pencil between them.",
            benefits: "Activates rhomboids and mid-trapezius; reverses the constant shoulder protraction of typing.",
            steps: [
                "Sit tall with arms at your sides or resting on your lap",
                "Take a breath in, then as you exhale, draw both shoulder blades toward each other",
                "Hold the squeeze for 5 seconds",
                "Slowly release and let shoulders return to neutral",
                "Repeat 8–10 times"
            ],
            sfSymbol: "arrow.up.backward.and.arrow.down.forward"
        ),
    ]

    // MARK: - Eyes (6 exercises)
    static let eyes: [Exercise] = [
        Exercise(
            id: "eyes_20_20_20",
            name: "20-20-20 Look",
            category: .eyes,
            durationSeconds: 20,
            instruction: "Look at something at least 20 feet away for 20 seconds to relax your eye muscles.",
            benefits: "Reduces digital eye strain by allowing ciliary muscles to fully relax from near-focus.",
            steps: [
                "Stop looking at your screen",
                "Find a point at least 20 feet (6 meters) away",
                "Softly focus on that distant point",
                "Blink naturally — don't stare rigidly",
                "Hold for the full 20 seconds"
            ],
            sfSymbol: "eye"
        ),
        Exercise(
            id: "eyes_circles_left",
            name: "Eye Circles Left",
            category: .eyes,
            durationSeconds: 15,
            instruction: "Slowly move your eyes in large counterclockwise circles without moving your head.",
            benefits: "Exercises all six extraocular muscles; improves coordination and reduces fatigue.",
            steps: [
                "Close your eyes briefly and take a breath",
                "Open your eyes and keep your head still",
                "Slowly move your gaze in a large circle to the left (counterclockwise)",
                "Go as far as comfortable in each direction: up, left, down, right",
                "Complete 3–4 full circles slowly"
            ],
            sfSymbol: "arrow.counterclockwise.circle"
        ),
        Exercise(
            id: "eyes_circles_right",
            name: "Eye Circles Right",
            category: .eyes,
            durationSeconds: 15,
            instruction: "Slowly move your eyes in large clockwise circles without moving your head.",
            benefits: "Complements left-direction circles for complete extraocular muscle balance.",
            steps: [
                "Keep your head still and face forward",
                "Slowly move your gaze in a large circle to the right (clockwise)",
                "Go far: right, up, left, down — making the circle as large as comfortable",
                "Move slowly and smoothly, no jerking",
                "Complete 3–4 full circles"
            ],
            sfSymbol: "arrow.clockwise.circle"
        ),
        Exercise(
            id: "eyes_palming",
            name: "Eye Palming",
            category: .eyes,
            durationSeconds: 30,
            instruction: "Cup your palms over your eyes (without pressing) and let your eyes relax in the warmth and darkness.",
            benefits: "Deeply relaxes the eyes and optic nerves; reduces photosensitivity from screen glare.",
            steps: [
                "Rub your palms together briskly for 5 seconds to generate warmth",
                "Cup your palms gently over your closed eyes",
                "Do not press on your eyelids — just let warmth radiate",
                "Breathe slowly and let your eyes completely relax",
                "Hold for 25–30 seconds in the darkness"
            ],
            sfSymbol: "hand.raised.fill"
        ),
        Exercise(
            id: "eyes_near_far",
            name: "Near-Far Focus",
            category: .eyes,
            durationSeconds: 30,
            instruction: "Alternate focus between your thumb held close and a distant object to exercise the focusing muscles.",
            benefits: "Trains accommodative flexibility — the ability to quickly shift focus between distances.",
            steps: [
                "Hold your thumb about 10 inches from your face",
                "Focus clearly on your thumbprint for 3 seconds",
                "Then quickly shift focus to something 15+ feet away",
                "Hold that far focus for 3 seconds",
                "Alternate 5–6 times without rushing"
            ],
            sfSymbol: "arrow.up.left.and.arrow.down.right"
        ),
        Exercise(
            id: "eyes_blink",
            name: "Blink Exercise",
            category: .eyes,
            durationSeconds: 15,
            instruction: "Consciously blink slowly and fully — many people blink far less than normal while reading screens.",
            benefits: "Refreshes the tear film, prevents dry eye and blurry vision from screen work.",
            steps: [
                "Look straight ahead, eyes relaxed",
                "Blink slowly and deliberately, fully closing your eyes each time",
                "Hold each blink for half a second before reopening",
                "Blink 10–15 times at a slow, intentional pace",
                "Notice how much clearer your vision feels afterward"
            ],
            sfSymbol: "eye.slash"
        ),
    ]

    // MARK: - Wrists (6 exercises)
    static let wrists: [Exercise] = [
        Exercise(
            id: "wrist_flexion",
            name: "Wrist Flexion Stretch",
            category: .wrists,
            durationSeconds: 20,
            instruction: "Extend one arm, palm up, and gently bend your wrist downward using your other hand.",
            benefits: "Stretches wrist extensors and forearm muscles tightened by keyboard/mouse use.",
            steps: [
                "Extend your right arm in front of you with palm facing up",
                "Use your left hand to gently bend your right wrist downward",
                "Feel the stretch along the top of your forearm",
                "Hold for 10 seconds, keeping your elbow straight",
                "Switch arms and repeat"
            ],
            sfSymbol: "hand.point.down"
        ),
        Exercise(
            id: "wrist_extension",
            name: "Wrist Extension Stretch",
            category: .wrists,
            durationSeconds: 20,
            instruction: "Extend one arm with palm facing down and gently bend your wrist upward using your other hand.",
            benefits: "Stretches wrist flexors; prevents and alleviates repetitive strain injury.",
            steps: [
                "Extend your right arm in front of you with palm facing down",
                "Use your left hand to gently bend your right wrist upward",
                "Feel the stretch along the underside of your forearm",
                "Hold for 10 seconds, elbow straight",
                "Switch arms and repeat"
            ],
            sfSymbol: "hand.point.up"
        ),
        Exercise(
            id: "wrist_circles",
            name: "Wrist Circles",
            category: .wrists,
            durationSeconds: 20,
            instruction: "Interlace your fingers and slowly rotate both wrists in large circles, first one direction then the other.",
            benefits: "Increases synovial fluid circulation in the wrist joint; improves range of motion.",
            steps: [
                "Extend both arms in front of you",
                "Interlace your fingers loosely",
                "Rotate your wrists in slow clockwise circles — 5 rotations",
                "Then rotate counterclockwise — 5 rotations",
                "Make the circles as large and smooth as possible"
            ],
            sfSymbol: "arrow.2.circlepath"
        ),
        Exercise(
            id: "prayer_stretch",
            name: "Prayer Stretch",
            category: .wrists,
            durationSeconds: 20,
            instruction: "Press palms together in front of your chest, fingers pointing up, and slowly lower your hands toward your waist.",
            benefits: "Deeply stretches wrist flexors and the carpal tunnel area.",
            steps: [
                "Press your palms together in front of your chest with fingers pointing up",
                "Keep palms pressed together and slowly lower them toward your waist",
                "Feel the stretch increasing in your wrists as you lower",
                "Hold at the point of comfortable tension for 15 seconds",
                "Slowly raise back to starting position"
            ],
            sfSymbol: "hand.raised"
        ),
        Exercise(
            id: "finger_spread",
            name: "Finger Spread",
            category: .wrists,
            durationSeconds: 15,
            instruction: "Spread all five fingers as wide as possible, hold briefly, then make a loose fist. Alternate rapidly.",
            benefits: "Activates intrinsic hand muscles; reduces fatigue from constant key-pressing.",
            steps: [
                "Hold both hands out in front of you",
                "Spread all fingers as wide and as far apart as possible",
                "Hold the spread for 3 seconds",
                "Then loosely curl into a relaxed fist",
                "Alternate spread and fist 8–10 times"
            ],
            sfSymbol: "hand.raised.fingers.spread"
        ),
        Exercise(
            id: "wrist_shake",
            name: "Wrist Shake",
            category: .wrists,
            durationSeconds: 15,
            instruction: "Let your hands hang relaxed and shake them loosely from the wrists, as if shaking off water.",
            benefits: "Releases built-up tension and promotes blood flow to fingers and forearms.",
            steps: [
                "Let your arms hang down or extend loosely in front of you",
                "Relax your hands and fingers completely",
                "Shake your hands loosely from the wrists, like shaking off water",
                "Let them flop and shake freely for 10–15 seconds",
                "Notice the release of tension and warmth returning to your fingers"
            ],
            sfSymbol: "waveform.path"
        ),
    ]

    // MARK: - Back (5 exercises)
    static let back: [Exercise] = [
        Exercise(
            id: "back_cat_cow",
            name: "Seated Cat-Cow",
            category: .back,
            durationSeconds: 30,
            instruction: "Alternately arch and round your lower back while seated, synchronizing movement with your breath.",
            benefits: "Mobilizes the entire spine; counters the static compression of sitting.",
            steps: [
                "Sit at the edge of your chair, feet flat on the floor, hands on thighs",
                "Inhale: arch your lower back, lift your chest and chin slightly (cow)",
                "Exhale: round your back, tuck your chin, and draw your navel in (cat)",
                "Move smoothly between the two positions",
                "Complete 6–8 full breath cycles"
            ],
            sfSymbol: "figure.flexibility"
        ),
        Exercise(
            id: "back_twist_left",
            name: "Seated Twist Left",
            category: .back,
            durationSeconds: 20,
            instruction: "Sit tall and rotate your torso to the left, using the back of your chair or your right hand for leverage.",
            benefits: "Rotates the thoracic spine; relieves compression from hours of forward-facing posture.",
            steps: [
                "Sit upright with feet flat on the floor",
                "Place your right hand on your left knee",
                "Inhale to lengthen your spine",
                "Exhale and gently rotate your torso to the left, looking over your left shoulder",
                "Hold for 15–20 seconds, breathing into the twist"
            ],
            sfSymbol: "arrow.counterclockwise"
        ),
        Exercise(
            id: "back_twist_right",
            name: "Seated Twist Right",
            category: .back,
            durationSeconds: 20,
            instruction: "Sit tall and rotate your torso to the right, using the back of your chair or your left hand for leverage.",
            benefits: "Mirrors left rotation for balanced thoracic mobility and detoxifying spinal compression.",
            steps: [
                "Sit upright with feet flat on the floor",
                "Place your left hand on your right knee",
                "Inhale to lengthen your spine",
                "Exhale and gently rotate your torso to the right, looking over your right shoulder",
                "Hold for 15–20 seconds, breathing into the twist"
            ],
            sfSymbol: "arrow.clockwise"
        ),
        Exercise(
            id: "back_forward_fold",
            name: "Seated Forward Fold",
            category: .back,
            durationSeconds: 30,
            instruction: "Hinge forward from your hips with a long spine, letting your torso drape toward your thighs.",
            benefits: "Lengthens the entire posterior chain; decompresses lumbar vertebrae.",
            steps: [
                "Sit at the edge of your chair, feet hip-width apart",
                "Place hands on your thighs",
                "Inhale to lengthen your spine",
                "Exhale and hinge forward from your hips, keeping your back as flat as possible initially",
                "Let your torso drape forward, hands reaching toward the floor — hold 25 seconds"
            ],
            sfSymbol: "arrow.down.circle"
        ),
        Exercise(
            id: "back_hip_flexor",
            name: "Seated Hip Flexor Release",
            category: .back,
            durationSeconds: 30,
            instruction: "Sit tall at the edge of your seat, bring one knee up, then lower it down and back to stretch the front of the hip.",
            benefits: "Counteracts hip flexor shortening from prolonged sitting; reduces lower back strain.",
            steps: [
                "Sit tall at the front edge of your chair",
                "Slide your right foot back so your right knee is behind your hip",
                "Gently press your right knee toward the floor while keeping your torso upright",
                "Feel the stretch at the front of your right hip",
                "Hold for 20–25 seconds, then switch sides"
            ],
            sfSymbol: "figure.seated.seatbelt"
        ),
    ]
}
