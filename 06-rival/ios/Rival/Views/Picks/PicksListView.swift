import SwiftUI
import SwiftData

struct PicksListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Pick.createdAt, order: .reverse) private var picks: [Pick]
    @State private var resultFilter: PickResult?
    @State private var showAdd = false

    private var filtered: [Pick] {
        guard let f = resultFilter else { return picks }
        return picks.filter { $0.result == f }
    }

    private var totalRecord: String {
        let won = picks.filter { $0.result == .correct }.count
        let lost = picks.filter { $0.result == .incorrect }.count
        let push = picks.filter { $0.result == .push }.count
        return "\(won)-\(lost)-\(push)"
    }

    var body: some View {
        NavigationStack {
            Group {
                if picks.isEmpty {
                    emptyState
                } else {
                    List {
                        recordHeader
                        filterRow
                        ForEach(filtered) { pick in
                            PickRowView(pick: pick)
                        }
                        .onDelete { idx in
                            let list = filtered
                            for i in idx { context.delete(list[i]) }
                            try? context.save()
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Picks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add pick")
                }
            }
            .sheet(isPresented: $showAdd) { AddPickView() }
        }
    }

    private var recordHeader: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Text(totalRecord)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(RivalTheme.label)
                Text("W-L-P All Time")
                    .font(.caption)
                    .foregroundColor(RivalTheme.secondaryLabel)
            }
            Spacer()
        }
        .listRowBackground(Color.clear)
        .accessibilityLabel("All-time record: \(totalRecord) wins-losses-pushes")
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", nil)
                filterChip("Pending", .pending)
                filterChip("Won", .correct)
                filterChip("Lost", .incorrect)
                filterChip("Push", .push)
            }
            .padding(.horizontal, 4)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
    }

    private func filterChip(_ label: String, _ result: PickResult?) -> some View {
        let selected = resultFilter == result
        return Button(action: { resultFilter = selected ? nil : result }) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(selected ? RivalTheme.accent : RivalTheme.secondary))
                .foregroundColor(selected ? .white : RivalTheme.secondaryLabel)
        }
        .accessibilityLabel(label + (selected ? ", selected" : ""))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🎯").font(.system(size: 64)).accessibilityHidden(true)
            Text("No Picks Yet").font(.title2.bold())
            Text("Start making predictions!").foregroundColor(RivalTheme.secondaryLabel)
            Button("Add First Pick") { showAdd = true }.buttonStyle(.borderedProminent)
                .accessibilityLabel("Add first pick")
        }
        .padding()
    }
}

struct PickRowView: View {
    @Environment(\.modelContext) private var context
    @Bindable var pick: Pick

    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .short; return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Result indicator
            Circle()
                .fill(RivalTheme.resultColor(pick.result))
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pick.pickedTeamName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(RivalTheme.label)
                    Spacer()
                    Text(pick.result.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundColor(RivalTheme.resultColor(pick.result))
                }
                HStack(spacing: 8) {
                    Text(pick.pickType.rawValue)
                        .font(.caption)
                        .foregroundColor(RivalTheme.secondaryLabel)
                    if let matchup = pick.matchup {
                        Text("·").foregroundColor(RivalTheme.secondaryLabel)
                        Text("\(matchup.awayTeamName) @ \(matchup.homeTeamName)")
                            .font(.caption)
                            .foregroundColor(RivalTheme.secondaryLabel)
                            .lineLimit(1)
                    }
                }
                HStack(spacing: 8) {
                    confidenceBadge
                    if pick.matchup != nil {
                        Text("·").foregroundColor(RivalTheme.secondaryLabel)
                        Text(Self.fmt.string(from: pick.matchup!.gameDate))
                            .font(.caption2)
                            .foregroundColor(RivalTheme.secondaryLabel)
                    }
                }
            }

            if pick.result == .pending {
                Menu {
                    Button(action: { setResult(.correct) }) { Label("Mark Won ✅", systemImage: "checkmark.circle") }
                    Button(action: { setResult(.incorrect) }) { Label("Mark Lost ❌", systemImage: "xmark.circle") }
                    Button(action: { setResult(.push) }) { Label("Mark Push ↔️", systemImage: "minus.circle") }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundColor(RivalTheme.secondaryLabel)
                }
                .accessibilityLabel("Update pick result")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pick.pickedTeamName), \(pick.result.rawValue), \(pick.confidence.label)")
    }

    private var confidenceBadge: some View {
        Text(pick.confidence.label)
            .font(.caption2.weight(.semibold))
            .foregroundColor(RivalTheme.confidenceColor(pick.confidence))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(RivalTheme.confidenceColor(pick.confidence).opacity(0.15)))
    }

    private func setResult(_ result: PickResult) {
        pick.result = result
        try? context.save()
    }
}
