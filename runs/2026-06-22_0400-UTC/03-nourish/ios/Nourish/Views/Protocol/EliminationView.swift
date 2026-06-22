import SwiftUI
import SwiftData

struct EliminationView: View {
    @Query(sort: \EliminationPhase.startDate) private var phases: [EliminationPhase]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if phases.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(phases) { phase in
                            PhaseRow(phase: phase)
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(phases[i]) }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Protocol")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) { AddPhaseView() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 56))
                .foregroundStyle(NourishTheme.corn.opacity(0.5))
            Text("No Protocol Active")
                .font(.title3.weight(.semibold))
            Text("Set up your elimination or challenge protocol to track reintroduction phases.")
                .foregroundStyle(NourishTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button { showingAdd = true } label: {
                Label("Start Protocol", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(NourishTheme.corn, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

private struct PhaseRow: View {
    let phase: EliminationPhase

    private var statusColor: Color {
        switch phase.status {
        case "active": return NourishTheme.sage
        case "completed": return .green
        default: return NourishTheme.secondaryText
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(phase.phaseName)
                    .font(.headline)
                Spacer()
                Text(phase.status.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(statusColor.opacity(0.12), in: Capsule())
            }
            if !phase.eliminatedFoods.isEmpty {
                Text("Avoiding: " + phase.eliminatedFoods.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(NourishTheme.secondaryText)
            }
            Text("\(phase.startDate, style: .date) → \(phase.endDate, style: .date)")
                .font(.caption2)
                .foregroundStyle(NourishTheme.secondaryText)
        }
        .padding(.vertical, 4)
    }
}

struct AddPhaseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date()
    @State private var foodInput = ""
    @State private var foods: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Phase Name") { TextField("e.g. Elimination Phase 1", text: $name) }
                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                Section {
                    HStack {
                        TextField("Food to avoid", text: $foodInput).onSubmit { addFood() }
                        Button("Add") { addFood() }.disabled(foodInput.isEmpty)
                    }
                    ForEach(foods, id: \.self) { Text($0) }.onDelete { foods.remove(atOffsets: $0) }
                } header: { Text("Foods to Eliminate (\(foods.count))") }
            }
            .navigationTitle("New Phase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let phase = EliminationPhase(phaseName: name.trimmingCharacters(in: .whitespacesAndNewlines), startDate: startDate, endDate: endDate, eliminatedFoods: foods, status: "active")
                        context.insert(phase)
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addFood() {
        let t = foodInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        foods.append(t)
        foodInput = ""
    }
}
