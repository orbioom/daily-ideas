import SwiftUI
import SwiftData

struct FavoritePlacesView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \FavoritePlace.name) private var places: [FavoritePlace]

    @State private var editing: FavoritePlace?
    @State private var showEditor = false
    @State private var toast: String?
    @State private var deleteError: String?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if places.isEmpty {
                EmptyStateView(icon: "star.fill",
                               title: "No favorite places",
                               message: "Save common destinations for one-tap round-trip logging.",
                               actionTitle: "Add place") {
                    editing = nil
                    showEditor = true
                }
            } else {
                List {
                    Section {
                        ForEach(places) { place in
                            Button {
                                editing = place
                                showEditor = true
                            } label: {
                                row(place)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.surface)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { delete(place) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } footer: {
                        Text("Distances are stored in miles and shown in your chosen unit when logging.")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Favorite Places")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = nil
                    showEditor = true
                    Haptics.impact(settings.hapticsEnabled)
                } label: {
                    Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                }
                .accessibilityLabel("Add place")
            }
        }
        .sheet(isPresented: $showEditor) {
            FavoritePlaceEditorView(place: editing) {
                toast = editing == nil ? "Place added" : "Place updated"
            }
        }
        .toast($toast)
        .alert("Couldn't delete place", isPresented: .constant(deleteError != nil)) {
            Button("OK") { deleteError = nil }
        } message: { Text(deleteError ?? "") }
    }

    private func row(_ place: FavoritePlace) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(place.name)
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(settings.distance(place.defaultMiles))
                .font(Theme.mono(14, .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(place.name), \(settings.distance(place.defaultMiles)) one way")
    }

    private func delete(_ place: FavoritePlace) {
        Haptics.impact(settings.hapticsEnabled, style: .medium)
        context.delete(place)
        do {
            try context.save()
            toast = "Place deleted"
        } catch {
            deleteError = "Please try again."
        }
    }
}

struct FavoritePlaceEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let place: FavoritePlace?
    let onSave: () -> Void

    @State private var name = ""
    @State private var milesText = ""
    @State private var saveError: String?

    private var parsedMiles: Double? {
        guard let v = Double(milesText.replacingOccurrences(of: ",", with: ".")), v >= 0 else { return nil }
        return settings.distanceUnit.toMiles(v)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (parsedMiles ?? -1) >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Place") {
                    TextField("Name (e.g. Airport)", text: $name)
                    HStack {
                        Text("One-way distance (\(settings.distanceUnit.shortLabel))")
                        Spacer()
                        TextField("0.0", text: $milesText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.mono(15, .semibold))
                            .frame(maxWidth: 110)
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(place == nil ? "Add Place" : "Edit Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold).disabled(!canSave)
                }
            }
            .onAppear(perform: loadInitial)
            .alert("Couldn't save", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: { Text(saveError ?? "") }
        }
    }

    private func loadInitial() {
        if let place {
            name = place.name
            milesText = String(format: "%.1f", settings.distanceUnit.fromMiles(place.defaultMiles))
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let miles = parsedMiles else {
            saveError = "Please enter a name and a valid distance."
            return
        }
        let target = place ?? FavoritePlace(name: trimmed)
        target.name = trimmed
        target.defaultMiles = miles
        if place == nil { context.insert(target) }
        do {
            try context.save()
            Haptics.success(settings.hapticsEnabled)
            onSave()
            dismiss()
        } catch {
            saveError = "Something went wrong. Please try again."
        }
    }
}
