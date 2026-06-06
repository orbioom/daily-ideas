import SwiftUI
import SwiftData

/// The bake log: planned and completed bakes, newest first.
struct BakesListView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Bake.date, order: .reverse) private var bakes: [Bake]
    @Query private var formulas: [Formula]

    @State private var creating = false
    @State private var pendingDelete: Bake?

    private var upcoming: [Bake] { bakes.filter { !$0.isComplete } }
    private var completed: [Bake] { bakes.filter { $0.isComplete } }

    var body: some View {
        NavigationStack {
            Group {
                if bakes.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Bakes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        creating = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New bake")
                    .disabled(formulas.isEmpty)
                }
            }
            .navigationDestination(for: Bake.self) { bake in
                BakeDetailView(bake: bake)
            }
        }
        .sheet(isPresented: $creating) {
            BakeEditView(bake: nil)
        }
        .alert("Delete bake?", isPresented: .constant(pendingDelete != nil), presenting: pendingDelete) { bake in
            Button("Delete", role: .destructive) { delete(bake) }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { bake in
            Text("\"\(bake.title)\" and its timeline will be removed.")
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if formulas.isEmpty {
            EmptyStateView(
                icon: "flame",
                title: "No formulas to bake",
                message: "Add a formula first, then log a bake with its own scheduled timeline."
            )
        } else {
            EmptyStateView(
                icon: "flame",
                title: "No bakes yet",
                message: "Plan a bake from one of your formulas. Crumb schedules every step from your start or finish time.",
                actionTitle: "New bake",
                action: { creating = true }
            )
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if !upcoming.isEmpty {
                    SectionLabel(text: "Planned")
                        .padding(.horizontal, 4)
                    ForEach(upcoming) { bake in row(bake) }
                }
                if !completed.isEmpty {
                    SectionLabel(text: "Baked")
                        .padding(.horizontal, 4)
                        .padding(.top, upcoming.isEmpty ? 0 : 8)
                    ForEach(completed) { bake in row(bake) }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private func row(_ bake: Bake) -> some View {
        NavigationLink(value: bake) {
            BakeRow(bake: bake)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                pendingDelete = bake
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func delete(_ bake: Bake) {
        context.delete(bake)
        Haptics.warning(enabled: settings.hapticsEnabled)
        pendingDelete = nil
    }
}

private struct BakeRow: View {
    @Environment(SettingsStore.self) private var settings
    var bake: Bake

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: bake.isComplete ? "checkmark.circle.fill" : "clock.badge")
                    .font(.title3)
                    .foregroundStyle(bake.isComplete ? Brand.live : Brand.text2)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(bake.title)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(bake.formula?.name ?? "No formula")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                            .lineLimit(1)
                        Text("·")
                            .foregroundStyle(Brand.text3)
                        Text(bake.date, format: .dateTime.month().day().hour().minute())
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                            .monospacedDigit()
                    }
                }
                Spacer(minLength: 0)
                if bake.isComplete && bake.crumbRating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Brand.live)
                        Text("\(bake.crumbRating)")
                            .font(Brand.mono(13, weight: .semibold))
                            .foregroundStyle(Brand.text2)
                    }
                    .accessibilityLabel("Rated \(bake.crumbRating) of 5")
                } else {
                    Text(BakersMath.durationString(minutes: bake.totalPlannedMinutes))
                        .font(Brand.mono(13))
                        .foregroundStyle(Brand.text3)
                        .accessibilityLabel("Planned \(BakersMath.durationString(minutes: bake.totalPlannedMinutes))")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let container = PreviewSupport.container()
    return BakesListView()
        .environment(SettingsStore())
        .modelContainer(container)
}
