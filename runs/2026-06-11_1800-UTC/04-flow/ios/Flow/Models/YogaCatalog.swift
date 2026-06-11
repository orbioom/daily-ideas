import Foundation

extension YogaPose {
    static let catalog: [YogaPose] = [
        YogaPose(id: "mountain", name: "Mountain Pose", sanskrit: "Tadasana", category: .standing, emoji: "🏔️", durationSeconds: 30,
                 benefits: ["Improves posture", "Strengthens legs", "Calms the mind"],
                 instructions: ["Stand with feet hip-width apart", "Press all four corners of each foot into the floor", "Lengthen your spine, roll shoulders back and down", "Arms at sides, palms facing forward", "Breathe deeply and find stillness"],
                 breathCue: "Inhale to lengthen, exhale to ground"),
        YogaPose(id: "downdog", name: "Downward Dog", sanskrit: "Adho Mukha Svanasana", category: .standing, emoji: "🐕", durationSeconds: 45,
                 benefits: ["Stretches hamstrings", "Builds arm strength", "Energizes body"],
                 instructions: ["Start on hands and knees", "Tuck toes and lift hips up and back", "Press palms firmly, spread fingers wide", "Lengthen spine, let head hang freely", "Pedal through heels to warm up"],
                 breathCue: "Exhale as you push the floor away"),
        YogaPose(id: "warrior1", name: "Warrior I", sanskrit: "Virabhadrasana I", category: .standing, emoji: "⚔️", durationSeconds: 40,
                 benefits: ["Strengthens legs and core", "Opens hips and chest", "Builds stamina"],
                 instructions: ["Step one foot forward into a lunge", "Back foot at 45 degrees, heel down", "Bend front knee over ankle", "Raise arms overhead, palms together", "Look forward or up, open chest"],
                 breathCue: "Inhale as you rise, breathe steadily"),
        YogaPose(id: "warrior2", name: "Warrior II", sanskrit: "Virabhadrasana II", category: .standing, emoji: "🛡️", durationSeconds: 40,
                 benefits: ["Strengthens legs", "Improves endurance", "Opens hips"],
                 instructions: ["Wide stance, front foot forward", "Back foot perpendicular", "Bend front knee over ankle", "Arms parallel to floor, gaze over front hand", "Keep shoulders over hips"],
                 breathCue: "Breathe into your belly, stay strong"),
        YogaPose(id: "triangle", name: "Triangle Pose", sanskrit: "Trikonasana", category: .standing, emoji: "📐", durationSeconds: 35,
                 benefits: ["Stretches legs and torso", "Improves balance", "Strengthens knees"],
                 instructions: ["Wide stance, front foot forward", "Extend front arm forward then down to shin", "Raise back arm to ceiling", "Look up at your raised hand", "Keep both legs straight and strong"],
                 breathCue: "Inhale to open, exhale to deepen"),
        YogaPose(id: "childspose", name: "Child's Pose", sanskrit: "Balasana", category: .lying, emoji: "🧸", durationSeconds: 60,
                 benefits: ["Releases back tension", "Calms nervous system", "Gentle stretch for hips"],
                 instructions: ["Kneel and sit back on heels", "Fold forward, arms extended or alongside body", "Rest forehead on mat", "Breathe deeply into your back", "Fully surrender your weight"],
                 breathCue: "Let each exhale release more tension"),
        YogaPose(id: "cobra", name: "Cobra Pose", sanskrit: "Bhujangasana", category: .lying, emoji: "🐍", durationSeconds: 30,
                 benefits: ["Opens chest", "Strengthens back", "Improves posture"],
                 instructions: ["Lie on belly, hands under shoulders", "Press tops of feet into mat", "On inhale, lift chest using back muscles", "Keep elbows slightly bent", "Draw shoulders down away from ears"],
                 breathCue: "Inhale to lift, exhale to hold"),
        YogaPose(id: "bridge", name: "Bridge Pose", sanskrit: "Setu Bandhasana", category: .lying, emoji: "🌉", durationSeconds: 45,
                 benefits: ["Strengthens glutes and back", "Opens chest", "Calms the brain"],
                 instructions: ["Lie on back, knees bent, feet hip-width", "Press feet firmly into the floor", "On inhale, lift hips toward ceiling", "Clasp hands under back", "Keep thighs parallel"],
                 breathCue: "Inhale to rise, exhale to hold"),
        YogaPose(id: "pigeon", name: "Pigeon Pose", sanskrit: "Eka Pada Rajakapotasana", category: .seated, emoji: "🕊️", durationSeconds: 60,
                 benefits: ["Deep hip flexor stretch", "Releases glutes", "Emotional release"],
                 instructions: ["From downward dog, bring one knee forward", "Extend back leg behind you", "Square hips toward the front", "Walk hands forward and lower down", "Breathe into the tightness"],
                 breathCue: "Soften with every exhale"),
        YogaPose(id: "seated_twist", name: "Seated Spinal Twist", sanskrit: "Ardha Matsyendrasana", category: .twist, emoji: "🌀", durationSeconds: 40,
                 benefits: ["Improves spinal mobility", "Aids digestion", "Stretches shoulders"],
                 instructions: ["Sit with legs extended", "Bend one knee, cross foot over other leg", "Place opposite elbow outside knee", "Sit tall, then rotate toward bent knee", "Hold and breathe into the twist"],
                 breathCue: "Inhale to lengthen, exhale to twist deeper"),
        YogaPose(id: "camel", name: "Camel Pose", sanskrit: "Ustrasana", category: .backbend, emoji: "🐪", durationSeconds: 30,
                 benefits: ["Opens chest and hip flexors", "Counters desk posture", "Energizing"],
                 instructions: ["Kneel with knees hip-width apart", "Hands on lower back for support", "Gently arch back, opening chest to ceiling", "Option to reach for heels", "Keep neck neutral or gently drop back"],
                 breathCue: "Inhale to open, exhale to deepen"),
        YogaPose(id: "tree", name: "Tree Pose", sanskrit: "Vrksasana", category: .balance, emoji: "🌳", durationSeconds: 45,
                 benefits: ["Improves balance", "Strengthens ankle and core", "Focuses the mind"],
                 instructions: ["Stand on one foot", "Place other foot on inner calf or thigh (not knee)", "Hands at heart or raised overhead", "Fix gaze on a still point", "Breathe calmly and stay rooted"],
                 breathCue: "Root down to rise up"),
        YogaPose(id: "cat_cow", name: "Cat-Cow", sanskrit: "Marjaryasana-Bitilasana", category: .lying, emoji: "🐈", durationSeconds: 60,
                 benefits: ["Warms up the spine", "Improves mobility", "Syncs breath with movement"],
                 instructions: ["On hands and knees, spine neutral", "Inhale: drop belly, lift head (Cow)", "Exhale: round spine, tuck chin (Cat)", "Move slowly and fluidly", "Repeat 5-10 times with breath"],
                 breathCue: "Let breath lead the movement"),
        YogaPose(id: "forward_fold", name: "Standing Forward Fold", sanskrit: "Uttanasana", category: .standing, emoji: "🙇", durationSeconds: 45,
                 benefits: ["Stretches hamstrings", "Releases back tension", "Calms nervous system"],
                 instructions: ["Stand tall, feet hip-width", "Hinge at hips, fold forward", "Let head and arms hang heavy", "Slight bend in knees if needed", "Shift weight toward balls of feet"],
                 breathCue: "Exhale deeper into the fold"),
        YogaPose(id: "legs_up_wall", name: "Legs Up Wall", sanskrit: "Viparita Karani", category: .inversion, emoji: "🦵", durationSeconds: 120,
                 benefits: ["Relieves tired legs", "Calms nervous system", "Reduces anxiety"],
                 instructions: ["Sit sideways close to a wall", "Swing legs up as you lower back down", "Rest legs up the wall, arms out to sides", "Close eyes and breathe", "Stay 2-5 minutes"],
                 breathCue: "Simply breathe and let go"),
        YogaPose(id: "savasana", name: "Savasana", sanskrit: "Savasana", category: .restorative, emoji: "✨", durationSeconds: 180,
                 benefits: ["Deep rest", "Integration of practice", "Reduces stress"],
                 instructions: ["Lie completely flat on your back", "Arms slightly away from sides, palms up", "Feet fall apart naturally", "Close eyes, let body be completely heavy", "Release all effort and rest"],
                 breathCue: "Nothing to do, nowhere to go"),
        YogaPose(id: "supine_twist", name: "Supine Twist", sanskrit: "Supta Matsyendrasana", category: .twist, emoji: "🌙", durationSeconds: 60,
                 benefits: ["Releases lower back", "Massages internal organs", "Deeply relaxing"],
                 instructions: ["Lie on your back", "Draw one knee to chest", "Cross knee to opposite side", "Open arm to the side, look away", "Breathe and let gravity do the work"],
                 breathCue: "Release on every exhale"),
        YogaPose(id: "low_lunge", name: "Low Lunge", sanskrit: "Anjaneyasana", category: .standing, emoji: "🏃", durationSeconds: 45,
                 benefits: ["Stretches hip flexors", "Opens chest", "Builds strength"],
                 instructions: ["Step one foot forward", "Lower back knee to mat", "Sink hips forward and down", "Raise arms overhead", "Keep front shin perpendicular to floor"],
                 breathCue: "Inhale to reach up, exhale to sink"),
        YogaPose(id: "happy_baby", name: "Happy Baby", sanskrit: "Ananda Balasana", category: .lying, emoji: "👶", durationSeconds: 60,
                 benefits: ["Releases hips and lower back", "Playful and joyful", "Calming"],
                 instructions: ["Lie on back", "Draw knees to chest", "Grab outer edges of feet", "Open knees toward armpits", "Rock side to side gently"],
                 breathCue: "Let yourself be playful and loose"),
        YogaPose(id: "seated_forward", name: "Seated Forward Bend", sanskrit: "Paschimottanasana", category: .seated, emoji: "🧘", durationSeconds: 60,
                 benefits: ["Stretches entire back body", "Calms the mind", "Lengthens spine"],
                 instructions: ["Sit with legs extended", "Flex feet, sit tall", "Hinge forward from hips", "Reach for feet or shins", "Let back round naturally"],
                 breathCue: "Melt forward on each exhale")
    ]

