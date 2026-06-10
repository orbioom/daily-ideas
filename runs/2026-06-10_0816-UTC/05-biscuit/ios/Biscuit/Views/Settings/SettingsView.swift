import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @AppStorage("selectedDogID") private var selectedDogID = ""
    @AppStorage("clickerSound") private var clickerSound = true
    @AppStorage("clickerHaptics") private var clickerHaptics = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @State private var showAddDog = false
    @State private var editTarget: Dog?
    @State private var deleteTarget: Dog?

    var body: some View {
        NavigationStack {
            Form {
                Section("Dogs") {
                    ForEach(dogs) { dog in
                        Button {
                            editTarget = dog
                        } label: {
                            HStack {
                                Text(dog.emoji)
                                Text(dog.name).foregroundStyle(Brand.text)
                                if dog.uuid.uuidString == selectedDogID {
                                    StatusDot()
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Brand.text3)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if dogs.count > 1 {
                                Button(role: .destructive) {
                                    deleteTarget = dog
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    Button {
                        showAddDog = true
                    } label: {
                        Label("Add a dog", systemImage: "plus.circle.fill")
                    }
                }

                Section("Clicker") {
                    Toggle("Click sound", isOn: $clickerSound)
                        .tint(Brand.live)
                    Toggle("Click haptic", isOn: $clickerHaptics)
                        .tint(Brand.live)
                    Text("The click is synthesized on device — it works with the phone on silent if haptics are on.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Feel") {
                    Toggle("App haptics", isOn: $hapticsEnabled)
                        .tint(Brand.live)
                }

                Section("About") {
                    LabeledContent("App", value: "Biscuit 1.0")
                    LabeledContent("Made by", value: "Orbioom")
                    LabeledContent("Method", value: "Positive reinforcement")
                    Text("Everything lives on this device. No subscription, no account, no streak-shaming notifications.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddDog) {
                DogEditorView(dog: nil) { newID in selectedDogID = newID }
            }
            .sheet(item: $editTarget) { dog in
                DogEditorView(dog: dog)
            }
            .alert("Delete this dog?", isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let d = deleteTarget {
                        let wasSelected = d.uuid.uuidString == selectedDogID
                        context.delete(d)
                        if wasSelected {
                            selectedDogID = dogs.first(where: { $0 != d })?.uuid.uuidString ?? ""
                        }
                        Haptics.warning()
                    }
                    deleteTarget = nil
                }
                Button("Cancel", role: .cancel) { deleteTarget = nil }
            } message: {
                Text("All of this dog's skill progress and sessions are removed.")
            }
        }
    }
}

struct DogEditorView: View {
    let dog: Dog?
    var onCreate: ((String) -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private static let emojiChoices = ["🐶", "🐕", "🦮", "🐩", "🐕‍🦺", "🌭"]

    @State private var name = ""
    @State private var breed = ""
    @State private var emoji = "🐶"
    @State private var knowBirthday = false
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
    @State private var error: String?
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Avatar") {
                    HStack(spacing: 8) {
                        ForEach(Self.emojiChoices, id: \.self) { choice in
                            Button {
                                emoji = choice
                                Haptics.selection()
                            } label: {
                                Text(choice)
                                    .font(.title2)
                                    .padding(6)
                                    .background(emoji == choice ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear), in: Circle())
                                    .overlay(Circle().strokeBorder(emoji == choice ? Brand.live : Color.clear, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Avatar \(choice)")
                        }
                    }
                }
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Breed (optional)", text: $breed)
                    Toggle("Know their birthday", isOn: $knowBirthday)
                        .tint(Brand.live)
                    if knowBirthday {
                        DatePicker("Birthday", selection: $birthDate,
                                   in: ...Date.now, displayedComponents: .date)
                    }
                }
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Brand.danger)
                    }
                }
            }
            .navigationTitle(dog == nil ? "Add Dog" : "Edit Dog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let dog {
                    name = dog.name
                    breed = dog.breed
                    emoji = dog.emoji
                    if let bd = dog.birthDate {
                        knowBirthday = true
                        birthDate = bd
                    }
                }
            }
        }
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else {
            error = "Your dog needs a name."
            return
        }
        if let dog {
            dog.name = n
            dog.breed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
            dog.emoji = emoji
            dog.birthDate = knowBirthday ? birthDate : nil
        } else {
            let d = Dog(name: n, breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
                        birthDate: knowBirthday ? birthDate : nil, emoji: emoji)
            context.insert(d)
            onCreate?(d.uuid.uuidString)
        }
        Haptics.success()
        dismiss()
    }
}
