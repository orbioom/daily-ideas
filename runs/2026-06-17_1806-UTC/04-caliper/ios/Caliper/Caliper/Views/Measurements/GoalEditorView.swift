import SwiftUI
import SwiftData

struct GoalEditorView: View {
    let site: MeasurementSite
    let onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @Query(sort: \MeasurementSite.sortOrder) private var allSites: [MeasurementSite]

    @State private var goalText: String = ""
    @State private var error: String?
    @State private var showPaywall = false

    private var kind: UnitKind { site.unitKind }
    private var unit: String { Units.unitLabel(kind: kind, system: settings.unitSystem) }

    /// How many sites already carry a goal (excluding this one).
    private var otherGoalCount: Int {
        allSites.filter { $0.goalValue != nil && $0.key != site.key }.count
    }

    /// Free users may keep at most one goal in total.
    private var blockedByFreeLimit: Bool {
        !proStore.isPro && site.goalValue == nil && otherGoalCount >= ProGate.freeGoalLimit
    }

    var body: some View {
        NavigationStack {
            Form {
                if blockedByFreeLimit {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Free plan includes \(ProGate.freeGoalLimit) goal", systemImage: "crown.fill")
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("Unlock Pro to set a goal on every site.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.inkSoft)
                            Button("Unlock Pro") { showPaywall = true }
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18).padding(.vertical, 10)
                                .background(Theme.accent, in: Capsule())
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Section {
                        HStack {
                            TextField("Target", text: $goalText)
                                .keyboardType(.decimalPad)
                                .font(Theme.rounded(20, .semibold))
                                .accessibilityLabel("Goal target for \(site.name)")
                            Text(unit)
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    } header: {
                        Text("\(site.name) goal")
                    } footer: {
                        if let error {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(Theme.bad).font(.footnote)
                        } else {
                            Text("Set the target you're working toward.")
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }

                    if site.goalValue != nil {
                        Section {
                            Button(role: .destructive) { removeGoal() } label: {
                                Label("Remove goal", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if !blockedByFreeLimit {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") { save() }.fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear {
                if let goal = site.goalValue {
                    goalText = Units.formatted(canonical: goal, kind: kind, system: settings.unitSystem)
                }
            }
        }
    }

    private func save() {
        let normalized = goalText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let display = Double(normalized), display > 0 else {
            error = "Enter a positive target."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        let range = Units.plausibleRange(kind: kind, system: settings.unitSystem)
        guard range.contains(display) else {
            error = "Target looks out of range."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        site.goalValue = Units.canonicalValue(display: display, kind: kind, system: settings.unitSystem)
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        onSaved()
        dismiss()
    }

    private func removeGoal() {
        site.goalValue = nil
        try? modelContext.save()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        onSaved()
        dismiss()
    }
}