    static func pose(id: String) -> YogaPose? {
        catalog.first { $0.id == id }
    }
}

extension YogaSession {
    static func makeStep(_ poseId: String, duration: Int? = nil, side: SessionStep.StepSide = .both, cue: String = "") -> SessionStep {
        guard let pose = YogaPose.pose(id: poseId) else {
            fatalError("Unknown pose id: \(poseId)")
        }
        return SessionStep(
            id: UUID(),
            pose: pose,
            durationSeconds: duration ?? pose.durationSeconds,
            isTransition: false,
            cue: cue.isEmpty ? pose.breathCue : cue,
            side: side
        )
    }

    static let catalog: [YogaSession] = [
        YogaSession(
            id: "morning_flow",
            name: "Morning Flow",
            description: "Wake up your body and set a positive tone for the day.",
            difficulty: .beginner,
            focus: .morning,
            emoji: "🌅",
            gradientColors: ["F9A826", "F76B1C"],
            steps: [
                makeStep("cat_cow", duration: 60),
                makeStep("downdog", duration: 45),
                makeStep("forward_fold"),
                makeStep("mountain", duration: 30),
                makeStep("warrior1", side: .left),
                makeStep("warrior1", side: .right),
                makeStep("warrior2", side: .left),
                makeStep("warrior2", side: .right),
                makeStep("downdog", duration: 30),
                makeStep("childspose", duration: 60),
                makeStep("savasana", duration: 60)
            ]
        ),
        YogaSession(
            id: "evening_wind_down",
            name: "Evening Wind Down",
            description: "Release the day's tension and prepare for restful sleep.",
            difficulty: .beginner,
            focus: .evening,
            emoji: "🌙",
            gradientColors: ["4A00E0", "8E2DE2"],
            steps: [
                makeStep("cat_cow"),
                makeStep("childspose"),
                makeStep("seated_forward"),
                makeStep("supine_twist", side: .left),
                makeStep("supine_twist", side: .right),
                makeStep("happy_baby"),
                makeStep("legs_up_wall"),
                makeStep("savasana")
            ]
        ),
        YogaSession(
            id: "core_power",
            name: "Core Power",
            description: "Build core strength and stability from the inside out.",
            difficulty: .intermediate,
            focus: .core,
            emoji: "💪",
            gradientColors: ["FF416C", "FF4B2B"],
            steps: [
                makeStep("cat_cow", duration: 90),
                makeStep("downdog", duration: 60),
                makeStep("low_lunge", side: .left),
                makeStep("low_lunge", side: .right),
                makeStep("warrior1", side: .left),
                makeStep("warrior1", side: .right),
                makeStep("warrior2", side: .left),
                makeStep("warrior2", side: .right),
                makeStep("bridge", duration: 60),
                makeStep("childspose"),
                makeStep("savasana", duration: 90)
            ]
        ),
        YogaSession(
            id: "deep_stretch",
            name: "Deep Flexibility",
            description: "Melt into long holds that open up tight areas.",
            difficulty: .beginner,
            focus: .flexibility,
            emoji: "🌿",
            gradientColors: ["11998E", "38EF7D"],
            steps: [
                makeStep("cat_cow"),
                makeStep("downdog", duration: 90),
                makeStep("pigeon", side: .left, duration: 90),
                makeStep("pigeon", side: .right, duration: 90),
                makeStep("seated_twist", side: .left),
                makeStep("seated_twist", side: .right),
                makeStep("seated_forward", duration: 90),
                makeStep("supine_twist", side: .left),
                makeStep("supine_twist", side: .right),
                makeStep("happy_baby"),
                makeStep("savasana")
            ]
        ),
        YogaSession(
            id: "balance_focus",
            name: "Balance & Focus",
            description: "Cultivate steady concentration through challenging poses.",
            difficulty: .intermediate,
            focus: .balance,
            emoji: "🎯",
            gradientColors: ["5C258D", "4389A2"],
            steps: [
                makeStep("mountain", duration: 60),
                makeStep("tree", side: .left),
                makeStep("tree", side: .right),
                makeStep("warrior1", side: .left),
                makeStep("warrior2", side: .left),
                makeStep("triangle", side: .left),
                makeStep("warrior1", side: .right),
                makeStep("warrior2", side: .right),
                makeStep("triangle", side: .right),
                makeStep("forward_fold"),
                makeStep("savasana", duration: 90)
            ]
        ),
        YogaSession(
            id: "stress_relief",
            name: "Stress Relief",
            description: "Slow down, breathe deeply, and release anxious energy.",
            difficulty: .beginner,
            focus: .stress,
            emoji: "☮️",
            gradientColors: ["348F50", "56B4D3"],
            steps: [
                makeStep("childspose", duration: 90),
                makeStep("cat_cow", duration: 90),
                makeStep("seated_twist", side: .left),
                makeStep("seated_twist", side: .right),
                makeStep("bridge"),
                makeStep("supine_twist", side: .left),
                makeStep("supine_twist", side: .right),
                makeStep("happy_baby"),
                makeStep("legs_up_wall"),
                makeStep("savasana")
            ]
        ),
        YogaSession(
            id: "backbend_flow",
            name: "Heart Opening",
            description: "Counteract forward hunching with chest and back openers.",
            difficulty: .intermediate,
            focus: .flexibility,
            emoji: "💚",
            gradientColors: ["F7971E", "FFD200"],
            steps: [
                makeStep("cat_cow"),
                makeStep("cobra", duration: 45),
                makeStep("downdog"),
                makeStep("low_lunge", side: .left),
                makeStep("low_lunge", side: .right),
                makeStep("camel"),
                makeStep("bridge", duration: 60),
                makeStep("childspose", duration: 90),
                makeStep("supine_twist", side: .left),
                makeStep("supine_twist", side: .right),
                makeStep("savasana")
            ]
        ),
        YogaSession(
            id: "quick_wake_up",
            name: "Quick Wake-Up",
            description: "10 minutes to get you moving and energised.",
            difficulty: .beginner,
            focus: .morning,
            emoji: "⚡️",
            gradientColors: ["FC5C7D", "6A82FB"],
            steps: [
                makeStep("cat_cow", duration: 60),
                makeStep("downdog", duration: 45),
                makeStep("warrior1", side: .left, duration: 30),
                makeStep("warrior1", side: .right, duration: 30),
                makeStep("forward_fold"),
                makeStep("mountain"),
                makeStep("savasana", duration: 60)
            ]
        )
    ]
}
