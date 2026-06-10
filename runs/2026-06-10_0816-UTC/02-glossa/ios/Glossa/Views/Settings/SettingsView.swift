import SwiftUI

struct SettingsView: View {
    @AppStorage("dailyGoal") private var dailyGoal = 20
    @AppStorage("maxSessionCards") private var maxSessionCards = 15
    @AppStorage("typedAnswers") private var typedAnswers = true
    @AppStorage("requireArticle") private var requireArticle = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Study") {
                    Stepper("Daily goal: \(dailyGoal) reviews", value: $dailyGoal, in: 5...100, step: 5)
                    Stepper("Session size: \(maxSessionCards) cards", value: $maxSessionCards, in: 5...50, step: 5)
                    Toggle("Typed answers for strong words", isOn: $typedAnswers)
                        .tint(Brand.live)
                    Text("Words in box 3 and above switch from multiple choice to typed recall — the mode that actually builds production.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Grading") {
                    Toggle("Require the article", isOn: $requireArticle)
                        .tint(Brand.live)
                    Text("Off: “casa” is accepted for “la casa”, and answers one letter off count as correct. On: articles must match exactly — best once genders feel solid.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Feel") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                        .tint(Brand.live)
                }

                Section("About") {
                    LabeledContent("App", value: "Glossa 1.0")
                    LabeledContent("Made by", value: "Orbioom")
                    Text("All decks and progress live on this device. No account, no lockouts, no upsell screens.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
