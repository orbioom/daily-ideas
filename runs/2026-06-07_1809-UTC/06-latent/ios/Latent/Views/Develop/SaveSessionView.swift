import SwiftUI
import SwiftData

/// The completion sheet shown after a run finishes. Captures rolls, a rating and
/// notes, then writes a DevSession snapshotting all the parameters from the run's
/// TimerState (and re-linking the source recipe if it still exists).
struct SaveSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// The finished run's persisted state (its parameter snapshot).
    let state: TimerState
    /// Called after a successful save so the engine can clear itself.
    let onSaved: () -> Void

    @AppStorage("latent.tempUnit") private var tempUnitRaw = TempUnit.celsius.rawValue

    @State private var rolls = 1
    @State private var rating = 0
    @State private var notes = ""

    private var tempUnit: TempUnit { TempUnit(rawValue: tempUnitRaw) ?? .celsius }

    private var devSeconds: Int {
        state.phases.first(where: { $0.kind == .develop })?.seconds ?? 0
    }
    private var stopSeconds: Int { state.phases.first(where: { $0.kind == .stop })?.seconds ?? 0 }
    private var fixSeconds: Int { state.phases.first(where: { $0.kind == .fix })?.seconds ?? 0 }
    private var washSeconds: Int { state.phases.first(where: { $0.kind == .wash })?.seconds ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    successHeader
                    summaryCard
                    inputCard
                    actions
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Run complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        onSaved()
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(false)
    }

    private var successHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(Brand.live)
                .accessibilityHidden(true)
            Text("All four phases done")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            Text("Log this run so the times stay handy for next time.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: state.recipeName.isEmpty ? "This run" : state.recipeName)
            InfoRow(label: "Film · Developer", value: "\(state.filmStock) · \(state.developer)")
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Temperature", value: Format.tempString(state.tempC, unit: tempUnit, decimals: 1), mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Push / pull", value: pushPullLabel, mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "EI", value: "\(state.ei)", mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Develop time", value: DevEngine.clock(devSeconds), mono: true)
        }
        .glassCard()
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Stepper(value: $rolls, in: 1...20) {
                InfoRow(label: "Rolls developed", value: "\(rolls)", mono: true)
            }
            Divider().overlay(Brand.hairline)
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle(text: "Rating")
                StarRating(rating: $rating, interactive: true, size: 26)
            }
            Divider().overlay(Brand.hairline)
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle(text: "Notes")
                TextField("How did it turn out?", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .glassCard()
    }

    private var actions: some View {
        Button {
            save()
        } label: {
            Label("Save to log", systemImage: "checkmark")
        }
        .buttonStyle(InkButtonStyle())
    }

    private var pushPullLabel: String {
        if state.pushPull == 0 { return "Box" }
        return state.pushPull > 0 ? "+\(state.pushPull)" : "−\(abs(state.pushPull))"
    }

    private func save() {
        // Re-link the source recipe if it still exists.
        var linked: Recipe?
        if let id = state.recipeID {
            let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate { $0.id == id })
            linked = (try? context.fetch(descriptor))?.first
        }

        let session = DevSession(
            date: Date(),
            recipeName: state.recipeName,
            filmStock: state.filmStock,
            developer: state.developer,
            dilution: state.dilution,
            ei: state.ei,
            tempC: state.tempC,
            pushPull: state.pushPull,
            devSec: devSeconds,
            stopSec: stopSeconds,
            fixSec: fixSeconds,
            washSec: washSeconds,
            rolls: rolls,
            rating: rating,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            recipe: linked
        )
        context.insert(session)
        try? context.save()
        Haptics.success()
        onSaved()
        dismiss()
    }
}
