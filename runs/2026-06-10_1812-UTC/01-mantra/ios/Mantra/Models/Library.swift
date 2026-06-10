import Foundation

/// The built-in affirmation library, grouped by category. Seeded into SwiftData
/// once on first launch so favorites and practice logs attach to real models.
enum Library {
    static let all: [(MantraCategory, [String])] = [
        (.morning, [
            "Today is a fresh page, and I am ready to write something good on it.",
            "I greet this morning with a calm and open mind.",
            "I have everything I need to make today meaningful.",
            "I move through this day with ease and intention.",
            "Each sunrise is a quiet invitation to begin again.",
            "I choose how I meet this day, and I choose peace.",
            "My energy is steady, and my purpose is clear.",
            "I am grateful for the simple gift of a new day."
        ]),
        (.calm, [
            "I am allowed to slow down and breathe.",
            "This moment is enough, and so am I.",
            "I release what I cannot control.",
            "My breath is an anchor I can always return to.",
            "Stillness is something I can give myself.",
            "I let tension leave my body with every exhale.",
            "Peace is not somewhere else; it is here, in me.",
            "I am safe in this present moment."
        ]),
        (.confidence, [
            "I trust myself to handle whatever comes.",
            "My voice matters, and I deserve to be heard.",
            "I am capable of more than my doubts tell me.",
            "I stand tall in who I am.",
            "I do not shrink to make others comfortable.",
            "Every challenge is a chance to prove my strength.",
            "I believe in my ability to figure things out.",
            "I am becoming more sure of myself each day."
        ]),
        (.selfLove, [
            "I am worthy of love exactly as I am.",
            "I speak to myself with kindness and patience.",
            "My imperfections make me human, not less.",
            "I forgive myself for not being perfect.",
            "I am my own home, and I deserve care.",
            "I treat my body with respect and gratitude.",
            "I am enough, and I have always been enough.",
            "I choose to be gentle with myself today."
        ]),
        (.gratitude, [
            "I notice the small good things around me.",
            "My life holds more than I sometimes remember.",
            "I am thankful for the people who care about me.",
            "Gratitude turns what I have into enough.",
            "I appreciate the quiet comforts of my day.",
            "I give thanks for the lessons in hard moments.",
            "There is so much already right in my life.",
            "I carry a grateful heart wherever I go."
        ]),
        (.success, [
            "I am building something one steady step at a time.",
            "My effort compounds, even when I can't see it yet.",
            "I am allowed to want more for my life.",
            "Setbacks are information, not verdicts.",
            "I finish what truly matters to me.",
            "I deserve the good that my work brings.",
            "I focus on progress, not perfection.",
            "I am the kind of person who follows through."
        ]),
        (.abundance, [
            "There is enough for me, and enough of me to give.",
            "Opportunities flow toward me when I stay open.",
            "I release scarcity and welcome possibility.",
            "I am open to receiving good things.",
            "My worth is not measured by what I lack.",
            "Generosity returns to me in unexpected ways.",
            "I trust that what I need will find me.",
            "Abundance begins with how I see what I already have."
        ]),
        (.healing, [
            "I am healing at my own pace, and that is okay.",
            "I give myself permission to rest and recover.",
            "My past does not define my future.",
            "Each day, I grow a little lighter.",
            "I honor my feelings without being ruled by them.",
            "I am stronger than the moment that hurt me.",
            "Healing is not linear, and I am still moving forward.",
            "I let go of what no longer serves me."
        ]),
        (.focus, [
            "I give my full attention to one thing at a time.",
            "Distraction passes; my purpose remains.",
            "I return to my work gently when my mind wanders.",
            "I protect my attention like the resource it is.",
            "Right now, this task is all I need to do.",
            "I am present, clear, and engaged.",
            "Small focused efforts build remarkable results.",
            "I choose depth over noise."
        ]),
        (.sleep, [
            "I release today and let my body rest.",
            "My mind is quiet, and my breathing is slow.",
            "I have done enough for today.",
            "I let go of tomorrow's worries until tomorrow.",
            "Sleep comes easily to a calm and grateful heart.",
            "I am wrapped in stillness and safety.",
            "Every muscle softens as I drift toward rest.",
            "Tomorrow will keep; tonight I simply rest."
        ])
    ]

    /// Flattened seed payload.
    static var seeds: [(String, MantraCategory)] {
        all.flatMap { cat, lines in lines.map { ($0, cat) } }
    }
}
