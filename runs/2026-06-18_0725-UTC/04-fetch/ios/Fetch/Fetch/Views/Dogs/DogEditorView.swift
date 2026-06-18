import SwiftUI
import SwiftData
import PhotosUI

struct DogEditorView: View {
    var dog: Dog?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]

    @State private var name = ""
    @State private var breed = ""
    @State private var notes = ""
    @State private var hasBirthday = false
    @State private var birthdate = Date()
    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var photoFilename: String?
    @State private var isLoadingPhoto = false

    private var isEditing: Bool { dog != nil }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        photoPicker
                        Card {
                            VStack(spacing: 12) {
                                LabeledField(title: "Name", text: $name, prompt: "e.g. Cooper")
                                LabeledField(title: "Breed (optional)", text: $breed, prompt: "e.g. Golden Retriever")
                            }
                        }
                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $hasBirthday) {
                                    Text("Birthday")
                                        .font(Theme.rounded(15, .semibold))
                                        .foregroundStyle(Theme.ink)
                                }
                                .tint(Theme.accent)
                                if hasBirthday {
                                    DatePicker("Birthdate", selection: $birthdate, in: ...Date(), displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .tint(Theme.accent)
                                        .font(Theme.rounded(15))
                                }
                            }
                        }
                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(Theme.rounded(13, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                TextEditor(text: $notes)
                                    .font(Theme.rounded(15))
                                    .frame(minHeight: 90)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceAlt))
                            }
                        }
                        if isEditing {
                            Button(role: .destructive) { deleteDog() } label: {
                                Label("Delete dog", systemImage: "trash")
                                    .font(Theme.rounded(15, .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(Theme.bad)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.bad.opacity(0.1)))
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(isEditing ? "Edit Dog" : "New Dog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadExisting)
            .onChange(of: photoItem) { _, newItem in
                loadPhoto(newItem)
            }
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack {
                if let photoImage {
                    Image(uiImage: photoImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Theme.heroGradient
                    VStack(spacing: 6) {
                        Image(systemName: isLoadingPhoto ? "hourglass" : "camera.fill")
                            .font(.system(size: 26, weight: .semibold))
                        Text(isLoadingPhoto ? "Loading\u{2026}" : "Add photo")
                            .font(Theme.rounded(13, .semibold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(width: 110, height: 110)
            .clipShape(Circle())
            .overlay(Circle().stroke(Theme.surface, lineWidth: 3))
        }
        .accessibilityLabel("Choose a photo for this dog")
    }

    private func loadExisting() {
        guard let d = dog else { return }
        name = d.name
        breed = d.breed
        notes = d.notes
        photoFilename = d.photoFilename
        photoImage = ImageStore.load(d.photoFilename)
        if let bd = d.birthdate {
            hasBirthday = true
            birthdate = bd
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isLoadingPhoto = true
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            await MainActor.run {
                isLoadingPhoto = false
                guard let data, let image = UIImage(data: data) else { return }
                photoImage = image
                // Persist the file now; clean up an old file if we're replacing.
                if let old = photoFilename { ImageStore.delete(old) }
                photoFilename = ImageStore.save(image)
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let bd: Date? = hasBirthday ? birthdate : nil

        if let d = dog {
            d.name = trimmed
            d.breed = breed.trimmingCharacters(in: .whitespaces)
            d.notes = notes
            d.birthdate = bd
            d.photoFilename = photoFilename
        } else {
            let newDog = Dog(
                name: trimmed,
                breed: breed.trimmingCharacters(in: .whitespaces),
                birthdate: bd,
                photoFilename: photoFilename,
                notes: notes,
                isActive: dogs.isEmpty
            )
            context.insert(newDog)
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func deleteDog() {
        guard let d = dog else { return }
        ImageStore.delete(d.photoFilename)
        context.delete(d)
        try? context.save()
        // Re-balance active flag after deletion.
        let remaining = dogs.filter { $0.id != d.id }
        DogManager.normalizeActive(remaining, context: context)
        Haptics.warning(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
