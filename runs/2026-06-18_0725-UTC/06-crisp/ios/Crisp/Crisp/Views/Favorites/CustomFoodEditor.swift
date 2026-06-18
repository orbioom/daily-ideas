import SwiftUI
import SwiftData

/// Create or edit a custom food. Validates input; saves to SwiftData.
struct CustomFoodEditor: View {
    let existing: CustomFood?

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: FoodCategory = .snacks
    @State private var tempF = 380
    @State private var minutes = 12
    @State private var notes = ""
    @State private var showValidation = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        nameCard
                        categoryCard
                        tempTimeCard
                        notesCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle(existing == nil ? "New Food" : "Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(Theme.roundedStyle(.body, .bold))
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(Theme.roundedStyle(.subheadline, .semibold))
                .foregroundStyle(Theme.inkSoft)
            TextField("e.g. Garlic naan bites", text: $name)
                .font(Theme.roundedStyle(.body))
                .padding(14)
                .crispCard(radius: Theme.chipRadius)
            if showValidation && !isValid {
                Text("Give your food a name to save it.")
                    .font(Theme.roundedStyle(.caption, .semibold))
                    .foregroundStyle(Theme.bad)
            }
        }
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(Theme.roundedStyle(.subheadline, .semibold))
                .foregroundStyle(Theme.inkSoft)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FoodCategory.allCases) { cat in
                        FilterChip(label: cat.rawValue, emoji: cat.icon, isOn: category == cat) {
                            category = cat
                            Haptics.selection(enabled: settings.hapticsEnabled)
                        }
                    }
                }
            }
        }
    }

    private var tempTimeCard: some View {
        VStack(spacing: 16) {
            stepperRow(
                title: "Temperature",
                value: Fmt.temp(fahrenheit: tempF, unit: settings.tempUnit),
                onMinus: { tempF = max(150, tempF - 5) },
                onPlus: { tempF = min(450, tempF + 5) }
            )
            Divider().background(Theme.hairline)
            stepperRow(
                title: "Time",
                value: Fmt.minutesLabel(minutes),
                onMinus: { minutes = max(1, minutes - 1) },
                onPlus: { minutes = min(180, minutes + 1) }
            )
        }
        .padding(16)
        .crispCard()
    }

    private func stepperRow(title: String, value: String, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.roundedStyle(.subheadline, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Text(value)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }
            Spacer()
            HStack(spacing: 10) {
                roundStep("minus") { onMinus(); Haptics.selection(enabled: settings.hapticsEnabled) }
                roundStep("plus") { onPlus(); Haptics.selection(enabled: settings.hapticsEnabled) }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func roundStep(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 44, height: 44)
                .foregroundStyle(.white)
                .background(Circle().fill(Theme.accent))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol == "plus" ? "Increase" : "Decrease")
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(Theme.roundedStyle(.subheadline, .semibold))
                .foregroundStyle(Theme.inkSoft)
            TextField("Optional tips", text: $notes, axis: .vertical)
                .lineLimit(2...5)
                .font(Theme.roundedStyle(.body))
                .padding(14)
                .crispCard(radius: Theme.chipRadius)
        }
    }

    private func load() {
        guard let e = existing else { return }
        name = e.name
        category = e.category
        tempF = e.tempF
        minutes = e.minutes
        notes = e.notes
    }

    private func save() {
        guard isValid else {
            showValidation = true
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            return
        }
        if let e = existing {
            e.name = trimmedName
            e.categoryRaw = category.rawValue
            e.tempF = min(max(tempF, 150), 450)
            e.minutes = min(max(minutes, 1), 180)
            e.notes = notes
        } else {
            context.insert(CustomFood(
                name: trimmedName,
                categoryRaw: category.rawValue,
                tempF: tempF,
                minutes: minutes,
                notes: notes
            ))
        }
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
