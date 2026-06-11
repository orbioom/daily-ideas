import SwiftUI
import SwiftData
import Charts

/// Remedies tab: manage factors + see which ones correlate with quieter nights.
struct FactorsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \SleepFactor.name) private var factors: [SleepFactor]
    @Query private var sessions: [NightSession]

    @State private var showAdd = false
    @State private var newName = ""
    @State private var newEmoji = ""
    @State private var addError: String?

    private var impacts: [SnoreEngine.FactorImpact] {
        SnoreEngine.factorImpacts(sessions: sessions, factors: factors)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if impacts.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Not enough data yet")
                                .font(.headline)
                            Text("Tag factors on at least 4 nights (2 with a factor, 2 without) and Timber will show whether each remedy actually helps.")
                                .font(.caption)
                                .foregroundStyle(Theme.inkSecondary(scheme))
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(impacts) { impact in
                            impactRow(impact)
                        }
                    }
                } header: {
                    Text("What's working")
                } footer: {
                    if !impacts.isEmpty {
                        Text("Negative numbers mean quieter nights with that factor. Correlation, not causation — but a great place to start.")
                    }
                }

                Section("Your factors") {
                    if factors.isEmpty {
                        Text("No factors yet — add one below.")
                            .foregroundStyle(Theme.inkSecondary(scheme))
                    }
                    ForEach(factors) { factor in
                        HStack {
                            Text(factor.emoji)
                            Text(factor.name)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { factor.isActive },
                                set: { factor.isActive = $0 }))
                            .labelsHidden()
                            .tint(Theme.amber)
                            .accessibilityLabel("Show \(factor.name) in the nightly checklist")
                        }
                    }
                    .onDelete(perform: deleteFactors)
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add factor", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.amber)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background(scheme))
            .navigationTitle("Remedies")
            .alert("New factor", isPresented: $showAdd) {
                TextField("Name (e.g. Slept elevated)", text: $newName)
                TextField("Emoji (optional)", text: $newEmoji)
                Button("Add") { addFactor() }
                Button("Cancel", role: .cancel) { newName = ""; newEmoji = "" }
            } message: {
                Text("Track anything you suspect affects your snoring.")
            }
            .alert("Couldn't add factor", isPresented: Binding(
                get: { addError != nil },
                set: { if !$0 { addError = nil } })) {
                Button("OK", role: .cancel) { addError = nil }
            } message: {
                Text(addError ?? "")
            }
        }
    }

    private func impactRow(_ impact: SnoreEngine.FactorImpact) -> some View {
        HStack(spacing: 12) {
            Text(impact.emoji)
            VStack(alignment: .leading, spacing: 2) {
                Text(impact.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(impact.nightsWith) nights with · avg \(Int(impact.withAverage.rounded())) vs \(Int(impact.withoutAverage.rounded()))")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary(scheme))
            }
            Spacer()
            Text(impact.delta <= 0 ? "−\(abs(Int(impact.delta.rounded())))" : "+\(Int(impact.delta.rounded()))")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(impact.delta <= 0 ? Theme.moss : Theme.ember)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(impact.name): score changes by \(Int(impact.delta.rounded())) points on nights with this factor")
    }

    private func addFactor() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        defer { newName = ""; newEmoji = "" }
        guard !trimmed.isEmpty else {
            addError = "Give the factor a name."
            return
        }
        guard !factors.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) else {
            addError = "A factor named “\(trimmed)” already exists."
            return
        }
        let emoji = newEmoji.trimmingCharacters(in: .whitespaces)
        context.insert(SleepFactor(name: trimmed, emoji: emoji.isEmpty ? "🌙" : String(emoji.prefix(2))))
        Haptics.success()
    }

    private func deleteFactors(at offsets: IndexSet) {
        for index in offsets {
            context.delete(factors[index])
        }
    }
}
