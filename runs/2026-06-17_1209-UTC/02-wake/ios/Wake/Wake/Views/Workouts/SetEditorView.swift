import SwiftUI

/// Edit a single draft set: repeats × distance × stroke × send-off × effort.
struct SetEditorView: View {
    @State private var draft: DraftSet
    let unit: DistanceUnit
    let onDone: (DraftSet) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var distanceText: String
    @State private var useSendOff: Bool
    @State private var sendOffText: String
    @State private var restText: String

    init(draft: DraftSet, unit: DistanceUnit, onDone: @escaping (DraftSet) -> Void) {
        _draft = State(initialValue: draft)
        self.unit = unit
        self.onDone = onDone
        let displayDistance = unit.value(fromMeters: draft.distance)
        _distanceText = State(initialValue: String(Int(displayDistance.rounded())))
        _useSendOff = State(initialValue: draft.sendOff > 0)
        _sendOffText = State(initialValue: draft.sendOff > 0 ? "\(draft.sendOff)" : "90")
        _restText = State(initialValue: "\(max(0, draft.rest))")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Repeats") {
                    Stepper(value: $draft.repeats, in: 1...60) {
                        Text("\(draft.repeats) reps")
                    }
                }
                Section("Distance per rep (\(unit.shortUnit))") {
                    TextField("Distance", text: $distanceText)
                        .keyboardType(.numberPad)
                }
                Section("Stroke") {
                    Picker("Stroke", selection: $draft.stroke) {
                        ForEach(Stroke.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                }
                Section("Effort") {
                    Picker("Effort", selection: $draft.effort) {
                        ForEach(Effort.allCases) { e in
                            Text(e.label).tag(e)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Toggle("Use send-off interval", isOn: $useSendOff)
                    if useSendOff {
                        HStack {
                            Text("Send-off (seconds)")
                            Spacer()
                            TextField("90", text: $sendOffText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                        }
                        Text("Each rep leaves on this interval, e.g. 105s = 1:45.")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                    } else {
                        HStack {
                            Text("Rest after each rep (s)")
                            Spacer()
                            TextField("20", text: $restText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                        }
                    }
                } header: {
                    Text("Interval")
                }
                Section("Note") {
                    TextField("e.g. build to fast", text: $draft.note)
                }
            }
            .navigationTitle("Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { commit() }
                        .fontWeight(.semibold)
                        .disabled(parsedDistanceMeters <= 0)
                }
            }
        }
    }

    private var parsedDistanceMeters: Double {
        let value = Double(distanceText.trimmingCharacters(in: .whitespaces)) ?? 0
        return unit.meters(fromValue: max(0, value))
    }

    private func commit() {
        var result = draft
        result.distance = parsedDistanceMeters
        guard result.distance > 0 else { return }
        if useSendOff {
            result.sendOff = max(0, Int(sendOffText.trimmingCharacters(in: .whitespaces)) ?? 0)
            result.rest = 0
        } else {
            result.sendOff = 0
            result.rest = max(0, Int(restText.trimmingCharacters(in: .whitespaces)) ?? 0)
        }
        onDone(result)
        dismiss()
    }
}
