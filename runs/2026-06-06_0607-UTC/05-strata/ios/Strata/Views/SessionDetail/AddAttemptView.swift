import SwiftUI
import SwiftData

/// Add an attempt to a session. The climber either picks an existing climb (grade
/// inherited) or logs an ad-hoc grade by family. Outcome is always required.
struct AddAttemptView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Climb.createdAt, order: .reverse) private var climbs: [Climb]

    var session: Session

    enum Mode: String, CaseIterable, Identifiable {
        case climb, adhoc
        var id: String { rawValue }
        var title: String { self == .climb ? "Existing climb" : "Quick log" }
    }

    @State private var mode: Mode = .climb
    @State private var selectedClimbID: UUID?
    @State private var adhocFamily: GradeFamily = .boulder
    @State private var adhocIndex = 0
    @State private var outcome: Outcome = .redpoint
    @State private var notes = ""

    private var selectedClimb: Climb? {
        climbs.first { $0.id == selectedClimbID }
    }

    private var canSave: Bool {
        mode == .adhoc || selectedClimb != nil
    }

    private var adhocSystem: GradeSystem {
        settings.system(for: adhocFamily)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                if mode == .climb {
                    if climbs.isEmpty {
                        Section {
                            Text("No climbs yet. Use Quick log to record a grade, or add a climb from the Climbs tab.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                        }
                    } else {
                        Section("Climb") {
                            Picker("Climb", selection: $selectedClimbID) {
                                Text("Select a climb").tag(UUID?.none)
                                ForEach(climbs) { climb in
                                    Text("\(climb.displayName) · \(climb.gradeLabel(boulderSystem: settings.boulderSystem, routeSystem: settings.routeSystem))")
                                        .tag(UUID?.some(climb.id))
                                }
                            }
                        }
                    }
                } else {
                    Section("Grade family") {
                        Picker("Family", selection: $adhocFamily) {
                            Text("Boulder").tag(GradeFamily.boulder)
                            Text("Route").tag(GradeFamily.route)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: adhocFamily) { _, _ in
                            // Re-clamp the index when switching families to stay in bounds.
                            adhocIndex = GradeScale.clampedIndex(adhocIndex, family: adhocFamily) ?? 0
                        }
                    }
                    Section("Grade (\(adhocSystem.title))") {
                        GradePicker(family: adhocFamily, system: adhocSystem, index: $adhocIndex)
                            .frame(height: 120)
                    }
                }

                Section("Outcome") {
                    Picker("Outcome", selection: $outcome) {
                        ForEach(Outcome.allCases) { o in
                            Label(o.title, systemImage: o.symbol).tag(o)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Notes") {
                    TextField("Beta, conditions, how it felt…", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Add Attempt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.fontWeight(.semibold).disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let order = (session.attempts.map(\.order).max() ?? -1) + 1

        let family: GradeFamily
        let index: Int
        let climb: Climb?

        if mode == .climb, let picked = selectedClimb {
            family = picked.gradeFamily
            index = picked.gradeIndex
            climb = picked
        } else {
            family = adhocFamily
            index = GradeScale.clampedIndex(adhocIndex, family: adhocFamily) ?? 0
            climb = nil
        }

        let attempt = Attempt(order: order, outcome: outcome,
                              gradeFamily: family, gradeIndex: index,
                              notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                              createdAt: .now, climb: climb)
        attempt.session = session
        session.attempts.append(attempt)
        context.insert(attempt)

        if outcome.isSend {
            Haptics.success(enabled: settings.hapticsEnabled)
        } else {
            Haptics.impact(enabled: settings.hapticsEnabled)
        }
        dismiss()
    }
}
