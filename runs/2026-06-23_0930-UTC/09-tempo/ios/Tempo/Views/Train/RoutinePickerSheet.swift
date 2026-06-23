import SwiftUI
import SwiftData

/// Lists all routines so the user can launch a session, with a link to manage them.
struct RoutinePickerSheet: View {
    let onPick: (Routine) -> Void
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Routine.createdAt) private var routines: [Routine]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if routines.isEmpty {
                    ContentUnavailableView {
                        Label("No routines", systemImage: "rectangle.stack")
                    } description: {
                        Text("Create routines in the Stats tab to launch sessions fast.")
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(routines) { routine in
                                Button {
                                    onPick(routine)
                                    dismiss()
                                } label: {
                                    RoutineDetailRow(routine: routine)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct RoutineDetailRow: View {
    let routine: Routine
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8).fill(Color(hex: routine.colorHex))
                    .frame(width: 6, height: 40).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name).font(.headline).foregroundStyle(Theme.textPrimary)
                    Text(routine.detail.isEmpty ? "\(routine.items.count) exercises" : routine.detail)
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            if !routine.orderedItems.isEmpty {
                Text(routine.orderedItems.compactMap { $0.exercise?.name }.prefix(4).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(routine.name), \(routine.items.count) exercises")
        .accessibilityHint("Starts a workout")
    }
}
