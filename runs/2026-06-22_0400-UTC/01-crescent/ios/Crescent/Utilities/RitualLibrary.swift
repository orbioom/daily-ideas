import Foundation

struct RitualTemplate: Identifiable {
    let id: String
    let phase: MoonPhase
    let title: String
    let description: String
    let steps: [String]
    let duration: String
}

enum RitualLibrary {
    static let all: [RitualTemplate] = [
        RitualTemplate(
            id: "new_intention",
            phase: .newMoon,
            title: "New Moon Intention Setting",
            description: "Plant the seeds of your desires for this lunar cycle.",
            steps: [
                "Find a quiet space and light a candle",
                "Take 5 deep breaths to center yourself",
                "Write 3 clear intentions in present tense (I am, I have, I create...)",
                "Visualize each intention as already fulfilled",
                "Close with gratitude: 'Thank you for guiding me'",
                "Keep your intention list somewhere visible"
            ],
            duration: "20–30 min"
        ),
        RitualTemplate(
            id: "new_cleanse",
            phase: .newMoon,
            title: "New Moon Space Cleanse",
            description: "Clear stagnant energy from your home to make room for new beginnings.",
            steps: [
                "Open all windows if weather permits",
                "Clean and declutter one room thoroughly",
                "Light incense or diffuse uplifting essential oils",
                "Walk through each room setting a positive intention",
                "End with a moment of stillness and gratitude"
            ],
            duration: "30–60 min"
        ),
        RitualTemplate(
            id: "full_release",
            phase: .fullMoon,
            title: "Full Moon Release Ritual",
            description: "Let go of what no longer serves your highest good.",
            steps: [
                "Sit under moonlight if possible, or near a window",
                "Write down what you want to release: fears, habits, relationships",
                "Read each item aloud: 'I release this with love and gratitude'",
                "Safely burn the paper (or tear and dispose mindfully)",
                "Take a cleansing bath or shower, imagining the release washing away",
                "Journal about how you feel lighter"
            ],
            duration: "30–45 min"
        ),
        RitualTemplate(
            id: "full_gratitude",
            phase: .fullMoon,
            title: "Full Moon Gratitude Practice",
            description: "Celebrate the fullness of your life and all you have created.",
            steps: [
                "Make a list of 20 things you are grateful for this cycle",
                "Reflect on intentions set at the new moon — what manifested?",
                "Write a love letter to yourself for all you have accomplished",
                "Share your abundance: do something kind for someone else",
                "Celebrate! Treat yourself to something nourishing"
            ],
            duration: "20–30 min"
        ),
        RitualTemplate(
            id: "waning_forgiveness",
            phase: .lastQuarter,
            title: "Forgiveness & Letting Go",
            description: "Release resentments and make peace with the past.",
            steps: [
                "Write a letter to someone you need to forgive (don't send it)",
                "Write a letter forgiving yourself for past mistakes",
                "Take 10 deep breaths, exhaling fully each time",
                "Say aloud: 'I choose peace over being right'",
                "Dispose of the letters symbolically"
            ],
            duration: "20–30 min"
        ),
        RitualTemplate(
            id: "crescent_action",
            phase: .waxingCrescent,
            title: "Waxing Crescent Action Planning",
            description: "Take the first steps toward your new moon intentions.",
            steps: [
                "Review your new moon intentions",
                "For each intention, identify ONE concrete action you can take today",
                "Write a daily schedule that supports your goals",
                "Remove one obstacle from your path",
                "Affirm: 'I take inspired action toward my dreams'"
            ],
            duration: "15–20 min"
        ),
        RitualTemplate(
            id: "waning_rest",
            phase: .waningCrescent,
            title: "Dark Moon Rest & Renewal",
            description: "Honor the void. Rest deeply before the next cycle begins.",
            steps: [
                "Spend time in silence for at least 10 minutes",
                "Journal: What did this lunar cycle teach you?",
                "Take a long bath or do restorative yoga",
                "Go to bed early and set an intention for your dreams",
                "Be gentle with yourself — this is a sacred pause"
            ],
            duration: "60 min"
        ),
        RitualTemplate(
            id: "gibbous_refine",
            phase: .waxingGibbous,
            title: "Refinement & Adjustment",
            description: "Fine-tune your plans as the moon approaches fullness.",
            steps: [
                "Review your progress since the new moon",
                "Identify what is working and what needs adjustment",
                "Make one meaningful change to your approach",
                "Ask for help or support if needed",
                "Trust the process — the full moon is almost here"
            ],
            duration: "20 min"
        ),
        RitualTemplate(
            id: "quarter_courage",
            phase: .firstQuarter,
            title: "First Quarter Courage Ritual",
            description: "Push through challenges with fierce determination.",
            steps: [
                "Write down any challenges or blocks you are facing",
                "For each challenge, brainstorm 3 creative solutions",
                "Choose one solution and commit to it fully",
                "Do something that scares you (but excites you) today",
                "Affirm: 'I have the strength to overcome any obstacle'"
            ],
            duration: "20–25 min"
        ),
        RitualTemplate(
            id: "waning_gibbous_thanks",
            phase: .waningGibbous,
            title: "Waning Gibbous Gratitude Walk",
            description: "Embody gratitude through mindful movement.",
            steps: [
                "Take a slow walk outside (or around your home)",
                "With each step, notice one thing you appreciate",
                "Pause to really feel the gratitude in your body",
                "Text or call someone to express appreciation",
                "Journal: 3 ways the universe supported you this cycle"
            ],
            duration: "30 min"
        )
    ]

    static func rituals(for phase: MoonPhase) -> [RitualTemplate] {
        all.filter { $0.phase == phase }
    }
}
