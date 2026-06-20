import SwiftUI
import SwiftData

struct LogSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var selectedType: TrainingType = .gi
    @State private var durationMinutes = 60
    @State private var rounds = 5
    @State private var submissionsGot = 0
    @State private var tapOuts = 0
    @State private var notes = ""

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

                        // Training Type
                        FormSection(title: "Type") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(TrainingType.allCases, id: \.self) { type in
                                        TypeChip(type: type, isSelected: selectedType == type) {
                                            selectedType = type
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }

                        // Duration
                        FormSection(title: "Duration") {
                            HStack {
                                Button {
                                    if durationMinutes > 15 { durationMinutes -= 15 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(DojoTheme.crimson)
                                }

                                Spacer()

                                VStack(spacing: 2) {
                                    Text("\(durationMinutes)")
                                        .font(.largeTitle.bold())
                                        .foregroundColor(.white)
                                    Text("minutes")
                                        .font(.caption)
                                        .foregroundColor(DojoTheme.subtleText)
                                }

                                Spacer()

                                Button {
                                    durationMinutes += 15
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(DojoTheme.crimson)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }

                        // Rounds
                        FormSection(title: "Rounds") {
                            CounterRow(label: "Rounds", value: $rounds, min: 0, max: 20)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }

                        // Submissions
                        FormSection(title: "Submissions") {
                            VStack(spacing: 12) {
                                CounterRow(
                                    label: "Got",
                                    value: $submissionsGot,
                                    min: 0,
                                    max: 50,
                                    valueColor: .green
                                )
                                Divider().background(DojoTheme.cardBg)
                                CounterRow(
                                    label: "Tapped Out",
                                    value: $tapOuts,
                                    min: 0,
                                    max: 50,
                                    valueColor: DojoTheme.crimson
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
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
                                .background(Color.clear)
                        }

                        // Save button
                        Button("Save Session") {
                            saveSession()
                        }
                        .buttonStyle(CrimsonButtonStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Log Session")
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

    private func saveSession() {
        let session = TrainingSession(
            date: date,
            type: selectedType.rawValue,
            durationMinutes: durationMinutes,
            rounds: rounds,
            notes: notes,
            submissionsGot: submissionsGot,
            tapOuts: tapOuts
        )
        modelContext.insert(session)
        dismiss()
    }
}

// MARK: - Form Section

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundColor(DojoTheme.subtleText)
                .padding(.horizontal)

            content
                .background(DojoTheme.cardBg)
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }
}

// MARK: - Type Chip

struct TypeChip: View {
    let type: TrainingType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .white : DojoTheme.subtleText)
            .background(isSelected ? DojoTheme.crimson : DojoTheme.elevatedBg)
            .cornerRadius(20)
        }
    }
}

// MARK: - Counter Row

struct CounterRow: View {
    let label: String
    @Binding var value: Int
    let min: Int
    let max: Int
    var valueColor: Color = .white

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
            Spacer()
            HStack(spacing: 16) {
                Button {
                    if value > min { value -= 1 }
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundColor(DojoTheme.subtleText)
                        .font(.title3)
                }

                Text("\(value)")
                    .font(.title3.bold())
                    .foregroundColor(valueColor)
                    .frame(width: 32, alignment: .center)

                Button {
                    if value < max { value += 1 }
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(DojoTheme.crimson)
                        .font(.title3)
                }
            }
        }
    }
}

#Preview {
    LogSessionView()
        .modelContainer(for: [TrainingSession.self], inMemory: true)
}
