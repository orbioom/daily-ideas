import SwiftUI
import SwiftData

struct FightRecordView: View {
    @Query(sort: \FightRecord.date, order: .reverse) private var fights: [FightRecord]
    @Environment(\.modelContext) private var context
    @State private var showAdd = false
    @State private var selected: FightRecord? = nil

    private var wins: Int { fights.filter { $0.result == .win }.count }
    private var losses: Int { fights.filter { $0.result == .loss }.count }
    private var draws: Int { fights.filter { $0.result == .draw }.count }
    private var koWins: Int { fights.filter { $0.result == .win && $0.method == .ko }.count }

    var body: some View {
        NavigationStack {
            Group {
                if fights.isEmpty {
                    emptyState
                } else {
                    List {
                        Section {
                            recordHeader
                        }
                        .listRowBackground(SparTheme.gradient())

                        Section("Fight History") {
                            ForEach(fights) { f in
                                FightRowView(fight: f)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selected = f }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            context.delete(f)
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Fight Record")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddFightView() }
            .sheet(item: $selected) { f in
                FightDetailView(fight: f)
            }
        }
    }

    private var recordHeader: some View {
        VStack(spacing: 12) {
            Text("\(wins)-\(losses)-\(draws)")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("W – L – D")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 24) {
                statBubble("KO/TKO", value: "\(koWins)")
                statBubble("Fights", value: "\(fights.count)")
                statBubble("Win %", value: fights.isEmpty ? "-" : "\(Int(Double(wins) / Double(fights.count) * 100))%")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Record: \(wins) wins, \(losses) losses, \(draws) draws. \(koWins) KO wins.")
    }

    private func statBubble(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold()).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No fights logged")
                .font(.title3.bold())
            Text("Log your amateur or professional fight results")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Fight") { showAdd = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct FightRowView: View {
    let fight: FightRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: fight.result.icon)
                .font(.title2)
                .foregroundStyle(resultColor(fight.result))
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("vs. \(fight.opponent)").font(.subheadline.bold())
                Text(fight.method.rawValue).font(.caption).foregroundStyle(.secondary)
                Text(fight.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(fight.result.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(resultColor(fight.result))
                Text(fight.isAmateur ? "Amateur" : "Pro")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fight.result.rawValue) vs \(fight.opponent), \(fight.method.rawValue)")
    }

    private func resultColor(_ r: FightResult) -> Color {
        switch r {
        case .win: return .green
        case .loss: return .red
        case .draw: return .orange
        case .noContest: return .gray
        }
    }
}

struct FightDetailView: View {
    @Bindable var fight: FightRecord
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            List {
                Section("Result") {
                    row("Opponent", "vs. \(fight.opponent)")
                    row("Result", fight.result.rawValue)
                    row("Method", fight.method.rawValue)
                    if fight.round > 0 { row("Round", "\(fight.round)") }
                    if !fight.roundTime.isEmpty { row("Time", fight.roundTime) }
                }
                Section("Event") {
                    row("Event", fight.event.isEmpty ? "—" : fight.event)
                    row("Type", fight.isAmateur ? "Amateur" : "Professional")
                    row("Discipline", fight.discipline.rawValue)
                    row("Date", fight.date.formatted(date: .long, time: .omitted))
                }
                if !fight.notes.isEmpty {
                    Section("Notes") { Text(fight.notes) }
                }
            }
            .navigationTitle("vs. \(fight.opponent)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("Edit") { showEdit = true } }
            }
            .sheet(isPresented: $showEdit) { AddFightView(editing: fight) }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}

struct AddFightView: View {
    var editing: FightRecord? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var opponent = ""
    @State private var event = ""
    @State private var result = FightResult.win
    @State private var method = FightMethod.decision
    @State private var round = 0
    @State private var roundTime = ""
    @State private var discipline = Discipline.boxing
    @State private var notes = ""
    @State private var isAmateur = true
    @State private var showValidation = false

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Fight") {
                    TextField("Opponent name", text: $opponent)
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    Picker("Result", selection: $result) {
                        ForEach(FightResult.allCases, id: \.self) { r in
                            Label(r.rawValue, systemImage: r.icon).tag(r)
                        }
                    }
                    Picker("Method", selection: $method) {
                        ForEach(FightMethod.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                }
                Section("Details") {
                    Stepper("Round: \(round == 0 ? "N/A" : "\(round)")", value: $round, in: 0...12)
                    TextField("Round time (e.g. 2:45)", text: $roundTime)
                    Picker("Discipline", selection: $discipline) {
                        ForEach(Discipline.allCases, id: \.self) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    Toggle("Amateur", isOn: $isAmateur)
                }
                Section("Event") {
                    TextField("Event name (optional)", text: $event)
                }
                Section("Notes") {
                    TextField("Post-fight notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "Edit Fight" : "Add Fight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(opponent.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Check Input", isPresented: $showValidation) {
                Button("OK", role: .cancel) {}
            } message: { Text("Opponent name is required.") }
        }
        .onAppear { populate() }
    }

    private func populate() {
        guard let f = editing else { return }
        date = f.date; opponent = f.opponent; event = f.event
        result = f.result; method = f.method; round = f.round
        roundTime = f.roundTime; discipline = f.discipline; notes = f.notes; isAmateur = f.isAmateur
    }

    private func save() {
        let name = opponent.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { showValidation = true; return }
        if let f = editing {
            f.date = date; f.opponent = name; f.event = event
            f.resultRaw = result.rawValue; f.methodRaw = method.rawValue
            f.round = round; f.roundTime = roundTime; f.disciplineRaw = discipline.rawValue
            f.notes = notes; f.isAmateur = isAmateur
        } else {
            let f = FightRecord(date: date, opponent: name, event: event, result: result,
                                method: method, round: round, roundTime: roundTime,
                                discipline: discipline, notes: notes, isAmateur: isAmateur)
            context.insert(f)
        }
        try? context.save()
        dismiss()
    }
}
