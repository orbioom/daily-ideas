import SwiftUI
import SwiftData

/// Edit basic fields of a restaurant (not its ranking — use Re-rank for that).
struct EditRestaurantView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Bindable var restaurant: Restaurant

    @State private var name: String = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Restaurant name", text: $name)
                    Picker("Cuisine", selection: $restaurant.cuisine) {
                        ForEach(Cuisine.allCases) { c in
                            Label(c.rawValue, systemImage: c.symbol).tag(c)
                        }
                    }
                    TextField("City", text: $restaurant.city)
                    Picker("Price", selection: $restaurant.priceTier) {
                        ForEach(1...4, id: \.self) { p in
                            Text(String(repeating: "$", count: p)).tag(p)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $restaurant.notes, axis: .vertical)
                        .lineLimit(2...5)
                }
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear { name = restaurant.name }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "Name can't be empty."
            Haptics.error(settings.hapticsEnabled)
            return
        }
        restaurant.name = trimmed
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
