import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Query private var companions: [Companion]

    @State private var step = 0
    @State private var companionName = "Wren"
    @State private var selectedGoalIDs: Set<Int> = [0, 2] // sensible defaults: walk + breaths
    @FocusState private var nameFocused: Bool

    private let starters = SeedData.starterGoals()

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                progressDots
                TabView(selection: $step) {
                    welcomeStep.tag(0)
                    nameStep.tag(1)
                    goalsStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                footer
            }
            .padding()
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Theme.accent : Theme.hairline)
                    .frame(width: i == step ? 22 : 8, height: 8)
                    .animation(.easeInOut, value: step)
            }
        }
        .padding(.top, 8)
        .accessibilityElement()
        .accessibilityLabel("Step \(step + 1) of 3")
    }

    // MARK: Steps

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()
            WrenBirdView(mood: .content, accessory: nil)
                .frame(width: 180, height: 180)
            Text("Meet Wren")
                .font(Theme.serif(34, .bold))
                .foregroundStyle(Theme.ink)
            Text("A calm little companion that grows when you care for yourself. No streaks shouting at you, no pressure — just gentle, steady company.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }

    private var nameStep: some View {
        VStack(spacing: 20) {
            Spacer()
            WrenBirdView(mood: .thriving, accessory: nil)
                .frame(width: 140, height: 140)
            Text("Name your companion")
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.ink)
            Text("You can change this any time in Settings.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            TextField("Name", text: $companionName)
                .font(Theme.rounded(20, .semibold))
                .multilineTextAlignment(.center)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .padding(.vertical, 14)
                .card(Theme.surface)
                .padding(.horizontal, 40)
                .accessibilityLabel("Companion name")
            Spacer()
        }
    }

    private var goalsStep: some View {
        VStack(spacing: 16) {
            Text("Pick a couple to start")
                .font(Theme.serif(26, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.top, 8)
            Text("Small is good. You can add more later.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(starters.enumerated()), id: \.offset) { idx, goal in
                        starterRow(idx: idx, goal: goal)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func starterRow(idx: Int, goal: SelfCareGoal) -> some View {
        let selected = selectedGoalIDs.contains(idx)
        return Button {
            if selected { selectedGoalIDs.remove(idx) } else { selectedGoalIDs.insert(idx) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: goal.category.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(goal.category.color)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(goal.schedule.summary)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Theme.accent : Theme.inkFaint)
            }
            .padding(14)
            .card(selected ? Theme.accentSoft : Theme.surface)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(goal.title)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityHint(goal.schedule.summary)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button(step < 2 ? "Continue" : "Begin") {
                advance()
            }
            .buttonStyle(WrenPrimaryButtonStyle())
            .disabled(step == 1 && companionName.trimmingCharacters(in: .whitespaces).isEmpty)

            if step > 0 {
                Button("Back") { withAnimation { step -= 1 } }
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(.bottom, 8)
    }

    private func advance() {
        if step < 2 {
            withAnimation { step += 1 }
            if step == 1 { nameFocused = true }
        } else {
            finish()
        }
    }

    private func finish() {
        nameFocused = false
        let trimmed = companionName.trimmingCharacters(in: .whitespaces)
        let name = trimmed.isEmpty ? "Wren" : trimmed

        // Seed the full realistic dataset, then keep only the chosen starter goals as active
        // and archive the rest so the user starts focused but with rich history.
        if companions.isEmpty {
            SeedData.seedIfNeeded(context: modelContext, companionName: name)
            applyStarterSelection(name: name)
        }
        hasOnboarded = true
    }

    private func applyStarterSelection(name: String) {
        // Update companion name (seed used it but ensure exact match).
        if let companion = try? modelContext.fetch(FetchDescriptor<Companion>()).first {
            companion.name = name
        }
        // Archive goals the user did not select, so their first day is uncluttered.
        if let goals = try? modelContext.fetch(FetchDescriptor<SelfCareGoal>()) {
            let titles = Set(selectedGoalIDs.compactMap { idx -> String? in
                starters.indices.contains(idx) ? starters[idx].title : nil
            })
            if !titles.isEmpty {
                for goal in goals where !titles.contains(goal.title) {
                    goal.isArchived = true
                }
            }
        }
        try? modelContext.save()
    }
}
