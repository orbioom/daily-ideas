import SwiftData
import Foundation

enum SparSeeder {
    static func seed(context: ModelContext) {
        let desc = FetchDescriptor<TrainingSession>()
        guard (try? context.fetch(desc))?.isEmpty == true else { return }

        let calendar = Calendar.current
        let now = Date()

        // Seed default fighter
        let fighter = Fighter(name: "You", discipline: .boxing, weightClass: .welterweight,
                              stance: "Orthodox", trainingYears: 2, beltOrRank: "Amateur")
        context.insert(fighter)

        // Seed 55 training sessions
        let sessionTemplates: [(SessionType, Int, Int, SessionIntensity)] = [
            (.shadowBoxing, 45, 6, .moderate),
            (.bagWork, 60, 8, .hard),
            (.padWork, 45, 6, .hard),
            (.sparring, 60, 5, .veryHard),
            (.conditioning, 30, 0, .hard),
            (.drills, 40, 0, .moderate),
            (.mitts, 35, 5, .hard),
            (.technicalDrills, 45, 0, .light),
        ]

        let focusOptions = [
            "Jab-cross combinations", "Body shots", "Head movement", "Footwork",
            "Counter-punching", "Defense and slipping", "Power shots", "Combination flow",
            "Lead hook technique", "Overhand right", "Inside fighting", "Southpaw counter",
            "", ""
        ]

        for i in 0..<55 {
            let daysAgo = Double(i) * 2.8 + Double.random(in: 0...1.5)
            let date = calendar.date(byAdding: .day, value: -Int(daysAgo), to: now) ?? now
            let t = sessionTemplates[i % sessionTemplates.count]
            let s = TrainingSession(
                date: date,
                sessionType: t.0,
                durationMinutes: t.1 + Int.random(in: -10...15),
                rounds: t.2,
                roundDurationSeconds: 180,
                intensity: t.3,
                focusAreas: focusOptions[i % focusOptions.count],
                notes: i % 9 == 0 ? "Great session today, felt sharp" : i % 13 == 0 ? "Tired, short on sleep" : "",
                mood: Int.random(in: 2...5),
                partnerName: i % 4 == 0 ? "Coach Mike" : i % 7 == 0 ? "Training partner" : ""
            )
            context.insert(s)
        }

        // Seed 35 techniques
        let techniques: [(String, TechniqueCategory, String, MasteryLevel)] = [
            ("Jab", .punch, "Lead-hand straight punch; used to set up combinations and gauge distance", .proficient),
            ("Cross (Straight Right)", .punch, "Rear-hand power punch thrown straight to the opponent's chin", .proficient),
            ("Lead Hook", .punch, "Short hook with lead hand targeting the jaw or temple", .competent),
            ("Rear Hook", .punch, "Power hook with rear hand, used as a follow-up to the jab-cross", .competent),
            ("Uppercut", .punch, "Rising punch aimed at chin or solar plexus; best at close range", .developing),
            ("Body Jab", .punch, "Jab aimed at the body to lower opponent's guard", .competent),
            ("Body Cross", .punch, "Rear-hand power shot to the ribs or solar plexus", .developing),
            ("Overhand Right", .punch, "Looping rear-hand punch over an opponent's guard", .developing),
            ("Lead Body Hook", .punch, "Left hook to the body; effective off a jab feint", .learning),
            ("Southpaw Jab", .punch, "Lead-hand jab from southpaw stance", .learning),
            ("Roundhouse Kick", .kick, "Wide-arc kick using the shin; targets body or head", .developing),
            ("Front Kick (Teep)", .kick, "Push kick to body using ball of foot; keeps distance", .competent),
            ("Low Kick (Calf Kick)", .kick, "Shin kick to the lower leg / calf muscle", .developing),
            ("Sidekick", .kick, "Thrust kick using the heel, targeting midsection", .learning),
            ("Back Kick", .kick, "Spinning rear-thrust kick; powerful when timed correctly", .learning),
            ("Switch Kick", .kick, "Stance switch before throwing a kick to add power", .learning),
            ("Horizontal Elbow", .elbow, "Slashing elbow at close range targeting the temple", .developing),
            ("Upward Elbow", .elbow, "Rising elbow aimed at the chin in the clinch", .learning),
            ("Rear Knee", .knee, "Rear-leg knee thrust to the midsection or thighs", .developing),
            ("Flying Knee", .knee, "Jump-driven knee strike; used as a surprise attack", .learning),
            ("Clinch Knee", .knee, "Multiple knees in the clinch to break opponent's posture", .developing),
            ("Slip Outside", .defense, "Lateral head movement to the outside of a jab", .proficient),
            ("Slip Inside", .defense, "Head movement to the inside to counter with body shots", .competent),
            ("Roll Under Hook", .defense, "Rolling under a hook to come up on the inside", .developing),
            ("Parry", .defense, "Redirecting a jab with your lead palm", .competent),
            ("High Guard", .defense, "Tight guard protecting the head; absorb and counter", .proficient),
            ("Cross Guard", .defense, "Cross-arm guard to protect against hooks and power shots", .competent),
            ("Pivot", .footwork, "Rotating on the lead foot to change angle", .competent),
            ("Lateral Step", .footwork, "Stepping to the side to create angles and avoid counters", .proficient),
            ("Cut Angle", .footwork, "Cutting to the side of opponent's rear hand", .developing),
            ("Southpaw Puzzle", .footwork, "Footwork strategy against a southpaw opponent", .learning),
            ("Collar Tie", .clinch, "Controlling opponent's head with collar grip to deliver knees", .developing),
            ("Double Collar", .clinch, "Both hands behind opponent's neck for knee strikes", .learning),
            ("Jab-Cross-Hook", .combo, "Classic 1-2-3 combination; the foundation of boxing", .proficient),
            ("Jab-Cross-Body Hook", .combo, "1-2 upstairs followed by a left hook to the body", .competent),
        ]

        for (name, cat, detail, mastery) in techniques {
            let practiceCount = max(0, mastery.rawValue * 8 + Int.random(in: -5...10))
            let t = Technique(name: name, category: cat, details: detail, mastery: mastery,
                              practiceCount: practiceCount, isCustom: false)
            t.isFavorite = mastery.rawValue >= 4
            context.insert(t)
        }

        // Seed 8 fight records
        let fightData: [(String, FightResult, FightMethod, Bool)] = [
            ("Alex Martinez", .win, .decision, true),
            ("Chris Thompson", .loss, .ko, true),
            ("Jordan Kim", .win, .unanimous, true),
            ("Ryan O'Brien", .draw, .decision, true),
            ("Sam Wilson", .win, .decision, false),
            ("Mike Santos", .win, .unanimous, false),
            ("David Lee", .loss, .split, false),
            ("Tom Harris", .win, .ko, false),
        ]

        for (i, (opp, result, method, isAmateur)) in fightData.enumerated() {
            let daysAgo = (i + 1) * 45 + Int.random(in: 0...15)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let f = FightRecord(
                date: date,
                opponent: opp,
                event: isAmateur ? "Local Amateur Card" : "Regional Boxing Show",
                result: result,
                method: method,
                round: Int.random(in: 1...4),
                roundTime: "",
                discipline: .boxing,
                notes: "",
                isAmateur: isAmateur
            )
            context.insert(f)
        }

        try? context.save()
    }
}
