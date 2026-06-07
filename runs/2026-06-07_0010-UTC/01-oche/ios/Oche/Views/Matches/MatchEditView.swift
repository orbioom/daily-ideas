import SwiftUI
import SwiftData

/// Create a new match shell (legs are added from the detail screen).
struct MatchEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultStartScore") private var defaultStartScore = 501
    @AppStorage("defaultBestOf") private var defaultBestOf = 5

    @State private var opponent = ""
    @State private var startScore = 501
    @State private var bestOf = 5
    @State private var notes = ""
    @State private var didInit = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Opponent") {
                        TextField("Name (optional)", text: $opponent)
                    }.listRowBackground(Color.clear)

                    Section("Format") {
                        Picker("Start score", selection: $startScore) {
                            Text("301").tag(301); Text("501").tag(501); Text("701").tag(701)
                        }
                        Picker("Match length", selection: $bestOf) {
                            Text("Best of 3").tag(3); Text("Best of 5").tag(5); Text("Best of 7").tag(7)
                        }
                    }.listRowBackground(Color.clear)

                    Section("Notes") {
                        TextField("Anything to remember", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New match")
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
                if !didInit {
                    startScore = defaultStartScore
                    bestOf = defaultBestOf
                    didInit = true
                }
            }
        }
    }

    private func save() {
        let match = Match(opponent: opponent.trimmingCharacters(in: .whitespaces),
                          startScore: startScore, bestOfLegs: bestOf,
                          notes: notes.trimmingCharacters(in: .whitespaces))
        context.insert(match)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

/// Add a single leg to a match.
struct LegEditView: View {
    @Environment(\.dismiss) private var dismiss
    let nextIndex: Int
    var startScore: Int = 501
    var onSave: (Leg) -> Void

    @State private var didWin = true
    @State private var dartsThrown = 18
    @State private var pointsScored = 501
    @State private var checkoutDouble = 16
    @State private var doubleAttempts = 1
    @State private var highestScore = 100

    private let commonDoubles = [20, 16, 12, 10, 8, 4, 2, 25]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Toggle("I won this leg", isOn: $didWin)
                        Stepper("Darts thrown: \(dartsThrown)", value: $dartsThrown, in: 9...60)
                        Stepper("Highest visit: \(highestScore)", value: $highestScore, in: 0...180, step: 1)
                    } header: { Text("Leg \(nextIndex + 1)") }
                        .listRowBackground(Color.clear)

                    if didWin {
                        Section("Finish") {
                            Picker("Checkout double", selection: $checkoutDouble) {
                                ForEach(commonDoubles, id: \.self) { d in
                                    Text(d == 25 ? "Bull" : "D\(d)").tag(d)
                                }
                            }
                            Stepper("Double attempts: \(doubleAttempts)", value: $doubleAttempts, in: 1...12)
                        }.listRowBackground(Color.clear)
                    } else {
                        Section("Score reached") {
                            Stepper("Points scored: \(pointsScored)", value: $pointsScored, in: 0...700, step: 5)
                            Stepper("Double attempts: \(doubleAttempts)", value: $doubleAttempts, in: 0...12)
                        }.listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add leg")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
        }
    }

    private func save() {
        let leg = Leg(index: nextIndex, didWin: didWin, dartsThrown: dartsThrown,
                      pointsScored: didWin ? startScore : pointsScored,
                      checkoutDouble: didWin ? checkoutDouble : 0,
                      doubleAttempts: max(0, doubleAttempts),
                      highestScore: highestScore)
        onSave(leg)
        Haptics.success()
        dismiss()
    }
}
