import SwiftUI

/// The personal safety plan editor. Stored in @AppStorage so it survives relaunch
/// and is available instantly in a hard moment.
struct SafetyPlanView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    @AppStorage(PrefKey.safetyWarningSigns) private var warningSigns = ""
    @AppStorage(PrefKey.safetyReasons) private var reasons = ""
    @AppStorage(PrefKey.safetyWhoToCall) private var whoToCall = ""

    var body: some View {
        ZStack {
            HavenBackground()
            ScrollView {
                VStack(spacing: 18) {
                    intro
                    planField(
                        title: "My warning signs",
                        hint: "What does a hard moment starting to feel like for me?",
                        icon: "exclamationmark.triangle",
                        text: $warningSigns
                    )
                    planField(
                        title: "Reasons to stay safe",
                        hint: "People, plans, and things that matter to me.",
                        icon: "heart",
                        text: $reasons
                    )
                    planField(
                        title: "Who I can reach out to",
                        hint: "Names and how to contact them.",
                        icon: "person.2",
                        text: $whoToCall
                    )
                }
                .padding(20)
            }
        }
        .navigationTitle("Safety plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var intro: some View {
        Text("A safety plan is something kind you write for your future self. It saves automatically as you type.")
            .font(.subheadline)
            .foregroundStyle(HavenTheme.secondaryText(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func planField(title: String, hint: String, icon: String, text: Binding<String>) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(HavenTheme.accent)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(HavenTheme.primaryText(scheme))
                }
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
                TextEditor(text: text)
                    .frame(minHeight: 96)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(HavenTheme.subtleFill(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerSmall, style: .continuous))
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                    .accessibilityLabel(title)
                    .accessibilityHint(hint)
            }
        }
    }
}
