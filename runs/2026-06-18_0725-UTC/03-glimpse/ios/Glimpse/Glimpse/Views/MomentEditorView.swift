import SwiftUI
import SwiftData
import PhotosUI

/// Create or edit a moment: photo picker, title, caption, mood, tags.
/// Validates input, writes the image to the ImageStore, and persists to SwiftData.
struct MomentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    /// The day this moment belongs to.
    let dayKey: String
    /// Existing moment to edit, or nil to create.
    var existing: Moment?
    /// Called after a successful save (used by Today to flash success).
    var onSaved: ((Moment) -> Void)?

    @State private var title = ""
    @State private var caption = ""
    @State private var mood: Mood = .good
    @State private var tagsText = ""
    @State private var isFavorite = false

    @State private var pickerItem: PhotosPickerItem?
    /// The image filename currently attached (persisted file name).
    @State private var imageFilename: String?
    /// A freshly imported image not yet committed; shown immediately.
    @State private var pendingImage: UIImage?
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showPaywall = false

    private var isEditing: Bool { existing != nil }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f
    }()

    private var parsedTags: [String] {
        let raw = tagsText
            .split(whereSeparator: { $0 == "," || $0 == " " || $0 == "#" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        // De-duplicate, preserve order.
        var seen = Set<String>()
        var ordered: [String] = []
        for tag in raw where !seen.contains(tag) {
            seen.insert(tag)
            ordered.append(tag)
        }
        let limit = isPro ? 24 : Pro.freeTagLimit
        return Array(ordered.prefix(limit))
    }

    private var canSave: Bool {
        // A moment needs at least a photo or some text.
        pendingImage != nil
            || (imageFilename?.isEmpty == false)
            || !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    photoSection
                    moodSection
                    textSection
                    tagSection
                    favoriteToggle
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Edit moment" : "New moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(Theme.inkSoft)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(Theme.rounded(16, .semibold))
                        .disabled(!canSave || isImporting)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Couldn't add photo", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK", role: .cancel) { importError = nil }
            } message: {
                Text(importError ?? "Please try a different photo.")
            }
            .onAppear(perform: loadExisting)
            .onChange(of: pickerItem) { _, newValue in
                guard let newValue else { return }
                Task { await importImage(newValue) }
            }
        }
    }

    // MARK: - Sections

    private var photoSection: some View {
        VStack(spacing: 10) {
            ZStack {
                if let pendingImage {
                    Image(uiImage: pendingImage)
                        .resizable()
                        .scaledToFill()
                } else if let imageFilename, !imageFilename.isEmpty {
                    MomentImageView(filename: imageFilename, pointSize: 600, cornerRadius: 0, fullResolution: false)
                } else {
                    ZStack {
                        Theme.heroGradient.opacity(0.16)
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 30))
                                .foregroundStyle(Theme.accent)
                            Text("Add today's photo")
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                if isImporting {
                    Color.black.opacity(0.25)
                    ProgressView().tint(.white)
                }
            }
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )

            HStack(spacing: 10) {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Label(hasImage ? "Change photo" : "Choose photo", systemImage: "photo")
                        .font(Theme.rounded(15, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .foregroundStyle(Theme.ink)
                }
                if hasImage {
                    Button(role: .destructive) {
                        Haptics.tap(settings.hapticsEnabled)
                        pendingImage = nil
                        imageFilename = nil
                        pickerItem = nil
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 46, height: 46)
                            .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .foregroundStyle(Theme.bad)
                    }
                    .accessibilityLabel("Remove photo")
                }
            }
        }
    }

    private var hasImage: Bool {
        pendingImage != nil || (imageFilename?.isEmpty == false)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How did it feel?")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 8) {
                ForEach(Mood.allCases) { option in
                    Button {
                        Haptics.selection(settings.hapticsEnabled)
                        mood = option
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: option.symbol)
                                .font(.system(size: 18, weight: .semibold))
                            Text(option.label)
                                .font(Theme.rounded(11, .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(mood == option ? .white : Theme.inkSoft)
                        .background(
                            mood == option ? AnyShapeStyle(option.color) : AnyShapeStyle(Theme.surfaceAlt),
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.label)
                    .accessibilityAddTraits(mood == option ? .isSelected : [])
                }
            }
        }
        .padding(14)
        .cardSurface()
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Title (optional)")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                TextField("Give the day a name", text: $title)
                    .font(Theme.rounded(17, .semibold))
                    .textInputAutocapitalization(.sentences)
            }
            Divider().overlay(Theme.hairline)
            VStack(alignment: .leading, spacing: 6) {
                Text("Caption")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                TextField("What made this moment?", text: $caption, axis: .vertical)
                    .font(Theme.bodyFont)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
            }
        }
        .padding(14)
        .cardSurface()
    }

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if !isPro {
                    Text("up to \(Pro.freeTagLimit) free")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            TextField("calm, home, coffee", text: $tagsText)
                .font(Theme.bodyFont)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !parsedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(parsedTags, id: \.self) { TagChip(tag: $0) }
                    }
                }
            }
            if !isPro {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock unlimited tags", systemImage: "sparkles")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .cardSurface()
    }

    private var favoriteToggle: some View {
        Toggle(isOn: $isFavorite) {
            Label("Mark as favorite", systemImage: isFavorite ? "heart.fill" : "heart")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .tint(Theme.accent)
        .padding(14)
        .cardSurface()
    }

    // MARK: - Logic

    private func loadExisting() {
        guard let existing else {
            mood = settings.defaultMood
            return
        }
        title = existing.title
        caption = existing.caption
        mood = existing.mood
        tagsText = existing.tags.joined(separator: ", ")
        isFavorite = existing.isFavorite
        imageFilename = existing.imageFilename
    }

    private func importImage(_ item: PhotosPickerItem) async {
        isImporting = true
        defer { isImporting = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                importError = "That photo couldn't be read."
                return
            }
            guard let uiImage = UIImage(data: data) else {
                importError = "That file isn't a supported image."
                return
            }
            pendingImage = uiImage
            Haptics.tap(settings.hapticsEnabled)
        } catch {
            importError = "Something went wrong importing the photo."
        }
    }

    private func save() {
        // Resolve the final image filename.
        var finalFilename = imageFilename
        if let pendingImage {
            if let saved = ImageStore.shared.save(pendingImage) {
                // Remove a previously attached file we're replacing.
                if let old = existing?.imageFilename, old != saved {
                    ImageStore.shared.delete(old)
                }
                finalFilename = saved
            } else {
                importError = "Couldn't save the photo to your library. Please try again."
                return
            }
        } else if existing?.imageFilename != nil && imageFilename == nil {
            // User removed the photo.
            ImageStore.shared.delete(existing?.imageFilename)
            finalFilename = nil
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)

        let target: Moment
        if let existing {
            target = existing
        } else {
            target = Moment(dayKey: dayKey)
            context.insert(target)
        }
        target.title = cleanTitle
        target.caption = cleanCaption
        target.mood = mood
        target.tags = parsedTags
        target.isFavorite = isFavorite
        target.imageFilename = finalFilename

        do {
            try context.save()
            Haptics.success(settings.hapticsEnabled)
            onSaved?(target)
            dismiss()
        } catch {
            importError = "Couldn't save your moment. Please try again."
        }
    }
}
