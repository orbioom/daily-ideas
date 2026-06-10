import Foundation
import SwiftData

/// The built-in affirmation library, seeded once on first launch.
enum AffirmationSeed {
    static let all: [(AffirmationTheme, String)] = [
        // Morning
        (.morning, "Today is full of fresh possibility."),
        (.morning, "I wake with a clear and willing mind."),
        (.morning, "I greet this day on my own terms."),
        (.morning, "My energy rises with the light."),
        (.morning, "I choose how this morning feels."),
        (.morning, "Each new day is mine to shape."),
        (.morning, "I begin gently, and I begin strong."),
        (.morning, "What I start today, I can finish well."),
        (.morning, "I carry calm with me into the day."),
        (.morning, "The morning is a quiet promise I keep to myself."),
        (.morning, "I rise rested and ready."),
        (.morning, "I let yesterday rest and meet today awake."),

        // Calm
        (.calm, "I breathe in calm and breathe out tension."),
        (.calm, "This moment is enough."),
        (.calm, "I am allowed to slow down."),
        (.calm, "My breath is steady and so am I."),
        (.calm, "I release what I cannot control."),
        (.calm, "Stillness is always available to me."),
        (.calm, "I meet my worries with a soft mind."),
        (.calm, "Peace begins with my next breath."),
        (.calm, "I am safe in this quiet moment."),
        (.calm, "I let my shoulders drop and my jaw soften."),
        (.calm, "There is nothing I must rush toward."),
        (.calm, "I return to my breath whenever I drift."),

        // Confidence
        (.confidence, "I trust myself to handle what comes."),
        (.confidence, "My voice deserves to be heard."),
        (.confidence, "I am capable of more than I assume."),
        (.confidence, "I take up the space I need."),
        (.confidence, "I act before I feel ready, and I grow."),
        (.confidence, "My ideas have value."),
        (.confidence, "I stand tall in who I am."),
        (.confidence, "I do not shrink to make others comfortable."),
        (.confidence, "I have survived every hard day so far."),
        (.confidence, "I speak with steadiness and care."),
        (.confidence, "I am becoming braver each time I try."),
        (.confidence, "My worth is not up for debate."),

        // Gratitude
        (.gratitude, "I notice the good that is already here."),
        (.gratitude, "I am grateful for this breath and this body."),
        (.gratitude, "Small joys are worth pausing for."),
        (.gratitude, "I have enough, and I am enough."),
        (.gratitude, "I thank the people who hold me up."),
        (.gratitude, "Today gave me something to keep."),
        (.gratitude, "I find one thing to appreciate right now."),
        (.gratitude, "Gratitude softens my whole day."),
        (.gratitude, "I am thankful for how far I have come."),
        (.gratitude, "There is beauty within my reach."),
        (.gratitude, "I receive kindness with an open heart."),
        (.gratitude, "I celebrate the ordinary and the good."),

        // Self-Love
        (.selfLove, "I am worthy of my own kindness."),
        (.selfLove, "I speak to myself as I would a dear friend."),
        (.selfLove, "I am doing the best I can, and that is okay."),
        (.selfLove, "I forgive myself for being human."),
        (.selfLove, "My body carries me, and I thank it."),
        (.selfLove, "I do not need to earn rest."),
        (.selfLove, "I am allowed to take up space."),
        (.selfLove, "I accept myself exactly as I am today."),
        (.selfLove, "My feelings are valid and welcome."),
        (.selfLove, "I release the need to be perfect."),
        (.selfLove, "I am enough, just as I am."),
        (.selfLove, "I treat my mistakes with patience."),

        // Success
        (.success, "I move toward my goals one step at a time."),
        (.success, "I am building something that matters."),
        (.success, "Effort, repeated, becomes mastery."),
        (.success, "I learn from setbacks instead of fearing them."),
        (.success, "I am focused on what I can do now."),
        (.success, "My discipline is a gift I give myself."),
        (.success, "I finish what I start."),
        (.success, "I am resourceful and I find a way."),
        (.success, "Progress, not perfection, is my measure."),
        (.success, "I deserve the success I am working toward."),
        (.success, "I keep promises I make to myself."),
        (.success, "Every small win compounds."),

        // Healing
        (.healing, "I am allowed to heal at my own pace."),
        (.healing, "I am not behind; I am becoming."),
        (.healing, "I hold space for my own recovery."),
        (.healing, "I am gentle with my tender places."),
        (.healing, "Each day I carry a little less weight."),
        (.healing, "I let go of what no longer serves me."),
        (.healing, "My past does not define my next step."),
        (.healing, "I am safe to feel what I feel."),
        (.healing, "I trust that I am growing through this."),
        (.healing, "I give myself permission to rest and mend."),
        (.healing, "I am whole even while I heal."),
        (.healing, "Time and care are on my side."),

        // Sleep
        (.sleep, "I release the day and let myself rest."),
        (.sleep, "My mind grows quiet and soft."),
        (.sleep, "I have done enough for today."),
        (.sleep, "I let each muscle sink and settle."),
        (.sleep, "Tomorrow can wait; tonight I rest."),
        (.sleep, "I am safe, and I can let go."),
        (.sleep, "My breath slows and my thoughts drift."),
        (.sleep, "I welcome deep and gentle sleep."),
        (.sleep, "I set down my worries until morning."),
        (.sleep, "Rest is a kindness I give myself."),
        (.sleep, "I drift toward calm with every exhale."),
        (.sleep, "The day is complete; I am at peace."),
    ]

    static func seed(into context: ModelContext) {
        for (theme, text) in all {
            context.insert(Affirmation(text: text, theme: theme, isCustom: false))
        }
    }
}

/// One-time seeding guarded by a persisted flag.
enum Seeder {
    static func seedIfNeeded(_ context: ModelContext) {
        let flag = "seeded.v1"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        AffirmationSeed.seed(into: context)
        try? context.save()
        UserDefaults.standard.set(true, forKey: flag)
    }
}
