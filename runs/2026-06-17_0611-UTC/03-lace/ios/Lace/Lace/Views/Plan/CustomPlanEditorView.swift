import SwiftUI
import SwiftData

/// Editor for a single custom plan: rename, add/remove sessions, and edit each
/// session's intervals. Mutations persist through SwiftData immediately.
struct CustomPlanEditorView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    @Bindable var plan: CustomPlan

    @State private var deleteConfirm = false

    private var orderedSessions: [CustomSession] {
        plan.sessions.sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan name") {
                    TextField("Plan name", text: $plan.title)
                        .onChange(of: plan.title) { _, _ in try? modelContext.save() }
                }

                ForEach(orderedSessions) { session in
                    Section {
                        sessionEditor(session)
                    } header: {
                        HStack {
                            Text(session.title)
                            Spacer()
                            Text(Fmt.minutes(sessionTotal(session)))
                                .foregroundStyle(Theme.secondaryText(scheme))
                        }
                    }
                }

                Section {
                    Button {
                        addSession()
                    } label: {
                        Label("Add session", systemImage: "plus.circle")
                    }
                    Button(role: .destructive) {
                        deleteConfirm = true
                    } label: {
                        Label("Delete this plan", systemImage: "trash")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .laceScreenBackground(scheme)
            .navigationTitle("Edit plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { try? modelContext.save(); dismiss() }
                }
            }
            .alert("Delete plan?", isPresented: $deleteConfirm) {
                Button("Delete", role: .destructive) { deletePlan() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the plan and all its sessions. Completed history is kept.")
            }
        }
    }

    // MARK: - Session editor

    @ViewBuilder
    private func sessionEditor(_ session: CustomSession) -> some View {
        let intervals = session.intervals.sorted { $0.order < $1.order }
        ForEach(intervals) { interval in
            intervalRow(interval, in: session)
        }
        .onDelete { offsets in
            deleteIntervals(at: offsets, from: session, ordered: intervals)
        }
        Button {
            addInterval(to: session)
        } label: {
            Label("Add interval", systemImage: "plus")
                .font(.subheadline)
        }
        if plan.sessions.count > 1 {
            Button(role: .destructive) {
                deleteSession(session)
            } label: {
                Label("Remove session", systemImage: "trash")
                    .font(.subheadline)
            }
        }
    }

    private func intervalRow(_ interval: CustomInterval, in session: CustomSession) -> some View {
        HStack(spacing: 10) {
            Circle().fill(interval.kind.color).frame(width: 12, height: 12)
                .accessibilityHidden(true)
            Picker("Type", selection: kindBinding(interval)) {
                ForEach(IntervalKind.allCases) { Text($0.title).tag($0) }
            }
            .labelsHidden()
            .frame(maxWidth: 130)
            Spacer()
            Stepper(value: secondsBinding(interval), in: 5...3600, step: 5) {
                Text(Fmt.clock(interval.durationSeconds))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.primaryText(scheme))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(interval.kind.title), \(Fmt.spokenDuration(interval.durationSeconds))")
    }

    // MARK: - Bindings

    private func kindBinding(_ interval: CustomInterval) -> Binding<IntervalKind> {
        Binding(
            get: { interval.kind },
            set: { interval.kindRaw = $0.rawValue; try? modelContext.save() }
        )
    }

    private func secondsBinding(_ interval: CustomInterval) -> Binding<Int> {
        Binding(
            get: { interval.durationSeconds },
            set: { interval.durationSeconds = max(5, $0); try? modelContext.save() }
        )
    }

    // MARK: - Mutations

    private func sessionTotal(_ session: CustomSession) -> Int {
        session.intervals.reduce(0) { $0 + $1.durationSeconds }
    }

    private func addSession() {
        let order = (plan.sessions.map { $0.order }.max() ?? -1) + 1
        let session = CustomSession(title: "Session \(plan.sessions.count + 1)", order: order, plan: plan)
        session.intervals = [
            CustomInterval(kind: .warmup, durationSeconds: 300, order: 0, session: session),
            CustomInterval(kind: .run, durationSeconds: 60, order: 1, session: session),
            CustomInterval(kind: .cooldown, durationSeconds: 300, order: 2, session: session)
        ]
        plan.sessions.append(session)
        try? modelContext.save()
        Haptics.tap(settings.hapticCues)
    }

    private func deleteSession(_ session: CustomSession) {
        plan.sessions.removeAll { $0.id == session.id }
        modelContext.delete(session)
        try? modelContext.save()
    }

    private func addInterval(to session: CustomSession) {
        let order = (session.intervals.map { $0.order }.max() ?? -1) + 1
        let interval = CustomInterval(kind: .run, durationSeconds: 60, order: order, session: session)
        session.intervals.append(interval)
        try? modelContext.save()
        Haptics.tap(settings.hapticCues)
    }

    private func deleteIntervals(at offsets: IndexSet, from session: CustomSession, ordered: [CustomInterval]) {
        for index in offsets {
            guard let interval = ordered[safe: index] else { continue }
            session.intervals.removeAll { $0.id == interval.id }
            modelContext.delete(interval)
        }
        try? modelContext.save()
    }

    private func deletePlan() {
        modelContext.delete(plan)
        try? modelContext.save()
        dismiss()
    }
}
