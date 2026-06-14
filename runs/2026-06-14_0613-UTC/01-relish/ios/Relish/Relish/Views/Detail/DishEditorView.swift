import SwiftUI
import SwiftData

/// Add or edit a dish (rating 1–5, would-order-again).
struct DishEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    let restaurant: Restaurant
    /// nil = adding new.
    let dish: Dish?

    @State private var name = ""
    @State private var rating = 4
    @State private var notes = ""
    @State private var wouldOrderAgain = true
    @State private var validationMessage: String?

    private var isEditing: Bool { dish != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dish") {
                    TextField("Dish name", text: $name)
                }
                Section("Rating") {
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                rating = i
                                Haptics.tap(settings.hapticsEnabled)
                            } label: {
                                Image(systemName: i <= rating ? "star.fill" : "star")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Theme.accent)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
                            .accessibilityAddTraits(i == rating ? .isSelected : [])
                        }
                        Spacer()
                    }
                    Toggle("Would order again", isOn: $wouldOrderAgain)
                }
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.bad)
                    }
                }
                if isEditing {
                    Section {
                        Button(role: .destructive) { deleteDish() } label: {
                            Label("Delete dish", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Dish" : "Add Dish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let dish {
            name = dish.name
            rating = dish.rating
            notes = dish.notes
            wouldOrderAgain = dish.wouldOrderAgain
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "Give the dish a name."
            Haptics.error(settings.hapticsEnabled)
            return
        }
        if let dish {
            dish.name = trimmed
            dish.rating = min(max(rating, 1), 5)
            dish.notes = notes
            dish.wouldOrderAgain = wouldOrderAgain
        } else {
            let newDish = Dish(name: trimmed, rating: rating, notes: notes, wouldOrderAgain: wouldOrderAgain)
            newDish.restaurant = restaurant
            restaurant.dishes.append(newDish)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func deleteDish() {
        if let dish {
            context.delete(dish)
            try? context.save()
        }
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
