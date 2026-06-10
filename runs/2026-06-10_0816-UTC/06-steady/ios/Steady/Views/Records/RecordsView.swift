import SwiftUI
import SwiftData

/// The journal of past thought records, month-grouped, with full detail.
struct RecordsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ThoughtRecord.createdAt, order: .reverse) private var records: [ThoughtRecord]
    @State private var deleteTarget: ThoughtRecord?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if records.isEmpty {
                    EmptyStateView(
                        icon: "text.book.closed",
                        title: "No records yet",
                        message: "Your first thought record lives in the Today tab. Each one you finish lands here."
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.key) { month, items in
                            Section {
                                ForEach(items) { record in
                                    NavigationLink(value: record) {
                                        row(record)
                                    }
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            deleteTarget = record
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                Eyebrow(text: month)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Records")
            .navigationDestination(for: ThoughtRecord.self) { RecordDetailView(record: $0) }
            .alert("Delete this record?", isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let r = deleteTarget {
                        context.delete(r)
                        Haptics.warning()
                    }
                    deleteTarget = nil
                }
                Button("Cancel", role: .cancel) { deleteTarget = nil }
            }
        }
    }

    private var grouped: [(key: String, value: [ThoughtRecord])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        var order: [String] = []
        var buckets: [String: [ThoughtRecord]] = [:]
        for r in records {
            let key = fmt.string(from: r.createdAt)
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(r)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }

    private func row(_ record: ThoughtRecord) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(record.automaticThought)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text)
                .lineLimit(2)
            HStack(spacing: 10) {
                Text(record.createdAt, format: .dateTime.weekday(.abbreviated).day().month())
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                if let top = record.topEmotion {
                    Text("\(top.name) \(top.intensity)")
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.text3)
                }
                if record.beliefDrop > 0 {
                    Label("−\(record.beliefDrop)", systemImage: "arrow.down.right")
                        .font(Brand.mono(11, weight: .medium))
                        .foregroundStyle(Brand.live)
                        .accessibilityLabel("belief dropped \(record.beliefDrop) points")
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct RecordDetailView: View {
    let record: ThoughtRecord

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 14) {
                    section("Situation", record.situation)

                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: "Feelings · before → after")
                        ForEach(record.emotions) { emotion in
                            let after = record.emotionsAfter.first { $0.name == emotion.name }
                            HStack {
                                Text(emotion.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                Text(after != nil ? "\(emotion.intensity) → \(after?.intensity ?? 0)" : "\(emotion.intensity)")
                                    .font(Brand.mono(14, weight: .semibold))
                                    .foregroundStyle((after?.intensity ?? emotion.intensity) < emotion.intensity ? Brand.live : Brand.text2)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Automatic thought")
                        Text("“\(record.automaticThought)”")
                            .font(.body.italic())
                            .foregroundStyle(Brand.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Believed \(record.beliefBefore)% → \(record.beliefAfter)%")
                            .font(Brand.mono(13, weight: .medium))
                            .foregroundStyle(record.beliefDrop > 0 ? Brand.live : Brand.text3)
                    }
                    .glassCard()

                    if !record.distortionIDs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow(text: "Thinking traps spotted")
                            ForEach(record.distortionIDs, id: \.self) { id in
                                if let d = Distortions.named(id) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(Brand.live)
                                            .padding(.top, 2)
                                            .accessibilityHidden(true)
                                        Text(d.name)
                                            .font(.subheadline)
                                            .foregroundStyle(Brand.text)
                                    }
                                }
                            }
                        }
                        .glassCard()
                    }

                    if !record.evidenceFor.isEmpty || !record.evidenceAgainst.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow(text: "Evidence")
                            if !record.evidenceFor.isEmpty {
                                Text("For: \(record.evidenceFor)")
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                            }
                            if !record.evidenceAgainst.isEmpty {
                                Text("Against: \(record.evidenceAgainst)")
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                            }
                        }
                        .glassCard()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Balanced thought")
                        Text("“\(record.balancedThought)”")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Brand.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .glassCard()
                }
                .padding(16)
            }
        }
        .navigationTitle(record.createdAt.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: title)
            Text(body)
                .font(.body)
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .glassCard()
    }
}
