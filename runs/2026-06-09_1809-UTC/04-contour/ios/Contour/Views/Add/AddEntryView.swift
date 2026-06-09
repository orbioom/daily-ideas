import SwiftUI
import SwiftData
import PhotosUI

/// The shared Add sheet. Two segments: log a progress photo, or log a body
/// measurement without a photo. Inputs are validated (positive numbers) and a
/// brief success state is shown before dismissing.
struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("contour.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("contour.lengthUnit") private var lengthUnitRaw = LengthUnit.cm.rawValue
    @AppStorage("contour.defaultPose") private var defaultPoseRaw = Pose.front.rawValue

    private enum Segment: String, CaseIterable, Identifiable {
        case photo = "Photo"
        case metric = "Measurement"
        var id: String { rawValue }
    }

    @State private var segment: Segment = .photo

    // Photo entry
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var isDecoding = false
    @State private var pose: Pose = .front
    @State private var photoDate = Date()
    @State private var photoWeightText = ""
    @State private var photoNote = ""

    // Metric entry
    @State private var metricType: MetricType = .weight
    @State private var metricValueText = ""
    @State private var metricDate = Date()
    @State private var metricNote = ""

    @State private var didSucceed = false

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
    private var lengthUnit: LengthUnit { LengthUnit(rawValue: lengthUnitRaw) ?? .cm }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if didSucceed {
                    successState
                } else {
                    form
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { pose = Pose(rawValue: defaultPoseRaw) ?? .front }
        }
    }

    // MARK: - Success

    private var successState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Text("Saved")
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.text)
            Text("Your entry is stored on this device.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Saved. Your entry is stored on this device.")
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(spacing: 18) {
                Picker("Type", selection: $segment) {
                    ForEach(Segment.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                if segment == .photo {
                    photoSection
                } else {
                    metricSection
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Photo section

    private var photoSection: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                ZStack {
                    if let pickedImage {
                        Image(uiImage: pickedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        VStack(spacing: 10) {
                            if isDecoding {
                                ProgressView().tint(Brand.text2)
                                Text("Loading photo…").font(.subheadline).foregroundStyle(Brand.text2)
                            } else {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundStyle(Brand.magic)
                                Text("Choose a photo").font(.headline).foregroundStyle(Brand.text)
                                Text("Stored only on this device").font(.caption).foregroundStyle(Brand.text3)
                            }
                        }
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Brand.glassStroke.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [6])))
                    }
                }
            }
            .accessibilityLabel(pickedImage == nil ? "Choose a photo" : "Change photo")
            .onChange(of: pickerItem) { _, item in
                Task { await decode(item) }
            }

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Pose")
                FlowLayout(spacing: 8) {
                    ForEach(Pose.allCases) { p in
                        SelectChip(text: p.label, isSelected: pose == p, systemImage: p.symbol) {
                            Haptics.selection()
                            pose = p
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GlassCard {
                VStack(spacing: 12) {
                    DatePicker("Date", selection: $photoDate, displayedComponents: .date)
                    Divider().overlay(Brand.hairline)
                    HStack {
                        Text("Weight (\(weightUnit.short))")
                        Spacer()
                        TextField("optional", text: $photoWeightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 110)
                    }
                    Divider().overlay(Brand.hairline)
                    TextField("Note (optional)", text: $photoNote, axis: .vertical)
                        .lineLimit(1...3)
                }
            }

            if let warning = photoWarning {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(Brand.warn)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                savePhoto()
            } label: {
                Text("Save photo")
            }
            .buttonStyle(InkButtonStyle())
            .disabled(pickedImage == nil || photoWeightInvalid)
        }
    }

    private var photoWeightInvalid: Bool {
        let t = photoWeightText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return false }
        guard let v = Double(t) else { return true }
        return v <= 0
    }

    private var photoWarning: String? {
        if pickedImage == nil { return "Choose a photo to continue." }
        if photoWeightInvalid { return "Enter a positive weight, or leave it blank." }
        return nil
    }

    // MARK: - Metric section

    private var metricSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Measurement")
                FlowLayout(spacing: 8) {
                    ForEach(MetricType.allCases) { t in
                        SelectChip(text: t.label, isSelected: metricType == t, systemImage: t.symbol) {
                            Haptics.selection()
                            metricType = t
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GlassCard {
                VStack(spacing: 12) {
                    HStack {
                        Text("Value (\(metricSuffix))")
                        Spacer()
                        TextField("0", text: $metricValueText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 110)
                    }
                    Divider().overlay(Brand.hairline)
                    DatePicker("Date", selection: $metricDate, displayedComponents: .date)
                    Divider().overlay(Brand.hairline)
                    TextField("Note (optional)", text: $metricNote, axis: .vertical)
                        .lineLimit(1...3)
                }
            }

            if metricInvalid {
                Label("Enter a positive value.", systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(Brand.warn)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                saveMetric()
            } label: {
                Text("Save measurement")
            }
            .buttonStyle(InkButtonStyle())
            .disabled(metricInvalid || metricValueText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var metricSuffix: String {
        Units.suffix(for: metricType, weightUnit: weightUnit, lengthUnit: lengthUnit)
    }

    private var metricInvalid: Bool {
        let t = metricValueText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return false }
        guard let v = Double(t) else { return true }
        return v <= 0
    }

    // MARK: - Actions

    private func decode(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        await MainActor.run { isDecoding = true }
        let data = try? await item.loadTransferable(type: Data.self)
        let image = data.flatMap { UIImage(data: $0) }
        await MainActor.run {
            isDecoding = false
            if let image { pickedImage = image }
        }
    }

    private func savePhoto() {
        guard let image = pickedImage else { return }
        let filename = ImageStore.save(image) ?? ""
        var weight: Double? = nil
        let t = photoWeightText.trimmingCharacters(in: .whitespaces)
        if let v = Double(t), v > 0 {
            weight = Units.displayToKg(v, unit: weightUnit)
        }
        let photo = ProgressPhoto(date: photoDate, pose: pose, filename: filename,
                                  note: photoNote.trimmingCharacters(in: .whitespaces),
                                  weightAtTime: weight)
        context.insert(photo)

        // If the user entered a weight, also log it as a metric so trends update.
        if let weight {
            context.insert(BodyMetric(date: photoDate, type: .weight, value: weight))
        }
        try? context.save()
        finishSuccess()
    }

    private func saveMetric() {
        let t = metricValueText.trimmingCharacters(in: .whitespaces)
        guard let v = Double(t), v > 0 else { return }
        let canonical = Units.canonicalValue(v, type: metricType,
                                              weightUnit: weightUnit, lengthUnit: lengthUnit)
        let metric = BodyMetric(date: metricDate, type: metricType, value: canonical,
                                note: metricNote.trimmingCharacters(in: .whitespaces))
        context.insert(metric)
        try? context.save()
        finishSuccess()
    }

    private func finishSuccess() {
        Haptics.success()
        withAnimation(Brand.ease(0.25)) { didSucceed = true }
        Task {
            try? await Task.sleep(nanoseconds: 850_000_000)
            await MainActor.run { dismiss() }
        }
    }
}
