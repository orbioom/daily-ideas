import SwiftUI
import SwiftData
import Charts

/// The weekly relationship pulse: three ratings, a note, and the trend.
struct PulseView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CheckIn.date, order: .reverse) private var checkIns: [CheckIn]

    @State private var connection = 3
    @State private var communication = 3
    @State private var fun = 3
    @State private var note = ""
    @State private var justSaved = false

    private var doneThisWeek: Bool { DuetEngine.hasCheckInThisWeek(checkIns) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 14) {
                        checkInCard
                        trendCard
                        historyCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Pulse")
        }
    }

    private var checkInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "This week")
                Spacer()
                if doneThisWeek {
                    HStack(spacing: 5) {
                        StatusDot()
                        Text("checked in")
                            .font(.caption)
                            .foregroundStyle(Brand.live)
                    }
                }
            }
            if justSaved {
                Label("Pulse saved — see you next week.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Brand.live)
            }
            ratingRow("Connection", value: $connection)
            ratingRow("Communication", value: $communication)
            ratingRow("Fun", value: $fun)
            TextField("One sentence about this week (optional)", text: $note, axis: .vertical)
                .lineLimit(2...4)
            Button(doneThisWeek ? "Check in again anyway" : "Save this week's pulse") {
                context.insert(CheckIn(connection: connection, communication: communication,
                                       fun: fun, note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
                note = ""
                justSaved = true
                Haptics.success()
            }
            .buttonStyle(InkButtonStyle())
            Text("Do it together, Sunday evenings work well. Low scores aren't failures — they're agenda items.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private func ratingRow(_ label: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Spacer()
                Text("\(value.wrappedValue)/5")
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text2)
            }
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { n in
                    Button {
                        value.wrappedValue = n
                        Haptics.selection()
                    } label: {
                        Circle()
                            .fill(n <= value.wrappedValue ? AnyShapeStyle(Brand.live.gradient) : AnyShapeStyle(.ultraThinMaterial))
                            .frame(height: 26)
                            .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(label) \(n) of 5")
                    .accessibilityAddTraits(n == value.wrappedValue ? .isSelected : [])
                }
            }
        }
    }

    @ViewBuilder
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Trend")
            if checkIns.count < 2 {
                Text(checkIns.isEmpty
                     ? "Your first check-in starts the chart."
                     : "One more check-in and the trend appears.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            } else {
                let recent = Array(checkIns.prefix(8).reversed())
                Chart {
                    ForEach(recent) { c in
                        LineMark(x: .value("Week", c.date, unit: .day),
                                 y: .value("Score", c.connection),
                                 series: .value("Metric", "Connection"))
                            .foregroundStyle(by: .value("Metric", "Connection"))
                        LineMark(x: .value("Week", c.date, unit: .day),
                                 y: .value("Score", c.communication),
                                 series: .value("Metric", "Communication"))
                            .foregroundStyle(by: .value("Metric", "Communication"))
                        LineMark(x: .value("Week", c.date, unit: .day),
                                 y: .value("Score", c.fun),
                                 series: .value("Metric", "Fun"))
                            .foregroundStyle(by: .value("Metric", "Fun"))
                    }
                }
                .chartYScale(domain: 0...5)
                .chartForegroundStyleScale([
                    "Connection": Brand.live,
                    "Communication": Brand.info,
                    "Fun": Brand.warn
                ])
                .frame(height: 170)
                .accessibilityLabel("Line chart of connection, communication, and fun scores over recent check-ins")
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private var historyCard: some View {
        if !checkIns.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "History")
                ForEach(checkIns.prefix(8)) { c in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.date, format: .dateTime.day().month().year())
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                            if !c.note.isEmpty {
                                Text(c.note)
                                    .font(.caption)
                                    .foregroundStyle(Brand.text2)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                        Text(String(format: "%.1f", c.average))
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(c.average >= 3.5 ? Brand.live : Brand.warn)
                            .accessibilityLabel("average \(String(format: "%.1f", c.average)) out of 5")
                    }
                    .padding(.vertical, 3)
                    .accessibilityElement(children: .combine)
                    .contextMenu {
                        Button(role: .destructive) {
                            context.delete(c)
                            Haptics.warning()
                        } label: {
                            Label("Delete check-in", systemImage: "trash")
                        }
                    }
                    if c.id != checkIns.prefix(8).last?.id { Divider() }
                }
            }
            .glassCard()
        }
    }
}
