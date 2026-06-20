import SwiftUI
import MapKit
import SwiftData

struct RunDetailView: View {
    @Bindable var session: RunSession
    @AppStorage("pace_use_km") private var useKm = true
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var isEditingNotes = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Image(systemName: session.activityType.systemImage)
                        .font(.title)
                        .foregroundStyle(PaceTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.activityType.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(session.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(session.date, style: .time)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Route map
                if session.points.count > 1 {
                    RouteMapView(points: session.points)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }

                // Metrics grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    DetailMetric(title: useKm ? "km" : "mi",
                                value: useKm
                                    ? String(format: "%.2f", session.distanceKm)
                                    : String(format: "%.2f", session.distanceMiles),
                                color: PaceTheme.accent)
                    DetailMetric(title: "time",
                                value: session.durationFormatted,
                                color: .blue)
                    DetailMetric(title: "pace/\(useKm ? "km" : "mi")",
                                value: session.paceFormatted(useKm: useKm),
                                color: .orange)
                    DetailMetric(title: "elev gain",
                                value: String(format: "%.0f m", session.elevationGainMeters),
                                color: .purple)
                    DetailMetric(title: "calories",
                                value: String(format: "%.0f", session.calories),
                                color: .red)
                    DetailMetric(title: "max speed",
                                value: String(format: "%.1f km/h", session.maxSpeedMps * 3.6),
                                color: .yellow)
                }
                .padding(.horizontal)

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes")
                            .font(.headline)
                        Spacer()
                        Button(isEditingNotes ? "Done" : "Edit") {
                            isEditingNotes.toggle()
                        }
                        .font(.subheadline)
                        .foregroundStyle(PaceTheme.accent)
                    }

                    if isEditingNotes {
                        TextField("Add notes about this activity...", text: $session.notes, axis: .vertical)
                            .lineLimit(3...8)
                            .padding()
                            .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                            .onChange(of: session.notes) { _, _ in
                                try? modelContext.save()
                            }
                    } else {
                        Text(session.notes.isEmpty ? "No notes" : session.notes)
                            .font(.body)
                            .foregroundStyle(session.notes.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)

                // Delete button
                Button(action: { showDeleteConfirm = true }) {
                    Label("Delete Activity", systemImage: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.vertical)
        }
        .navigationTitle("Activity Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Activity?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(session)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This activity will be permanently deleted and cannot be recovered.")
        }
    }
}

private struct DetailMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}
