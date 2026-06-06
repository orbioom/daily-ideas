import SwiftUI
import SwiftData

/// One roll: its metadata, an ordered list of frames, add-frame, edit, delete, export.
struct RollDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var roll: Roll

    @State private var showingNewFrame = false
    @State private var editingFrame: Frame?
    @State private var showingEditRoll = false
    @State private var showingDeleteConfirm = false

    private var frames: [Frame] { roll.orderedFrames }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                framesSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(roll.filmStock)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditRoll = true
                    } label: {
                        Label("Edit roll", systemImage: "pencil")
                    }
                    ShareLink(item: RollExport.csv(for: roll), preview: SharePreview("Export CSV")) {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                    ShareLink(item: RollExport.json(for: roll), preview: SharePreview("Export JSON")) {
                        Label("Export JSON", systemImage: "curlybraces")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete roll", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Roll actions")
            }
        }
        .sheet(isPresented: $showingNewFrame) {
            FrameEditView(roll: roll, frame: nil)
        }
        .sheet(item: $editingFrame) { frame in
            FrameEditView(roll: roll, frame: frame)
        }
        .sheet(isPresented: $showingEditRoll) {
            RollEditView(roll: roll)
        }
        .alert("Delete this roll?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteRoll() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The roll and all \(roll.frames.count) of its frames will be permanently removed.")
        }
    }

    // MARK: - Header

    private var header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    FormatBadge(format: roll.format)
                    Text("ISO \(Int(roll.iso.rounded()))")
                        .font(Brand.mono(14, weight: .semibold))
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    if roll.isFinished {
                        Label("Developed", systemImage: "checkmark.seal.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.live)
                            .labelStyle(.titleAndIcon)
                    }
                }

                if !roll.camera.isEmpty {
                    detailRow(icon: "camera", text: roll.camera)
                }
                detailRow(icon: "number", text: "\(roll.frames.count) frame\(roll.frames.count == 1 ? "" : "s") logged")

                if !roll.notes.isEmpty {
                    Text(roll.notes)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                InkButton(title: "Add frame", systemImage: "plus") {
                    showingNewFrame = true
                }
            }
        }
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Brand.text3)
                .frame(width: 18)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
    }

    // MARK: - Frames

    private var framesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Frames")
                .padding(.horizontal, 4)

            if frames.isEmpty {
                GlassCard {
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.dashed")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(Brand.text3)
                            .accessibilityHidden(true)
                        Text("No frames yet")
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                        Text("Add your first frame to record the aperture, shutter, and subject.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                ForEach(frames) { frame in
                    Button {
                        editingFrame = frame
                    } label: {
                        FrameRow(frame: frame)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(frame)
                        } label: {
                            Label("Delete frame", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mutations

    private func delete(_ frame: Frame) {
        context.delete(frame)
        Haptics.impact(enabled: settings.hapticsEnabled)
    }

    private func deleteRoll() {
        context.delete(roll)
        Haptics.warning(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

/// A single frame row: number, settings, computed EV, and subject.
private struct FrameRow: View {
    var frame: Frame

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text("#\(frame.number)")
                        .font(Brand.mono(16, weight: .bold))
                        .foregroundStyle(Brand.text)
                    if let ev = frame.ev {
                        Text("EV \(Exposure.evString(ev))")
                            .font(Brand.mono(11, weight: .semibold))
                            .foregroundStyle(Brand.text3)
                    }
                }
                .frame(width: 56)

                Divider().overlay(Brand.glassStroke.opacity(0.4)).frame(height: 38)

                VStack(alignment: .leading, spacing: 3) {
                    Text(frame.subject.isEmpty ? "Untitled frame" : frame.subject)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(frame.subject.isEmpty ? Brand.text3 : Brand.text)
                        .lineLimit(1)
                    HStack(spacing: 10) {
                        Text(Exposure.apertureString(frame.aperture))
                            .foregroundStyle(Brand.aperture)
                        Text(Exposure.shutterString(frame.shutterSeconds))
                            .foregroundStyle(Brand.shutter)
                        Text("\(Int(frame.focalLengthMM.rounded()))mm")
                            .foregroundStyle(Brand.text3)
                    }
                    .font(Brand.mono(13, weight: .medium))
                    if !frame.location.isEmpty {
                        Text(frame.location)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityHint("Opens the frame editor")
    }

    private var label: String {
        var parts = ["Frame \(frame.number)"]
        if !frame.subject.isEmpty { parts.append(frame.subject) }
        parts.append(Exposure.apertureString(frame.aperture))
        parts.append("at \(Exposure.shutterString(frame.shutterSeconds))")
        if let ev = frame.ev { parts.append("EV \(Exposure.evString(ev))") }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    RollDetailPreview()
}

private struct RollDetailPreview: View {
    @State private var settings = SettingsStore()

    var body: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: Roll.self, Frame.self, configurations: config) {
            let roll = Roll(filmStock: "Kodak Portra 400", iso: 400, camera: "Nikon FE2")
            container.mainContext.insert(roll)
            return AnyView(
                NavigationStack {
                    RollDetailView(roll: roll)
                }
                .environment(settings)
                .modelContainer(container)
            )
        } else {
            return AnyView(Text("Preview unavailable"))
        }
    }
}
