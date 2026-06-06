import SwiftUI

/// Edit a single segment draft: kind, label, duration, and (if grouped) the repeat count.
/// Works on a local copy; commits via `onSave` only when the user taps Done.
struct SegmentEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var working: SegmentDraft
    let onSave: (SegmentDraft) -> Void

    init(draft: SegmentDraft, onSave: @escaping (SegmentDraft) -> Void) {
        _working = State(initialValue: draft)
        self.onSave = onSave
    }

    private var minutes: Int { working.duration / 60 }
    private var seconds: Int { working.duration % 60 }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Kind") {
                        Picker("Kind", selection: $working.kind) {
                            ForEach(SegmentKind.allCases) { kind in
                                Label(kind.title, systemImage: kind.symbol).tag(kind)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Section("Label") {
                        TextField(working.kind.title, text: $working.label)
                            .foregroundStyle(Brand.text)
                    }

                    Section {
                        durationStepper
                    } header: {
                        Text("Duration")
                    } footer: {
                        Text("Between 1 second and 60 minutes.")
                    }

                    if working.isInRepeatGroup {
                        Section {
                            Stepper(value: Binding(
                                get: { working.repeatCount },
                                set: { working.repeatCount = SegmentDraft.clampCount($0) }
                            ), in: 1...99) {
                                HStack {
                                    Text("Repeat group")
                                    Spacer()
                                    Text("×\(working.repeatCount)")
                                        .font(Brand.mono(15, weight: .semibold))
                                        .foregroundStyle(Brand.magic)
                                }
                            }
                        } footer: {
                            Text("This count applies to the whole group this segment belongs to.")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Segment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        var result = working
                        result.duration = SegmentDraft.clampDuration(result.duration)
                        result.repeatCount = SegmentDraft.clampCount(result.repeatCount)
                        onSave(result)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var durationStepper: some View {
        VStack(spacing: 12) {
            HStack {
                Text(DurationFormat.clock(working.duration))
                    .font(Brand.mono(34, weight: .semibold))
                    .foregroundStyle(working.kind.tint)
                    .monospacedDigit()
                    .accessibilityLabel("Duration \(DurationFormat.compact(working.duration))")
                Spacer()
            }
            HStack(spacing: 16) {
                Stepper(value: Binding(
                    get: { minutes },
                    set: { setDuration(minutes: $0, seconds: seconds) }
                ), in: 0...60) {
                    Text("\(minutes) min")
                        .foregroundStyle(Brand.text2)
                }
                Stepper(value: Binding(
                    get: { seconds },
                    set: { setDuration(minutes: minutes, seconds: $0) }
                ), in: 0...59, step: 5) {
                    Text("\(seconds) sec")
                        .foregroundStyle(Brand.text2)
                }
            }
            // Quick presets for common interval lengths.
            HStack(spacing: 8) {
                ForEach([15, 20, 30, 40, 60], id: \.self) { value in
                    Button("\(value)s") {
                        working.duration = SegmentDraft.clampDuration(value)
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(Brand.text)
                }
            }
        }
    }

    private func setDuration(minutes m: Int, seconds s: Int) {
        let total = max(1, m * 60 + s)
        working.duration = SegmentDraft.clampDuration(total)
    }
}

#Preview {
    SegmentEditView(draft: SegmentDraft(kind: .work, duration: 40, label: "Burpees",
                                        repeatGroupID: UUID(), repeatCount: 8)) { _ in }
}
