import Foundation
import SwiftData

@Model
final class WritingPrompt {
    var id: UUID
    var promptText: String
    var eraRaw: String
    var isUsed: Bool
    var usedDate: Date?

    init(
        id: UUID = UUID(),
        promptText: String,
        era: LifeEra,
        isUsed: Bool = false,
        usedDate: Date? = nil
    ) {
        self.id = id
        self.promptText = promptText
        self.eraRaw = era.rawValue
        self.isUsed = isUsed
        self.usedDate = usedDate
    }

    var era: LifeEra {
        get { LifeEra(rawValue: eraRaw) ?? .reflection }
        set { eraRaw = newValue.rawValue }
    }

    static var defaultPrompts: [WritingPrompt] {
        [
            // Childhood
            WritingPrompt(promptText: "What is your earliest memory?", era: .childhood),
            WritingPrompt(promptText: "Describe the home you grew up in.", era: .childhood),
            WritingPrompt(promptText: "Who was your best childhood friend?", era: .childhood),
            WritingPrompt(promptText: "What were you most afraid of as a child?", era: .childhood),
            WritingPrompt(promptText: "Describe a typical school day from your childhood.", era: .childhood),
            WritingPrompt(promptText: "What was your favorite family tradition growing up?", era: .childhood),
            WritingPrompt(promptText: "Tell me about a summer that shaped who you are.", era: .childhood),
            WritingPrompt(promptText: "Who was your most memorable teacher and why?", era: .childhood),

            // Teen Years
            WritingPrompt(promptText: "What was the biggest challenge you faced as a teenager?", era: .teen),
            WritingPrompt(promptText: "Describe your first crush or first love.", era: .teen),
            WritingPrompt(promptText: "What music defined your teenage years?", era: .teen),
            WritingPrompt(promptText: "Tell me about a time you got into trouble as a teen.", era: .teen),
            WritingPrompt(promptText: "What did you dream of becoming when you were 16?", era: .teen),
            WritingPrompt(promptText: "Describe the group of friends you had in high school.", era: .teen),

            // Young Adult
            WritingPrompt(promptText: "Describe your first job and what you learned from it.", era: .youngAdult),
            WritingPrompt(promptText: "Tell me about the moment you felt truly independent for the first time.", era: .youngAdult),
            WritingPrompt(promptText: "What was the biggest decision you ever made in your twenties?", era: .youngAdult),
            WritingPrompt(promptText: "Describe a place you lived that felt like home.", era: .youngAdult),
            WritingPrompt(promptText: "Who mentored you most in your early career?", era: .youngAdult),

            // Adult Life
            WritingPrompt(promptText: "How did you meet the most important person in your life?", era: .adult),
            WritingPrompt(promptText: "Describe a moment you felt truly proud of yourself.", era: .adult),
            WritingPrompt(promptText: "What sacrifice did you make that you would make again?", era: .adult),
            WritingPrompt(promptText: "Tell me about a time you failed and what it taught you.", era: .adult),
            WritingPrompt(promptText: "What career accomplishment means the most to you and why?", era: .adult),
            WritingPrompt(promptText: "Describe a trip or adventure that changed your perspective.", era: .adult),

            // Recent Years
            WritingPrompt(promptText: "What has surprised you most about this chapter of your life?", era: .recent),
            WritingPrompt(promptText: "What does a perfect ordinary day look like for you now?", era: .recent),
            WritingPrompt(promptText: "What habit or practice has brought you the most joy recently?", era: .recent),

            // Reflection
            WritingPrompt(promptText: "What is the best advice you have ever received?", era: .reflection),
            WritingPrompt(promptText: "What would you tell your 20-year-old self?", era: .reflection),
            WritingPrompt(promptText: "What do you most want future generations of your family to know about you?", era: .reflection),
        ]
    }
}
