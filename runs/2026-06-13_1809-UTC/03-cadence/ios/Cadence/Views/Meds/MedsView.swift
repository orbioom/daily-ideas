import SwiftUI
import SwiftData

struct MedsView: View {
    @Environment(\.modelContext) private var context
    @Environment(ProStore.self) private var pro
    @Query(sort: \Medication.createdAt) private var meds: [Medication]

    static let freeLimit = 5

    @State private var editing: Medication?
    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var toDelete: Medication?

    private func attemptAdd() {
        if !pro.isPro && meds.count >= Self.freeLimit { showPaywall = true } else { showAdd = true }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if meds.isEmpty {
                    EmptyStateView(icon: "pills.fill",
                                   title: "No medications yet",
                                   message: "Add your prescriptions, vitamins and supplements — set the schedule once and Cadence handles the rest.",
                                   actionTitle: "Add medication") { attemptAdd() }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(meds) { med in
                                Button { editing = med } label: { medCard(med) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("Edit") { editing = med }
                                        Button(med.isActive ? "Pause" : "Resume") { toggleActive(med) }
                                        Button("Delete", role: .destructive) { toDelete = med }
                                    }
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { attemptAdd() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add medication")
                }
            }
            .sheet(isPresented: $showAdd) { MedEditView(med: nil) }
            .sheet(item: $editing) { MedEditView(med: $0) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Delete this medication?",
                   isPresented: Binding(get: { toDelete != nil }, set: { if !$0 { toDelete = nil } })) {
                Button("Delete", role: .destructive) {
                    if let m = toDelete { context.delete(m); try? context.save(); reschedule() }
                    toDelete = nil
                }
                Button("Cancel", role: .cancel) { toDelete = nil }
            } message: {
                Text("This removes the medication and its reminders. Past dose history is kept.")
            }
        }
    }

    private func medCard(_ med: Medication) -> some View {
        Card {
            HStack(spacing: 14) {
                PillGlyph(med: med, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(med.name).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink).lineLimit(1)
                        if !med.isActive { Pill(text: "Paused", color: Theme.inkFaint) }
                    }
                    if !med.strength.isEmpty {
                        Text(med.strength).font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                    }
                    Text(med.scheduleSummary).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft).lineLimit(1)
                }
                Spacer()
                if med.needsRefill {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.warn)
                        .accessibilityLabel("Low supply")
                }
            }
        }
    }

    private func toggleActive(_ med: Medication) {
        med.isActive.toggle(); try? context.save(); reschedule(); Haptics.tap()
    }

    private func reschedule() {
        let enabled = UserDefaults.standard.bool(forKey: "remindersEnabled")
        let snapshot = meds
        Task { await NotificationScheduler.reschedule(meds: snapshot, enabled: enabled) }
    }
}
