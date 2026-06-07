import SwiftUI
import SwiftData

/// The Systems tab: a list of saved power systems with at-a-glance verdicts,
/// full CRUD, and navigation into a detailed dashboard.
struct SystemsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PowerSystem.createdAt, order: .reverse) private var systems: [PowerSystem]

    @State private var editorTarget: SystemEditorTarget?
    @State private var pendingDelete: PowerSystem?

    var body: some View {
        NavigationStack {
            Group {
                if systems.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Systems")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        editorTarget = .new
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add system")
                }
            }
            .sheet(item: $editorTarget) { target in
                SystemEditorView(target: target)
            }
            .confirmationDialog(
                "Delete this system?",
                isPresented: deleteBinding,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("\(pendingDelete?.name ?? "This system") and all its loads will be removed.")
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(systems) { system in
                    NavigationLink {
                        SystemDetailView(system: system)
                    } label: {
                        SystemRow(system: system)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            Haptics.tap()
                            editorTarget = .edit(system)
                        } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) {
                            Haptics.warning()
                            pendingDelete = system
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 20) {
                EmptyStateView(
                    icon: "bolt.batteryblock",
                    title: "No systems yet",
                    message: "Create your first power system to start planning battery, solar and loads."
                )
                Button("Create a system") {
                    Haptics.tap()
                    editorTarget = .new
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 40)
            }
            .padding(.top, 60)
        }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private func confirmDelete() {
        guard let system = pendingDelete else { return }
        context.delete(system)
        try? context.save()
        Haptics.success()
        pendingDelete = nil
    }
}

/// A single card in the systems list: name, verdict badge, and key numbers.
private struct SystemRow: View {
    let system: PowerSystem

    private var result: PowerResult { PowerEngine.evaluate(system) }

    var body: some View {
        let verdict = SystemVerdict(result)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(system.name.isEmpty ? "Untitled system" : system.name)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Text("\(system.chemistry.label) · \(Fmt.int(system.batteryCapacityAh))Ah · \(system.systemVoltage)V")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                Spacer()
                HStack(spacing: 6) {
                    StatusDot(color: verdict.dotColor)
                    Text(verdict.title)
                        .font(Brand.mono(11, weight: .medium))
                        .foregroundStyle(verdict.color)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(verdict.color.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 18) {
                metric(Fmt.ah(result.dailyAh), "daily")
                metric(Fmt.signedWh(result.netDailyWh), "solar net")
                metric(Fmt.days(result.effectiveAutonomyDays), "autonomy")
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(system.name), \(verdict.title). \(Fmt.ah(result.dailyAh)) per day, solar net \(Fmt.signedWh(result.netDailyWh)).")
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Brand.mono(14, weight: .semibold))
                .foregroundStyle(Brand.text)
            Text(label.uppercased())
                .font(Brand.mono(9, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Brand.text3)
        }
    }
}

#Preview {
    SystemsView()
        .modelContainer(for: [PowerSystem.self, Load.self], inMemory: true)
}
