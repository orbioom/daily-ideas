import SwiftUI
import SwiftData

struct PersonalRecordsView: View {
    @Query private var prs: [RowPR]
    @Query private var workouts: [RowWorkout]
    @Environment(\.modelContext) private var context

    private var distancePRs: [RowPR] {
        prs.filter { $0.category.isDistance }.sorted { a, b in
            (a.category.targetMeters ?? 0) < (b.category.targetMeters ?? 0)
        }
    }

    private var timedPRs: [RowPR] {
        prs.filter { !$0.category.isDistance }.sorted { a, b in
            (a.category.targetSeconds ?? 0) < (b.category.targetSeconds ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if prs.isEmpty {
                    emptyState
                } else {
                    List {
                        Section("Distance Events") {
                            if distancePRs.isEmpty {
                                Text("No distance PRs yet")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(distancePRs) { pr in
                                    PRRowView(pr: pr)
                                }
                            }
                        }
                        Section("Timed Events") {
                            if timedPRs.isEmpty {
                                Text("No timed PRs yet")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(timedPRs) { pr in
                                    PRRowView(pr: pr)
                                }
                            }
                        }
                        Section("About PRs") {
                            Text("Personal records are automatically detected when you log a workout that qualifies for a standard event (500m, 2k, 5k, 10k, 20min, 30min).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Records")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No PRs yet")
                .font(.title3.bold())
            Text("Log workouts that match standard distances (500m, 2k, 5k, 10k) or durations (20min, 30min) to earn PRs.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct PRRowView: View {
    let pr: RowPR

    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.category.rawValue)
                    .font(.subheadline.bold())
                Text(pr.achievedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(pr.displayValue)
                .font(.title3.bold())
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pr.category.rawValue): \(pr.displayValue), set on \(pr.achievedDate.formatted(date: .abbreviated, time: .omitted))")
    }
}
