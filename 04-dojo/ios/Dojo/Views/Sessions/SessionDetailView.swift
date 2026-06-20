import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let session: TrainingSession

    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            DojoTheme.darkBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Header card
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(DojoTheme.crimson.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: session.trainingType.icon)
                                .font(.system(size: 30))
                                .foregroundColor(DojoTheme.crimson)
                        }

                        Text(session.trainingType.rawValue)
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Text(session.date, format: .dateTime.weekday(.wide).month().day().year())
                            .font(.subheadline)
                            .foregroundColor(DojoTheme.subtleText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .cardStyle()
                    .padding(.horizontal)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DetailStatCard(
                            value: "\(session.durationMinutes) min",
                            label: "Duration",
                            icon: "clock.fill",
                            color: DojoTheme.gold
                        )
                        DetailStatCard(
                            value: "\(session.rounds)",
                            label: "Rounds",
                            icon: "arrow.counterclockwise",
                            color: DojoTheme.crimson
                        )
                        DetailStatCard(
                            value: "\(session.submissionsGot)",
                            label: "Submissions Got",
                            icon: "checkmark.seal.fill",
                            color: .green
                        )
                        DetailStatCard(
                            value: "\(session.tapOuts)",
                            label: "Tapped Out",
                            icon: "hand.raised.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Notes section
                    if !session.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NOTES")
                                .font(.caption.bold())
                                .foregroundColor(DojoTheme.subtleText)

                            Text(session.notes)
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .cardStyle()
                        }
                        .padding(.horizontal)
                    }

                    // Delete button
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Session", systemImage: "trash")
                            .font(.headline)
                            .foregroundColor(DojoTheme.crimson)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DojoTheme.crimson.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DojoTheme.darkBg, for: .navigationBar)
        .alert("Delete Session?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(session)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct DetailStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(DojoTheme.subtleText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(session: TrainingSession(
            date: .now,
            type: TrainingType.gi.rawValue,
            durationMinutes: 90,
            rounds: 6,
            notes: "Great class today. Worked on guard passing details.",
            submissionsGot: 3,
            tapOuts: 1
        ))
    }
    .modelContainer(for: [TrainingSession.self], inMemory: true)
}
