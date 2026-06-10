import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No workouts logged",
                        message: "Start a routine from the Routines tab — every finished session lands here."
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.key) { month, items in
                            Section {
                                ForEach(items) { session in
                                    NavigationLink(value: session) {
                                        SessionRow(session: session, unit: unit)
                                    }
                                    .listRowBackground(Color.clear)
                                }
                                .onDelete { offsets in
                                    for i in offsets where items.indices.contains(i) {
                                        context.delete(items[i])
                                    }
                                    Haptics.warning()
                                }
                            } header: {
                                Eyebrow(text: month)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: WorkoutSession.self) {
                SessionDetailView(session: $0)
            }
        }
    }

    private var grouped: [(key: String, value: [WorkoutSession])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        var order: [String] = []
        var buckets: [String: [WorkoutSession]] = [:]
        for s in sessions {
            let key = fmt.string(from: s.date)
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(s)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }
}

private struct SessionRow: View {
    let session: WorkoutSession
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(session.routineName)
                .font(.headline)
                .foregroundStyle(Brand.text)
            HStack(spacing: 12) {
                Text(session.date, format: .dateTime.weekday(.abbreviated).day().month())
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                Label(Duration.friendly(session.durationSeconds), systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                Label("\(session.doneSetCount) sets", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                Text(unit.format(kg: session.tonnageKg))
                    .font(Brand.mono(12, weight: .medium))
                    .foregroundStyle(Brand.text3)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct SessionDetailView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @State private var confirmDelete = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        stat("Duration", Duration.friendly(session.durationSeconds))
                        stat("Sets", "\(session.doneSetCount)")
                        stat("Volume", unit.format(kg: session.tonnageKg))
                    }

                    ForEach(session.orderedExercises) { ex in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: ex.muscle.symbol)
                                    .foregroundStyle(Brand.text3)
                                    .accessibilityHidden(true)
                                Text(ex.name)
                                    .font(.headline)
                                    .foregroundStyle(Brand.text)
                            }
                            ForEach(ex.orderedSets) { set in
                                HStack {
                                    Text("Set \(set.orderIndex + 1)")
                                        .font(.subheadline)
                                        .foregroundStyle(Brand.text2)
                                    Spacer()
                                    Text("\(set.reps) × \(unit.format(kg: set.weightKg))")
                                        .font(Brand.mono(14, weight: .medium))
                                        .foregroundStyle(set.done ? Brand.text : Brand.text3)
                                    Image(systemName: set.done ? "checkmark.circle.fill" : "circle.dashed")
                                        .font(.subheadline)
                                        .foregroundStyle(set.done ? Brand.live : Brand.text3)
                                        .accessibilityLabel(set.done ? "completed" : "skipped")
                                }
                            }
                        }
                        .glassCard()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: "Notes")
                        TextField("How did it feel?", text: $session.note, axis: .vertical)
                            .lineLimit(2...5)
                            .font(.body)
                            .foregroundStyle(Brand.text)
                    }
                    .glassCard()
                }
                .padding(16)
            }
        }
        .navigationTitle(session.routineName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete workout")
            }
        }
        .alert("Delete this workout?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(session)
                Haptics.warning()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the logged session permanently.")
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(16, weight: .semibold))
                .foregroundStyle(Brand.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}
