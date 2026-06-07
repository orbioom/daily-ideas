import SwiftUI
import SwiftData

/// Create / edit an instrument's identity: name, type and scale length. Strings
/// are edited in the detail view. Validates the name and scale length and shows
/// a calm inline message when something is off.
struct InstrumentEditSheet: View {
    @Bindable var instrument: Instrument
    var isNew: Bool
    /// Called when the user cancels a brand-new instrument so the caller can
    /// remove the freshly-inserted (uncommitted) object.
    var onCancelNew: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var scaleText: String = ""

    private var trimmedName: String {
        instrument.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedScale: Double? {
        Double(scaleText.replacingOccurrences(of: ",", with: "."))
    }

    private var validation: String? {
        if trimmedName.isEmpty { return "Give the instrument a name." }
        guard let scale = parsedScale else { return "Enter a scale length in inches." }
        if scale <= 0 { return "Scale length must be greater than zero." }
        if scale > 40 { return "Scale length must be 40 inches or less." }
        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionTitle(text: "Name")
                                TextField("Instrument name", text: $instrument.name)
                                    .textInputAutocapitalization(.words)
                                    .font(.body)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitle(text: "Type")
                                Picker("Type", selection: typeBinding) {
                                    ForEach(InstrumentType.allCases) { type in
                                        Text(type.label).tag(type)
                                    }
                                }
                                .pickerStyle(.navigationLink)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: "Scale length (inches)")
                                TextField("25.5", text: $scaleText)
                                    .keyboardType(.decimalPad)
                                    .font(Brand.mono(17, weight: .medium))
                                Text("The vibrating length from nut to bridge saddle. Longer scales raise tension at the same pitch.")
                                    .font(.caption)
                                    .foregroundStyle(Brand.text3)
                            }
                        }

                        if let validation {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                Text(validation)
                            }
                            .font(.footnote)
                            .foregroundStyle(Brand.warn)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let notesValidation = notesHint {
                            Text(notesValidation)
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: "Notes")
                                TextField("Optional notes", text: $instrument.notes, axis: .vertical)
                                    .lineLimit(2...4)
                                    .font(.body)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(isNew ? "New Instrument" : "Edit Instrument")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(validation != nil)
                }
            }
            .onAppear {
                scaleText = String(format: "%g", instrument.scaleLengthIn)
            }
        }
        .interactiveDismissDisabled(isNew)
    }

    private var typeBinding: Binding<InstrumentType> {
        Binding(get: { instrument.type },
                set: { instrument.type = $0 })
    }

    private var notesHint: String? {
        isNew ? "A standard .010–.046 set in E tuning is applied; tune it in the detail view." : nil
    }

    private func save() {
        guard validation == nil, let scale = parsedScale else { return }
        instrument.scaleLengthIn = scale
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func cancel() {
        if isNew { onCancelNew() }
        dismiss()
    }
}
