import SwiftUI
import SwiftData

struct PatternEditView: View {
    var pattern: BreathPattern?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var all: [BreathPattern]

    @State private var name = ""
    @State private var detail = ""
    @State private var inhale = 4.0
    @State private var holdIn = 4.0
    @State private var exhale = 4.0
    @State private var holdOut = 4.0
    @State private var rounds = 8

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (inhale + exhale) > 0 && rounds >= 1
    }
    private var roundLen: Double { inhale + holdIn + exhale + holdOut }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Name") {
                        TextField("e.g. Evening calm", text: $name)
                        TextField("Short description", text: $detail)
                    }
                    Section("Phases (seconds)") {
                        phaseStepper("Breathe in", $inhale, min: 1)
                        phaseStepper("Hold in", $holdIn, min: 0)
                        phaseStepper("Breathe out", $exhale, min: 1)
                        phaseStepper("Hold out", $holdOut, min: 0)
                    }
                    Section("Rounds") {
                        Stepper(value: $rounds, in: 1...60) {
                            HStack { Text("Rounds"); Spacer()
                                Text("\(rounds)").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                        }
                        HStack {
                            Text("Total length"); Spacer()
                            Text(Format.minutes(roundLen * Double(rounds) / 60))
                                .font(Brand.mono(15)).foregroundStyle(Brand.text3)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(pattern == nil ? "New pattern" : "Edit pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid) }
            }
            .onAppear {
                if let p = pattern {
                    name = p.name; detail = p.detail; inhale = p.inhale; holdIn = p.holdIn
                    exhale = p.exhale; holdOut = p.holdOut; rounds = p.rounds
                }
            }
        }
    }

    private func phaseStepper(_ label: String, _ value: Binding<Double>, min: Double) -> some View {
        Stepper(value: value, in: min...20, step: 1) {
            HStack { Text(label); Spacer()
                Text("\(Int(value.wrappedValue))s").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let d = detail.trimmingCharacters(in: .whitespaces)
        let finalDetail = d.isEmpty ? "Custom pattern" : d
        if let p = pattern {
            p.name = trimmed; p.detail = finalDetail; p.inhale = inhale; p.holdIn = holdIn
            p.exhale = exhale; p.holdOut = holdOut; p.rounds = rounds
        } else {
            let order = (all.map(\.order).max() ?? 0) + 1
            context.insert(BreathPattern(name: trimmed, detail: finalDetail, inhale: inhale,
                                         holdIn: holdIn, exhale: exhale, holdOut: holdOut,
                                         rounds: rounds, isCustom: true, order: order))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
