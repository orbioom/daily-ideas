import SwiftUI
import SwiftData

struct GoalView: View {
    @Query private var goals: [DrinkGoal]
    @Environment(\.modelContext) private var ctx

    private var goal: DrinkGoal {
        if let g = goals.first { return g }
        let g = DrinkGoal()
        ctx.insert(g)
        return g
    }

    var body: some View {
        NavigationStack {
            GoalEditorView(goal: goal)
                .navigationTitle("My Goal")
        }
    }
}

private struct GoalEditorView: View {
    @Bindable var goal: DrinkGoal
    @State private var newMotivation = ""

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly drink limit")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DripTheme.subtle)
                    Stepper("\(goal.weeklyLimit) drinks per week", value: Binding(
                        get: { goal.weeklyLimit },
                        set: { goal.weeklyLimit = $0 }
                    ), in: 1...50)
                    .accessibilityLabel("Weekly drink limit: \(goal.weeklyLimit) drinks")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Alcohol-free day target")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DripTheme.subtle)
                    Stepper("\(goal.alcoholFreeDaysTarget) AF days per week", value: Binding(
                        get: { goal.alcoholFreeDaysTarget },
                        set: { goal.alcoholFreeDaysTarget = $0 }
                    ), in: 0...7)
                    .accessibilityLabel("Alcohol-free days target: \(goal.alcoholFreeDaysTarget) per week")
                }
            } header: {
                Text("Limits")
            }

            Section("Money Tracking") {
                HStack {
                    Text("Avg cost per drink")
                    Spacer()
                    TextField("8.00", value: Binding(
                        get: { goal.costPerDrink },
                        set: { goal.costPerDrink = $0 }
                    ), format: .number.precision(.fractionLength(2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .accessibilityLabel("Average cost per drink")
                }

                Picker("Currency", selection: Binding(
                    get: { goal.currencySymbol },
                    set: { goal.currencySymbol = $0 }
                )) {
                    Text("$ USD").tag("$")
                    Text("€ EUR").tag("€")
                    Text("£ GBP").tag("£")
                    Text("¥ JPY").tag("¥")
                    Text("A$ AUD").tag("A$")
                }
                .accessibilityLabel("Currency symbol")
            }

            Section("My Motivations") {
                if goal.motivations.isEmpty {
                    Text("Add reasons you want to drink less — they help on hard days.")
                        .font(.caption)
                        .foregroundStyle(DripTheme.subtle)
                }
                ForEach(goal.motivations, id: \.self) { m in
                    Label(m, systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(DripTheme.text)
                }
                .onDelete { offsets in
                    var updated = goal.motivations
                    updated.remove(atOffsets: offsets)
                    goal.motivations = updated
                }

                HStack {
                    TextField("Add a motivation…", text: $newMotivation)
                        .accessibilityLabel("New motivation")
                    Button {
                        let trimmed = newMotivation.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        goal.motivations.append(trimmed)
                        newMotivation = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(DripTheme.accent)
                    }
                    .accessibilityLabel("Add motivation")
                }
            }

            Section("About Your Limits") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Low-risk guidelines (UK NHS): ≤14 units/week for men and women. 1 standard drink (US) ≈ 1.4 UK units.")
                        .font(.caption)
                        .foregroundStyle(DripTheme.subtle)
                    Text("NIAAA (US): Low-risk for women: ≤7/week, ≤3/day. Low-risk for men: ≤14/week, ≤4/day.")
                        .font(.caption)
                        .foregroundStyle(DripTheme.subtle)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(DripTheme.bg)
    }
}
