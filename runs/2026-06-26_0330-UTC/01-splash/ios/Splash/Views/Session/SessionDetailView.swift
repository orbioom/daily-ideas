import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: SwimSession

    @Query private var settingsAll: [SplashSettings]
    var useYards: Bool { settingsAll.first?.useYards ?? false }

    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    var sortedSets: [SwimSet] {
        session.sets.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card
                VStack(spacing: 10) {
                    Text(session.date, style: .date)
                        .font(.title3.bold())
                    if let pool = session.pool {
                        Label(pool.name, systemImage: pool.poolType.poolTypeIcon)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    RatingStars(rating: session.feelRating)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(SplashTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Stats row
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(
                        title: "Distance",
                        value: metersToDisplay(session.computedDistance > 0 ? session.computedDistance : session.totalDistanceMeters, useYards: useYards),
                        icon: "arrow.left.and.right",
                        color: SplashTheme.accent
                    )
                    StatCard(
                        title: "Duration",
                        value: formatDuration(session.durationSeconds),
                        icon: "clock.fill",
                        color: Color(red: 0.28, green: 0.52, blue: 0.93)
                    )
                    StatCard(
                        title: "Sets",
                        value: "\(session.sets.count)",
                        icon: "list.number",
                        color: Color(red: 0.20, green: 0.80, blue: 0.60)
                    )
                    StatCard(
                        title: "Avg Pace",
                        value: {
                            let dist = session.computedDistance > 0 ? session.computedDistance : session.totalDistanceMeters
                            if dist > 0 && session.durationSeconds > 0 {
                                let p = (Double(session.durationSeconds) / dist) * 100
                                return formatPace(p, useYards: useYards)
                            }
                            return "—"
                        }(),
                        icon: "speedometer",
                        color: Color(red: 0.93, green: 0.45, blue: 0.20)
                    )
                }

                // Sets
                if sortedSets.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet.indent")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No sets recorded")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(sortedSets.enumerated()), id: \.element.id) { idx, set in
                            SetDetailRow(set: set, index: idx + 1, useYards: useYards)
                        }
                    }
                }

                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Notes", systemImage: "note.text")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(session.notes)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SplashTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Delete Session", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Session?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(session)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

private struct SetDetailRow: View {
    let set: SwimSet
    let index: Int
    let useYards: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SplashTheme.strokeColor(set.strokeType).opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(index)")
                    .font(.caption.bold())
                    .foregroundStyle(SplashTheme.strokeColor(set.strokeType))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(set.repetitions)×\(metersToDisplay(set.distanceMeters, useYards: useYards))")
                        .font(.subheadline.bold())
                    StrokeTag(stroke: set.strokeType)
                }
                HStack(spacing: 8) {
                    IntensityTag(intensity: set.intensityLevel)
                    if set.restSeconds > 0 {
                        Text(":\(set.restSeconds)s rest")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let pace = set.pace100m {
                        Text(formatPace(pace, useYards: useYards))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(metersToDisplay(set.totalDistanceMeters, useYards: useYards))
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                if set.durationSeconds > 0 {
                    Text(formatDuration(set.durationSeconds))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(SplashTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Set \(index): \(set.repetitions) × \(metersToDisplay(set.distanceMeters, useYards: useYards)) \(set.strokeType.strokeDisplayName), \(set.intensityLevel.intensityDisplayName)")
    }
}
