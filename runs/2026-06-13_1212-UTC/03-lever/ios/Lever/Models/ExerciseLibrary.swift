import Foundation

/// The hand-built catalogue of bodyweight movements and their skill ladders.
/// Targets are intentionally honest and motivating — the heart of the app.
enum ExerciseLibrary {

    static let all: [Exercise] = [pushUp, squat, pullUp, dip, plank, hollowHold]

    static func byID(_ id: String) -> Exercise? { all.first { $0.id == id } }

    // MARK: Push-Up

    static let pushUp = Exercise(
        id: "pushup", name: "Push-Up", muscleGroup: "Chest · Triceps", icon: "figure.strengthtraining.functional",
        unit: .reps,
        levels: [
            ProgressionLevel(index: 0, name: "Wall Push-Up", detail: "Hands on a wall, body leaning in. Builds the press pattern with almost no load.",
                             targetSets: 3, target: 15, restSeconds: 45,
                             tip: "Keep a straight line from heels to head — squeeze your glutes."),
            ProgressionLevel(index: 1, name: "Incline Push-Up", detail: "Hands on a bench or counter. The lower the surface, the harder it gets.",
                             targetSets: 3, target: 12, restSeconds: 60,
                             tip: "Lower your chest to the edge, not just your chin."),
            ProgressionLevel(index: 2, name: "Knee Push-Up", detail: "From the knees on the floor. Bridges the gap to full reps.",
                             targetSets: 3, target: 12, restSeconds: 60,
                             tip: "Hips stay forward — don't pike up at the waist."),
            ProgressionLevel(index: 3, name: "Full Push-Up", detail: "The classic. Toes and hands, chest to the floor, full lockout.",
                             targetSets: 3, target: 12, restSeconds: 75,
                             tip: "Elbows track back at ~45°, not flared straight out."),
            ProgressionLevel(index: 4, name: "Diamond Push-Up", detail: "Hands together under the chest. Hammers the triceps.",
                             targetSets: 3, target: 10, restSeconds: 75,
                             tip: "Form a diamond with thumbs and index fingers; keep elbows tight."),
            ProgressionLevel(index: 5, name: "Archer Push-Up", detail: "Weight shifts to one arm while the other stays straight. Builds one-arm strength.",
                             targetSets: 3, target: 6, restSeconds: 90, isPro: true,
                             tip: "Bend one arm fully while the other guides — alternate sides each rep."),
            ProgressionLevel(index: 6, name: "One-Arm Push-Up", detail: "The pinnacle press. Feet wide, one hand behind the back.",
                             targetSets: 3, target: 5, restSeconds: 120, isPro: true,
                             tip: "Brace hard and stay tight — resist twisting toward the working arm.")
        ])

    // MARK: Squat

    static let squat = Exercise(
        id: "squat", name: "Squat", muscleGroup: "Quads · Glutes", icon: "figure.cross.training",
        unit: .reps,
        levels: [
            ProgressionLevel(index: 0, name: "Assisted Squat", detail: "Hold a doorframe or TRX and sit back. Learns the hinge with support.",
                             targetSets: 3, target: 20, restSeconds: 45,
                             tip: "Sit back and down — let your support take just enough weight."),
            ProgressionLevel(index: 1, name: "Box Squat", detail: "Squat down to tap a chair or box, then stand. Controls depth.",
                             targetSets: 3, target: 18, restSeconds: 60,
                             tip: "Touch the box softly — don't crash or bounce off it."),
            ProgressionLevel(index: 2, name: "Full Squat", detail: "Bodyweight squat to below parallel, full depth, full stand.",
                             targetSets: 3, target: 20, restSeconds: 60,
                             tip: "Drive the knees out and keep your heels planted."),
            ProgressionLevel(index: 3, name: "Bulgarian Split Squat", detail: "Rear foot elevated, single-leg. A huge jump in per-leg strength.",
                             targetSets: 3, target: 12, restSeconds: 75,
                             tip: "Most weight on the front leg — knee tracks over the foot."),
            ProgressionLevel(index: 4, name: "Shrimp Squat", detail: "Single-leg squat holding the rear ankle behind you.",
                             targetSets: 3, target: 6, restSeconds: 90, isPro: true,
                             tip: "Lower the trailing knee toward the floor under control."),
            ProgressionLevel(index: 5, name: "Pistol Squat", detail: "Full single-leg squat with the other leg held straight out front.",
                             targetSets: 3, target: 5, restSeconds: 120, isPro: true,
                             tip: "Reach the free leg forward as a counterbalance; ankles must be mobile.")
        ])

    // MARK: Pull-Up

    static let pullUp = Exercise(
        id: "pullup", name: "Pull-Up", muscleGroup: "Back · Biceps", icon: "figure.play",
        unit: .reps,
        levels: [
            ProgressionLevel(index: 0, name: "Dead Hang", detail: "Just hang from the bar. Builds grip and shoulder readiness (counted in seconds).",
                             targetSets: 3, target: 30, restSeconds: 60,
                             tip: "Active shoulders — pull them down away from your ears."),
            ProgressionLevel(index: 1, name: "Negative Pull-Up", detail: "Jump to the top, then lower yourself as slowly as possible.",
                             targetSets: 3, target: 5, restSeconds: 75,
                             tip: "Aim for a 3–5 second descent — that's where the strength is built."),
            ProgressionLevel(index: 2, name: "Band-Assisted Pull-Up", detail: "A resistance band under the feet takes off enough weight to do full reps.",
                             targetSets: 3, target: 8, restSeconds: 75,
                             tip: "Use the lightest band you can — progress by switching down."),
            ProgressionLevel(index: 3, name: "Full Pull-Up", detail: "Dead hang to chin over the bar, unassisted.",
                             targetSets: 3, target: 8, restSeconds: 90,
                             tip: "Lead with the chest and drive elbows down to your ribs."),
            ProgressionLevel(index: 4, name: "L-Sit Pull-Up", detail: "Full pull-up while holding the legs out straight in an L.",
                             targetSets: 3, target: 5, restSeconds: 120, isPro: true,
                             tip: "Brace the core hard to keep the legs from dropping."),
            ProgressionLevel(index: 5, name: "Archer Pull-Up", detail: "Pull toward one hand while the other arm stays straight. Builds one-arm strength.",
                             targetSets: 3, target: 4, restSeconds: 120, isPro: true,
                             tip: "Keep the straight arm tense — it does real work guiding the rep.")
        ])

