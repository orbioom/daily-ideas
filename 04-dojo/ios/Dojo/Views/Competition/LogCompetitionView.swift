import SwiftUI
import SwiftData

struct LogCompetitionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var name = ""
    @State private var weightClass = ""
    @State private var wins = 0
    @State private var losses = 0
    @State private var medal = 0
    @State private var notes = ""

    private let medals = [
        (value: 0, label: "None", emoji: "—"),
        (value: 1, label: "Bronze", emoji: "🥉"),
        (value: 2, label: "Silver", emoji: "🥈"),
        (value: 3, label: "Gold", emoji: "🥇")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                DojoTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Date
                        FormSection(title: "Date") {
                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .tint(DojoTheme.crimson)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }

                        // Tournament name
                        FormSection(title: "Tournament Name") {
                            TextField("e.g. IBJJF Fall Open", text: $name)
                                .padding(14)
                                .foregroundColor(.white)
                                .tint(DojoTheme.crimson)
                        }

                        // Weight class
                        FormSection(title: "Weight Class") {
                            TextField("e.g. Featherweight / 64kg", text: $weightClass)
                                .padding(14)
                                .foregroundColor(.white)
                                .tint(DojoTheme.crimson)
                        }

                        // Wins / Losses
                        FormSection(title: "Results") {
                            VStack(spacing: 12) {
                                CounterRow(
                                    label: "Wins",
                                    value: $wins,
                                    min: 0,
                                    max: 20,
                                    valueColor: .green
                                )
                                Divider().background(DojoTheme.elevatedBg)
                                CounterRow(
                                    label: "Losses",
                                    value: $losses,
                                    min: 0,
                                    max: 20,
                                    valueColor: DojoTheme.crimson
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }

                        // Medal picker
                        FormSection(title: "Medal") {
                            HStack(spacing: 0) {
                                ForEach(medals, id: \.value) { m in
                                    Button {
                                        medal = m.value
                                    } label: {
                                        VStack(spacing: 6) {
                                            Text(m.emoji)
                                                .font(.title2)
                                            Text(m.label)
                                                .font(.caption)
                                                .foregroundColor(medal == m.value ? .white : DojoTheme.subtleText)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(medal == m.value ? DojoTheme.crimson.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }

                        // Notes
                        FormSection(title: "Notes") {
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundColor(.white)
                                .tint(DojoTheme.crimson)
                                .scrollContentBackground(.hidden)
                        }

                        // Save
                        Button("Save Competition") {
                            saveCompetition()
                        }
                        .buttonStyle(CrimsonButtonStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Log Competition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DojoTheme.darkBg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DojoTheme.crimson)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveCompetition() {
        let competition = Competition(
            date: date,
            name: name,
            weightClass: weightClass,
            wins: wins,
            losses: losses,
            medal: medal,
            notes: notes
        )
        modelContext.insert(competition)
        dismiss()
    }
}

#Preview {
    LogCompetitionView()
        .modelContainer(for: [Competition.self], inMemory: true)
}
