import SwiftUI
import SwiftData

/// Pick a day + slot + servings to add a recipe to the plan.
struct AddToPlanSheet: View {
    let recipe: Recipe
    var defaultServings: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [AppSettings]

    @State private var day: Date = Calendar.current.startOfDay(for: .now)
    @State private var slot: MealSlot = .dinner
    @State private var servings: Int = 4
    @State private var saved = false

    private var settings: AppSettings { settingsList.first ?? AppSettings() }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if saved {
                    successView
                } else {
                    form
                }
            }
            .navigationTitle("Add to Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { servings = max(1, defaultServings) }
        }
        .presentationDetents([.medium, .large])
    }

    private var form: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                RecipeThumbnail(recipe: recipe, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name).font(.headline).foregroundStyle(Theme.primaryText)
                    RecipeMeta(recipe: recipe)
                }
                Spacer()
            }
            .cardSurface()

            VStack(spacing: 16) {
                DatePicker("Day", selection: $day, displayedComponents: .date)
                    .datePickerStyle(.compact)
                Divider().overlay(Theme.hairline)
                Picker("Meal", selection: $slot) {
                    ForEach(MealSlot.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                }
                .pickerStyle(.segmented)
                Divider().overlay(Theme.hairline)
                HStack {
                    Text("Servings").foregroundStyle(Theme.primaryText)
                    Spacer()
                    ServingsStepper(servings: $servings)
                }
            }
            .cardSurface()

            Spacer()

            Button {
                add()
            } label: {
                Label("Add to \(slot.rawValue)", systemImage: "calendar.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.terracotta, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.sage)
                .accessibilityHidden(true)
            Text("Added to your plan")
                .font(.title3.bold())
                .foregroundStyle(Theme.primaryText)
            Text("\(recipe.name) · \(slot.rawValue) · \(WeekHelper.fullDay.string(from: day))")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .task {
            try? await Task.sleep(for: .seconds(0.9))
            dismiss()
        }
    }

    private func add() {
        let store = PlanStore(context: context)
        store.assign(recipe: recipe, to: day, slot: slot, servings: servings)
        Haptics.success()
        withAnimation { saved = true }
    }
}
