import SwiftUI
import SwiftData

/// The starter feeding log: the keeper's current state ("time since fed") plus the
/// full history of feedings. Supports a single starter for a calm, focused screen.
struct StarterView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Starter.createdAt) private var starters: [Starter]

    @State private var feeding = false
    @State private var editingStarter = false
    @State private var now = Date.now
    @State private var pendingDeleteFeeding: Feeding?

    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var starter: Starter? { starters.first }

    var body: some View {
        NavigationStack {
            Group {
                if let starter {
                    content(starter)
                } else {
                    EmptyStateView(
                        icon: "leaf",
                        title: "No starter yet",
                        message: "Create your starter to track its feedings and see how long it's been since its last meal.",
                        actionTitle: "Create starter",
                        action: createStarter
                    )
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Starter")
            .toolbar {
                if let starter {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button { editingStarter = true } label: {
                                Label("Edit starter", systemImage: "pencil")
                            }
                            Button { feeding = true } label: {
                                Label("Log feeding", systemImage: "plus")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Starter actions")
                    }
                }
            }
        }
        .sheet(isPresented: $feeding) {
            if let starter { FeedingEditView(starter: starter) }
        }
        .sheet(isPresented: $editingStarter) {
            if let starter { StarterEditView(starter: starter) }
        }
        .onReceive(ticker) { now = $0 }
        .alert("Delete feeding?", isPresented: .constant(pendingDeleteFeeding != nil),
               presenting: pendingDeleteFeeding) { feed in
            Button("Delete", role: .destructive) { delete(feed) }
            Button("Cancel", role: .cancel) { pendingDeleteFeeding = nil }
        } message: { _ in
            Text("This feeding will be removed from the log.")
        }
    }

    private func content(_ starter: Starter) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                statusCard(starter)
                if starter.feedings.isEmpty {
                    GlassCard {
                        VStack(spacing: 8) {
                            Text("No feedings logged")
                                .font(.headline)
                                .foregroundStyle(Brand.text)
                            Text("Log your first feeding to start tracking.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    feedingHistory(starter)
                }
                InkButton(title: "Log feeding", systemImage: "plus") { feeding = true }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Status

    private func statusCard(_ starter: Starter) -> some View {
        let last = starter.lastFeeding
        let elapsed = last.map { now.timeIntervalSince($0.date) }
        // Past ~12h a counter-top starter usually wants feeding; tint accordingly.
        let overdue = (elapsed ?? 0) > 12 * 3600

        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundStyle(Brand.roleColor(.levain))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(starter.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Brand.text)
                        Text(starter.flourType)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                    Spacer()
                }
                Divider().overlay(Brand.glassStroke.opacity(0.5))
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LAST FED")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.text3)
                            .tracking(0.6)
                        Text(elapsedString(elapsed))
                            .font(Brand.mono(20, weight: .semibold))
                            .foregroundStyle(overdue ? Brand.warm : Brand.live)
                            .monospacedDigit()
                    }
                    Spacer()
                    if let last {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("RATIO")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Brand.text3)
                                .tracking(0.6)
                            Text(last.ratioString)
                                .font(Brand.mono(20, weight: .semibold))
                                .foregroundStyle(Brand.text)
                                .monospacedDigit()
                        }
                    }
                }
                if !starter.notes.isEmpty {
                    Text(starter.notes)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(starter.name), last fed \(elapsedString(elapsed))")
        }
    }

    // MARK: - History

    private func feedingHistory(_ starter: Starter) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Feeding history")
                ForEach(starter.orderedFeedings) { feed in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(feed.ratioString)
                                .font(Brand.mono(16, weight: .semibold))
                                .foregroundStyle(Brand.text)
                                .monospacedDigit()
                            Text("·")
                                .foregroundStyle(Brand.text3)
                            Text(feed.flourType)
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                                .lineLimit(1)
                            Spacer()
                            Text(feed.date, format: .dateTime.month().day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                                .monospacedDigit()
                        }
                        HStack(spacing: 10) {
                            Text("\(BakersMath.displayPercent(feed.impliedHydration))% hydration")
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                            if !feed.notes.isEmpty {
                                Text(feed.notes)
                                    .font(.caption)
                                    .foregroundStyle(Brand.text3)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button(role: .destructive) {
                            pendingDeleteFeeding = feed
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Fed \(feed.ratioString) with \(feed.flourType)")
                    if feed.id != starter.orderedFeedings.last?.id {
                        Divider().overlay(Brand.glassStroke.opacity(0.3))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func elapsedString(_ interval: TimeInterval?) -> String {
        guard let interval, interval >= 0 else { return "Never" }
        let totalMinutes = Int(interval / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h == 0 { return "\(m)m ago" }
        if h < 24 { return m == 0 ? "\(h)h ago" : "\(h)h \(m)m ago" }
        let days = h / 24
        let remH = h % 24
        return remH == 0 ? "\(days)d ago" : "\(days)d \(remH)h ago"
    }

    private func createStarter() {
        let starter = Starter(name: "My Starter")
        context.insert(starter)
        Haptics.success(enabled: settings.hapticsEnabled)
        editingStarter = true
    }

    private func delete(_ feed: Feeding) {
        context.delete(feed)
        Haptics.warning(enabled: settings.hapticsEnabled)
        pendingDeleteFeeding = nil
    }
}

#Preview {
    let container = PreviewSupport.container()
    return StarterView()
        .environment(SettingsStore())
        .modelContainer(container)
}
