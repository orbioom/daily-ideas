import SwiftUI
import SwiftData

struct AddCheckInView: View {
    let quit: Quit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var mood: Int = 3
    @State private var note: String = ""
    @State private var pledged: Bool = false
    @State private var date: Date = Calendar.current.startOfDay(for: Date())

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                Form {
                    Section("How are you feeling?") {
                        MoodPicker(mood: $mood)
                            .padding(.vertical, 4)
                    }

                    Section("Details") {
                        DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)

                        Toggle("Today's pledge", isOn: $pledged)
                            .accessibilityHint("Mark that you pledged to stay clean today")

                        LabeledContent("Note") {
                            TextField("Optional note…", text: $note, axis: .vertical)
                                .lineLimit(3...6)
                                .multilineTextAlignment(.leading)
                        }
                        .accessibilityLabel("Check-in note")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let checkIn = CheckIn(
            date: date,
            mood: mood,
            note: note,
            pledged: pledged,
            quit: quit
        )
        modelContext.insert(checkIn)
        quit.checkIns.append(checkIn)
        Haptics.success()
        dismiss()
    }
}
