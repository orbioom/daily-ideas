import SwiftUI
import SwiftData

struct PracticeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @State private var showingSession = false

    /// Aggregate per target double, weakest first.
    private struct Agg: Identifiable {
        let target: Int
        let darts: Int
        let hits: Int
        var id: Int { target }
        var rate: Double { darts > 0 ? Double(hits) / Double(darts) : 0 }
        var label: String { target == 25 ? "Bull" : "D\(target)" }
    }

    private var aggregates: [Agg] {
        let grouped = Dictionary(grouping: sessions, by: \.targetValue)
        return grouped.map { key, group in
            Agg(target: key,
                darts: group.reduce(0) { $0 + $1.darts },
                hits: group.reduce(0) { $0 + $1.hits })
        }
        .filter { $0.darts > 0 }
        .sorted { $0.rate < $1.rate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        if sessions.isEmpty {
                            EmptyStateView(icon: "scope",
                                           title: "No practice yet",
                                           message: "Pick a double, throw a handful of darts, and log the hits. Oche surfaces the finish you keep missing.")
                                .padding(.top, 40)
                        } else {
                            weakestCard
                            breakdownCard
                            recentCard
                        }
                        Button {
                            Haptics.tap(); showingSession = true
                        } label: {
                            Label("Start a session", systemImage: "plus.circle")
                        }
                        .buttonStyle(InkButtonStyle())
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle("Practice")
            .sheet(isPresented: $showingSession) { PracticeSessionView() }
        }
    }

    private var weakestCard: some View {
        let total = sessions.reduce(0) { $0 + $1.darts }
        let hits = sessions.reduce(0) { $0 + $1.hits }
        let rate = total > 0 ? Double(hits) / Double(total) * 100 : 0
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Where you stand")
            HStack(spacing: 12) {
                StatTile(value: "\(total)", label: "Darts thrown")
                StatTile(value: Fmt.pct(rate), label: "Hit rate", accent: Brand.live)
                StatTile(value: aggregates.first?.label ?? "—", label: "Weakest", accent: Brand.warn)
            }
        }
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "By double", trailing: "weakest first")
            VStack(spacing: 12) {
                ForEach(aggregates) { a in
                    HStack(spacing: 12) {
                        Text(a.label)
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text)
                            .frame(width: 52, alignment: .leading)
                        ValueBar(fraction: a.rate,
                                 tint: a.rate < 0.3 ? Brand.warn : Brand.live)
                        Text(Fmt.pct(a.rate * 100))
                            .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                            .frame(width: 46, alignment: .trailing)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(a.label): \(Fmt.pct(a.rate * 100)) over \(a.darts) darts")
                }
            }
            .glassCard()
        }
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent sessions")
            ForEach(sessions.prefix(8)) { s in
                HStack {
                    Text(s.targetLabel)
                        .font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                        .frame(width: 52, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(s.hits)/\(s.darts) hit").font(.subheadline).foregroundStyle(Brand.text)
                        Text(Fmt.date(s.date)).font(.caption).foregroundStyle(Brand.text3)
                    }
                    Spacer()
                    Text(Fmt.pct(s.hitRate)).font(Brand.mono(14)).foregroundStyle(Brand.live)
                }
                .glassCard(padding: 12)
                .swipeActions {
                    Button(role: .destructive) {
                        context.delete(s); try? context.save()
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
    }
}

/// Live hit/miss logger for a single target double.
struct PracticeSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var target = 16
    @State private var darts = 0
    @State private var hits = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let targets = [20, 19, 18, 17, 16, 14, 12, 10, 8, 6, 4, 2, 25]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 22) {
                    targetPicker
                    liveCounter
                    tapButtons
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .navigationTitle("Practice session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(darts == 0)
                }
            }
        }
    }

    private var targetPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Target")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(targets, id: \.self) { t in
                        let label = t == 25 ? "Bull" : "D\(t)"
                        Button {
                            Haptics.selection(); target = t
                        } label: {
                            Text(label).font(Brand.mono(14, weight: .medium))
                                .foregroundStyle(target == t ? .white : Brand.text)
                                .padding(.horizontal, 14).padding(.vertical, 9)
                                .background(target == t ? AnyShapeStyle(Brand.inkGradient)
                                                        : AnyShapeStyle(.ultraThinMaterial),
                                            in: Capsule())
                        }
                        .accessibilityLabel("Target \(label)")
                    }
                }
            }
        }
        .glassCard()
    }

    private var liveCounter: some View {
        VStack(spacing: 8) {
            Text("\(hits) / \(darts)")
                .font(Brand.mono(46, weight: .bold))
                .foregroundStyle(Brand.text)
                .contentTransition(.numericText())
            Text(darts > 0 ? Fmt.pct(Double(hits) / Double(darts) * 100) + " on \(target == 25 ? "Bull" : "D\(target)")"
                           : "Hit or miss to begin")
                .font(.subheadline).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(hits) of \(darts) darts hit")
    }

    private var tapButtons: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(reduceMotion ? nil : Brand.ease(0.2)) { darts += 1 }
                Haptics.warning()
            } label: {
                Label("Miss", systemImage: "xmark")
            }
            .buttonStyle(GlassButtonStyle())

            Button {
                withAnimation(reduceMotion ? nil : Brand.ease(0.2)) { darts += 1; hits += 1 }
                Haptics.success()
            } label: {
                Label("Hit", systemImage: "checkmark")
            }
            .buttonStyle(InkButtonStyle())
        }
    }

    private func save() {
        let s = PracticeSession(targetValue: target, darts: darts, hits: hits)
        context.insert(s)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