    // MARK: Dip

    static let dip = Exercise(
        id: "dip", name: "Dip", muscleGroup: "Chest · Triceps", icon: "figure.strengthtraining.traditional",
        unit: .reps,
        levels: [
            ProgressionLevel(index: 0, name: "Bench Dip", detail: "Hands on a bench behind you, feet on the floor. Easiest entry.",
                             targetSets: 3, target: 15, restSeconds: 45,
                             tip: "Keep your back close to the bench and lower to 90° at the elbow."),
            ProgressionLevel(index: 1, name: "Foot-Supported Dip", detail: "On parallel bars with feet lightly on the ground to assist.",
                             targetSets: 3, target: 10, restSeconds: 60,
                             tip: "Use just enough leg drive to complete clean reps."),
            ProgressionLevel(index: 2, name: "Negative Dip", detail: "Start at the top on the bars and lower yourself slowly.",
                             targetSets: 3, target: 6, restSeconds: 75,
                             tip: "Control a 3–5 second descent, then reset to the top."),
            ProgressionLevel(index: 3, name: "Full Dip", detail: "Full range on parallel bars, shoulders below elbows at the bottom.",
                             targetSets: 3, target: 8, restSeconds: 90,
                             tip: "Lean slightly forward for chest, stay upright for triceps."),
            ProgressionLevel(index: 4, name: "Ring Dip", detail: "Dips on gymnastic rings — adds a brutal stability demand.",
                             targetSets: 3, target: 6, restSeconds: 120, isPro: true,
                             tip: "Turn the rings out at the top (RTO) to lock the position.")
        ])

    // MARK: Plank (seconds)

    static let plank = Exercise(
        id: "plank", name: "Plank", muscleGroup: "Core", icon: "figure.core.training",
        unit: .seconds,
        levels: [
            ProgressionLevel(index: 0, name: "Knee Plank", detail: "Forearm plank from the knees. Learns the brace with less load.",
                             targetSets: 3, target: 30, restSeconds: 45,
                             tip: "Tuck the pelvis and squeeze — don't let the lower back sag."),
            ProgressionLevel(index: 1, name: "Forearm Plank", detail: "The standard forearm plank from the toes.",
                             targetSets: 3, target: 45, restSeconds: 60,
                             tip: "Straight line from heels to head; breathe steadily."),
            ProgressionLevel(index: 2, name: "High Plank", detail: "Plank on straight arms — adds shoulder stability.",
                             targetSets: 3, target: 60, restSeconds: 60,
                             tip: "Stack shoulders over wrists and push the floor away."),
            ProgressionLevel(index: 3, name: "Single-Leg Plank", detail: "Hold a forearm plank with one foot lifted.",
                             targetSets: 3, target: 30, restSeconds: 75,
                             tip: "Keep the hips level — resist the urge to rotate."),
            ProgressionLevel(index: 4, name: "RKC Plank", detail: "Maximum-tension plank: glutes, quads and abs braced hard.",
                             targetSets: 3, target: 20, restSeconds: 90,
                             tip: "Pull elbows toward your toes — it should be intense from second one."),
            ProgressionLevel(index: 5, name: "Long-Lever Plank", detail: "Forearms reached further forward to extend the lever arm.",
                             targetSets: 3, target: 30, restSeconds: 90, isPro: true,
                             tip: "The further forward the elbows, the harder the core works.")
        ])

    // MARK: Hollow Hold (seconds)

    static let hollowHold = Exercise(
        id: "hollow", name: "Hollow Hold", muscleGroup: "Core", icon: "figure.flexibility",
        unit: .seconds,
        levels: [
            ProgressionLevel(index: 0, name: "Tuck Hollow", detail: "On your back, knees tucked, shoulders off the floor.",
                             targetSets: 3, target: 30, restSeconds: 45,
                             tip: "Press the lower back into the floor the whole time."),
            ProgressionLevel(index: 1, name: "Single-Leg Hollow", detail: "One leg extended, the other tucked.",
                             targetSets: 3, target: 30, restSeconds: 60,
                             tip: "Lower the straight leg only as far as you keep the back flat."),
            ProgressionLevel(index: 2, name: "Bent-Arm Hollow", detail: "Both legs out straight, arms by your sides.",
                             targetSets: 3, target: 40, restSeconds: 60,
                             tip: "Point the toes and keep a steady, dish-shaped body."),
            ProgressionLevel(index: 3, name: "Full Hollow Hold", detail: "Legs and arms extended overhead — the full hollow body.",
                             targetSets: 3, target: 45, restSeconds: 75,
                             tip: "If the back lifts, raise the arms or legs higher to scale it down."),
            ProgressionLevel(index: 4, name: "Hollow Rock", detail: "Full hollow position, rocking back and forth without losing the shape.",
                             targetSets: 3, target: 40, restSeconds: 90, isPro: true,
                             tip: "Rock from the rounded back, not by breaking at the hips.")
        ])
}
