import SwiftUI
import SwiftData

struct RelapseEntryView: View {
    let quit: Quit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var note: String = ""
    @State private var showConfirm = false

    private var currentCleanDays: Int {
        SobrietyEngine.cleanDays(start: quit.startDate, now: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                VStack(spacing: 24) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Brand.warn)
                                    .font(.title2)
                                    .accessibilityHidden(true)
                                Text("Recording a Slip")
                                    .font(.headline)
                                    .foregroundStyle(Brand.text)
                            }

                            Text("This will record today as a relapse for \(quit.name) and reset your streak. Your current streak of \(currentCleanDays) day\(currentCleanDays == 1 ? "" : "s") will be saved.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow(text: "What happened?")
                            TextField("Optional note about the slip…", text: $note, axis: .vertical)
                                .lineLimit(3...8)
                                .font(.body)
                                .foregroundStyle(Brand.text)
                        }
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        Button("Confirm — Reset My Streak") {
                            showConfirm = true
                        }
                        .buttonStyle(InkButtonStyle())
                        .accessibilityHint("Records the relapse and resets your streak to zero")

                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .navigationTitle("I Had a Slip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog(
                "Reset your streak?",
                isPresented: $showConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset Streak", role: .destructive) {
                    recordRelapse()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your \(currentCleanDays)-day streak will be saved as a record and your clean date resets to now.")
            }
        }
    }

    private func recordRelapse() {
        let relapse = Relapse(
            date: Date(),
            previousCleanDays: currentCleanDays,
            note: note,
            quit: quit
        )
        modelContext.insert(relapse)
        quit.relapses.append(relapse)
        quit.startDate = Date()
        Haptics.warning()
        dismiss()
    }
}
