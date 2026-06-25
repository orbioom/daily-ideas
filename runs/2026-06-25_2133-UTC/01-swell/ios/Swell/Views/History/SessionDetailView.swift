import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: SurfSession
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDelete = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                conditionsGrid
                if !session.notes.isEmpty {
                    notesCard
                }
            }
            .padding()
        }
        .navigationTitle(session.spotName.isEmpty ? "Session" : session.spotName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
                .foregroundStyle(SwellTheme.teal)
                .accessibilityLabel("Edit session")

                Button(role: .destructive) {
                    showingDelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .foregroundStyle(.red)
                .accessibilityLabel("Delete session")
            }
        }
        .sheet(isPresented: $showingEdit) {
            LogSessionView(session: session)
        }
        .confirmationDialog("Delete this session?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(session)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var heroCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.dateFormatter.string(from: session.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !session.boardName.isEmpty {
                        Label(session.boardName, systemImage: "surfboard.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                ConditionBadge(conditions: session.conditions)
            }

            HStack(spacing: 24) {
                DetailStatView(icon: "water.waves", value: String(format: "%.1f ft", session.waveHeightFt), label: "Waves")
                DetailStatView(icon: "clock.fill", value: session.durationFormatted, label: "Duration")
                DetailStatView(icon: "arrow.triangle.2.circlepath", value: "\(session.swellPeriodSec)s", label: "Period")
            }

            RatingView(rating: session.rating, size: 20)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
    }

    private var conditionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wind & Swell")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ConditionCell(icon: "wind", title: "Wind Speed", value: String(format: "%.0f kts", session.windSpeedKnots))
                ConditionCell(icon: "arrow.up.circle.fill", title: "Wind Direction", value: session.windDirection.rawValue)
                ConditionCell(icon: "water.waves", title: "Wave Height", value: String(format: "%.1f ft", session.waveHeightFt))
                ConditionCell(icon: "timer", title: "Swell Period", value: "\(session.swellPeriodSec) sec")
            }
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)
            Text(session.notes)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notes: \(session.notes)")
    }
}

struct DetailStatView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(SwellTheme.teal)
                .font(.title3)
                .accessibilityHidden(true)
            Text(value)
                .font(.headline.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct ConditionCell: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(SwellTheme.teal)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
