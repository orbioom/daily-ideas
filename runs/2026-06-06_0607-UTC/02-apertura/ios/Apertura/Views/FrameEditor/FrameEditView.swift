import SwiftUI
import SwiftData

/// Create or edit a frame. Shows live EV (from the roll's ISO) as settings change.
/// All numeric inputs are bounded > 0; text is trimmed on save.
struct FrameEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let roll: Roll
    /// nil = add a new frame; non-nil = edit existing.
    let frame: Frame?

    @State private var aperture: Double = 8
    @State private var shutterSeconds: Double = 1.0 / 250
    @State private var focalLengthMM: Double = 50
    @State private var subject: String = ""
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var didLoad = false

    private var isEditing: Bool { frame != nil }

    private var liveEV: Double? {
        Exposure.ev(aperture: aperture, shutterSeconds: shutterSeconds, iso: roll.iso)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    evCard
                    settingsCard
                    detailsCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Frame" : "Add Frame")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    // MARK: - Cards

    private var evCard: some View {
        GlassCard {
            HStack {
                MonoReadout(value: liveEV.map { Exposure.evString($0) } ?? "—",
                            caption: "EV at ISO \(Int(roll.iso.rounded()))",
                            size: 36)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Exposure.apertureString(aperture))
                        .font(Brand.mono(18, weight: .semibold))
                        .foregroundStyle(Brand.aperture)
                    Text(Exposure.shutterString(shutterSeconds))
                        .font(Brand.mono(18, weight: .semibold))
                        .foregroundStyle(Brand.shutter)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Computed exposure value")
            .accessibilityValue(liveEV.map { "EV \(Exposure.evString($0))" } ?? "Not available")
        }
    }

    private var settingsCard: some View {
        GlassCard {
            VStack(spacing: 18) {
                sliderRow(
                    title: "Aperture",
                    valueLabel: Exposure.apertureString(aperture),
                    tint: Brand.aperture,
                    systemImage: "camera.aperture",
                    value: Binding(
                        get: { 2.0 * log2(max(aperture, 0.5)) },
                        set: { aperture = pow(2.0, $0 / 2.0) }
                    ),
                    range: 0...12, step: 1.0/3.0,
                    a11yValue: Exposure.apertureString(aperture)
                )
                sliderRow(
                    title: "Shutter",
                    valueLabel: Exposure.shutterString(shutterSeconds),
                    tint: Brand.shutter,
                    systemImage: "timer",
                    value: Binding(
                        get: { -log2(max(shutterSeconds, 1.0/16000)) },
                        set: { shutterSeconds = pow(2.0, -$0) }
                    ),
                    range: -5...13, step: 1.0/3.0,
                    a11yValue: Exposure.shutterString(shutterSeconds)
                )
                sliderRow(
                    title: "Focal length",
                    valueLabel: "\(Int(focalLengthMM.rounded())) mm",
                    tint: Brand.text2,
                    systemImage: "scope",
                    value: $focalLengthMM,
                    range: 12...300, step: 1,
                    a11yValue: "\(Int(focalLengthMM.rounded())) millimetres"
                )
            }
        }
    }

    private var detailsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                labeledField(title: "Subject", text: $subject, prompt: "What's in frame")
                labeledField(title: "Location", text: $location, prompt: "Where you shot it")
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "Notes")
                    TextField("Anything worth remembering", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(10)
                        .background(Brand.glassStroke.opacity(0.2),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private func labeledField(title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: title)
            TextField(prompt, text: text)
                .textInputAutocapitalization(.sentences)
                .padding(10)
                .background(Brand.glassStroke.opacity(0.2),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func sliderRow(title: String, valueLabel: String, tint: Color,
                           systemImage: String, value: Binding<Double>,
                           range: ClosedRange<Double>, step: Double,
                           a11yValue: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.text2)
                    .labelStyle(.titleAndIcon)
                Spacer()
                Text(valueLabel)
                    .font(Brand.mono(16, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Slider(value: value, in: range, step: step)
                .tint(tint)
                .accessibilityLabel(title)
                .accessibilityValue(a11yValue)
        }
    }

    // MARK: - Load & save

    private func loadIfNeeded() {
        guard !didLoad else { return }
        if let frame {
            aperture = frame.aperture
            shutterSeconds = frame.shutterSeconds
            focalLengthMM = frame.focalLengthMM
            subject = frame.subject
            location = frame.location
            notes = frame.notes
        }
        didLoad = true
    }

    private func save() {
        let safeAperture = min(max(aperture, 1.0), 64.0)
        let safeShutter = min(max(shutterSeconds, 1.0/16000), 60.0)
        let safeFocal = min(max(focalLengthMM, 1.0), 2000.0)
        let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let frame {
            frame.aperture = safeAperture
            frame.shutterSeconds = safeShutter
            frame.focalLengthMM = safeFocal
            frame.subject = trimmedSubject
            frame.location = trimmedLocation
            frame.notes = trimmedNotes
        } else {
            let new = Frame(number: roll.nextFrameNumber,
                            aperture: safeAperture,
                            shutterSeconds: safeShutter,
                            focalLengthMM: safeFocal,
                            subject: trimmedSubject,
                            location: trimmedLocation,
                            notes: trimmedNotes)
            new.roll = roll
            roll.frames.append(new)
            context.insert(new)
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview {
    FrameEditView(roll: Roll(filmStock: "Tri-X 400", iso: 400), frame: nil)
        .environment(SettingsStore())
        .modelContainer(for: [Roll.self, Frame.self], inMemory: true)
}
