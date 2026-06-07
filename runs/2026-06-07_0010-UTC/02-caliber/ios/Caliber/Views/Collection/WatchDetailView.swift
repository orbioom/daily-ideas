import SwiftUI
import SwiftData
import Charts

struct WatchDetailView: View {
    @Bindable var watch: Watch
    @Environment(\.modelContext) private var context
    @AppStorage("driftHorizonDays") private var driftHorizonDays = 7
    @State private var showingEdit = false
    @State private var showingMeasure = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    rateCard
                    if watch.measurements.count >= 2 { chartCard }
                    positionalCard
                    measurementsSection
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
            }
        }
        .navigationTitle(watch.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingMeasure = true } label: { Label("Add reading", systemImage: "stopwatch") }
                    Button { showingEdit = true } label: { Label("Edit watch", systemImage: "pencil") }
                    Button {
                        watch.isFavorite.toggle(); try? context.save()
                    } label: { Label(watch.isFavorite ? "Unfavorite" : "Favorite", systemImage: "star") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEdit) { WatchEditView(watch: watch) }
        .sheet(isPresented: $showingMeasure) { MeasureView(preselected: watch) }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Circle().fill(Color(hex: watch.accentHex)).frame(width: 16, height: 16)
                .accessibilityHidden(true)
            if !watch.movement.isEmpty || !watch.modelRef.isEmpty {
                Text([watch.modelRef, watch.movement].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.footnote).foregroundStyle(Brand.text2)
            }
            HStack(spacing: 8) {
                Chip(text: "\(watch.powerReserveHours)h reserve", system: "battery.75")
                if !watch.notes.isEmpty { Chip(text: "noted", system: "note.text") }
            }
            if !watch.notes.isEmpty {
                Text(watch.notes).font(.footnote).foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity).glassCard(padding: 18)
    }

    private var rateCard: some View {
        let rate = watch.dailyRate
        let drift = RateEngine.projectedDrift(rate: rate, overDays: Double(driftHorizonDays))
        return VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Daily rate")
                    Text(Fmt.rate(rate)).font(Brand.mono(30, weight: .bold)).foregroundStyle(Brand.text)
                    Text(watch.grade.rawValue).font(.subheadline).foregroundStyle(watch.grade.tint)
                }
                Spacer()
                StatusDot(color: watch.grade.tint).scaleEffect(1.6)
            }
            Divider().overlay(Brand.hairline)
            HStack(spacing: 12) {
                StatTile(value: drift.map { Fmt.seconds($0) } ?? "—",
                         label: "drift / \(driftHorizonDays)d",
                         accent: (drift ?? 0) >= 0 ? Brand.warn : Brand.info)
                StatTile(value: RateEngine.recentRate(watch.measurements).map { Fmt.rate($0) } ?? "—",
                         label: "recent rate")
            }
        }
        .glassCard(padding: 18)
    }

    private var chartCard: some View {
        let samples = RateEngine.samples(from: watch.measurements)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Offset over time", trailing: "seconds")
            Chart {
                ForEach(Array(samples.enumerated()), id: \.offset) { _, s in
                    LineMark(x: .value("Day", s.days), y: .value("Offset", s.offset))
                        .foregroundStyle(Color(hex: watch.accentHex))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Day", s.days), y: .value("Offset", s.offset))
                        .foregroundStyle(Color(hex: watch.accentHex))
                }
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(Brand.text3.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .frame(height: 180)
            .accessibilityLabel("Offset in seconds across \(samples.count) readings")
        }
        .glassCard()
    }

    private var positionalCard: some View {
        let rates = RateEngine.positionalRates(watch.measurements)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "By position")
            if rates.isEmpty {
                Text("Log at least two readings in the same position to see how it runs there.")
                    .font(.footnote).foregroundStyle(Brand.text2)
            } else {
                ForEach(rates, id: \.0) { pos, r in
                    HStack {
                        Text(pos.label).font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text(Fmt.rate(r)).font(Brand.mono(14, weight: .medium))
                            .foregroundStyle(r >= 0 ? Brand.warn : Brand.info)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(pos.label): \(Fmt.rateSpoken(r))")
                }
            }
        }
        .glassCard()
    }

    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Readings", trailing: "\(watch.measurements.count)")
            if watch.measurements.isEmpty {
                Text("No readings yet. Add one to start tracking accuracy.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                    .frame(maxWidth: .infinity).glassCard(padding: 18)
            } else {
                ForEach(watch.sortedMeasurements) { m in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Fmt.seconds(m.offsetSeconds))
                                .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                            Text(Fmt.dateTime(m.timestamp)).font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Chip(text: m.position.short)
                    }
                    .glassCard(padding: 12)
                    .swipeActions {
                        Button(role: .destructive) {
                            watch.measurements.removeAll { $0.id == m.id }
                            context.delete(m); try? context.save()
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }
}
