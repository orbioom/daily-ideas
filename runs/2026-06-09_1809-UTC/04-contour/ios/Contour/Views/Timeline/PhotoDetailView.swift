import SwiftUI
import SwiftData

struct PhotoDetailView: View {
    @Bindable var photo: ProgressPhoto

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("contour.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue

    @State private var showDeleteConfirm = false
    @State private var showEditor = false

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PhotoImageView(filename: photo.filename, contentMode: .fit,
                               accessibilityText: "\(photo.pose.label) pose, \(Format.relativeDay(photo.date))")
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 280, maxHeight: 460)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        TagChip(text: photo.pose.label, systemImage: photo.pose.symbol, tint: Brand.magic)
                        Spacer()
                        Text(Format.relativeDay(photo.date))
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    }

                    if let w = photo.weightAtTime {
                        HStack {
                            Eyebrow(text: "Weight")
                            Spacer()
                            Text(Units.formattedWeight(w, unit: weightUnit))
                                .font(Brand.mono(16, weight: .semibold))
                                .foregroundStyle(Brand.text)
                        }
                    }

                    if !photo.note.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Eyebrow(text: "Note")
                            Text(photo.note)
                                .font(.body)
                                .foregroundStyle(Brand.text)
                        }
                    }
                }
                .glassCard()

                VStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        showEditor = true
                    } label: {
                        Label("Edit details", systemImage: "pencil")
                    }
                    .buttonStyle(GlassButtonStyle())

                    Button(role: .destructive) {
                        Haptics.warning()
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete photo", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(Brand.danger)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Brand.danger.opacity(0.4), lineWidth: 1))
                    }
                }
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle(Format.shortDay.string(from: photo.date))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditor) {
            PhotoEditorView(photo: photo)
        }
        .confirmationDialog("Delete this photo?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the photo and its file from this device. This can't be undone.")
        }
    }

    private func performDelete() {
        if photo.hasImage { ImageStore.delete(photo.filename) }
        context.delete(photo)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

/// Edits a photo's pose / date / weight / note (not the image itself).
struct PhotoEditorView: View {
    @Bindable var photo: ProgressPhoto
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("contour.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue

    @State private var weightText: String = ""
    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pose") {
                    Picker("Pose", selection: $photo.poseRaw) {
                        ForEach(Pose.allCases) { p in
                            Label(p.label, systemImage: p.symbol).tag(p.rawValue)
                        }
                    }
                }
                Section("Date") {
                    DatePicker("Taken", selection: $photo.date, displayedComponents: .date)
                }
                Section("Weight (\(weightUnit.short), optional)") {
                    TextField("Weight", text: $weightText)
                        .keyboardType(.decimalPad)
                }
                Section("Note") {
                    TextField("Note", text: $photo.note, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle("Edit Photo")
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
                if let w = photo.weightAtTime {
                    weightText = Units.formattedWeight(w, unit: weightUnit, showUnit: false)
                }
            }
        }
    }

    private func save() {
        let trimmed = weightText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            photo.weightAtTime = nil
        } else if let entered = Double(trimmed), entered > 0 {
            photo.weightAtTime = Units.displayToKg(entered, unit: weightUnit)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
