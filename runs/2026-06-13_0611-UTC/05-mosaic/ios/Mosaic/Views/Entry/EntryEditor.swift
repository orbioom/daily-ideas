import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct EntryEditor: View {
    let day: Date
    let existing: DayEntry?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var mood = 3
    @State private var caption = ""
    @State private var fileName: String?
    @State private var previewImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var loadingPhoto = false

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Text(isToday ? "Today" : day.formatted(.dateTime.weekday(.wide).month().day().year()))
                        .font(Theme.rounded(20)).foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    photoArea

                    VStack(alignment: .leading, spacing: 10) {
                        Text("How was the day?").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                        MoodPicker(selection: $mood)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("A line about it").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                        TextField("What happened today?", text: $caption, axis: .vertical)
                            .lineLimit(2...6)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt))
                    }

                    if existing != nil {
                        Button(role: .destructive) { deleteEntry() } label: {
                            Label("Delete this day", systemImage: "trash")
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt))
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.fontWeight(.bold) }
            }
            .onAppear(perform: load)
            .onChange(of: pickerItem) { _, item in importPhoto(item) }
        }
    }

    private var photoArea: some View {
        PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
            ZStack {
                if let previewImage {
                    Image(uiImage: previewImage).resizable().scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 20).fill(Theme.surfaceAlt)
                    VStack(spacing: 8) {
                        Image(systemName: loadingPhoto ? "hourglass" : "camera.fill")
                            .font(.system(size: 30)).foregroundStyle(Theme.accent)
                        Text(loadingPhoto ? "Adding…" : "Add a photo").font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .frame(height: 240)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .topTrailing) {
                if previewImage != nil {
                    Image(systemName: "pencil.circle.fill").font(.system(size: 26))
                        .foregroundStyle(.white, Theme.accent).padding(10)
                }
            }
        }
        .accessibilityLabel(previewImage == nil ? "Add a photo" : "Change photo")
    }

    private func load() {
        guard let existing else { return }
        mood = existing.moodIndex
        caption = existing.caption
        fileName = existing.photoFileName
        previewImage = ImageStore.load(existing.photoFileName)
    }

    private func importPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        loadingPhoto = true
        Task {
            defer { loadingPhoto = false }
            if let data = try? await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data),
               let name = ImageStore.save(ui) {
                ImageStore.delete(fileName)   // remove the old one
                await MainActor.run {
                    fileName = name
                    previewImage = ui
                    Haptics.tap()
                }
            }
        }
    }

    private func save() {
        if let existing {
            existing.moodIndex = mood
            existing.caption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.photoFileName = fileName
            existing.updatedAt = .now
        } else {
            let entry = DayEntry(day: day, caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
                                 moodIndex: mood, photoFileName: fileName)
            context.insert(entry)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func deleteEntry() {
        if let existing {
            ImageStore.delete(existing.photoFileName)
            context.delete(existing)
            try? context.save()
        }
        Haptics.tap()
        dismiss()
    }
}
