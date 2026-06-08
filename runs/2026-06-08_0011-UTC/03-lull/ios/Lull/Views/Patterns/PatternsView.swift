import SwiftUI
import SwiftData

struct PatternsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BreathPattern.order) private var patterns: [BreathPattern]
    @AppStorage("lull.selectedPattern") private var selectedID = ""

    @State private var showingNew = false
    @State private var editing: BreathPattern?
    @State private var previewing: BreathPattern?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if patterns.isEmpty {
                    EmptyStateView(icon: "square.on.square", title: "No patterns",
                                   message: "Add a breathing pattern to begin.")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(patterns) { p in card(p) }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Patterns")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add pattern")
                }
            }
            .sheet(isPresented: $showingNew) { PatternEditView(pattern: nil) }
            .sheet(item: $editing) { PatternEditView(pattern: $0) }
            .fullScreenCover(item: $previewing) { SessionPlayerView(pattern: $0) }
        }
    }

    private func card(_ p: BreathPattern) -> some View {
        let selected = p.id.uuidString == selectedID
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(p.name).font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                            if p.isCustom {
                                Text("CUSTOM").font(Brand.mono(9, weight: .medium))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Brand.hairline, in: Capsule()).foregroundStyle(Brand.text2)
                            }
                        }
                        Text(p.detail).font(.subheadline).foregroundStyle(Brand.text2)
                    }
                    Spacer()
                    Button { selectedID = p.id.uuidString; Haptics.selection() } label: {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.title2).foregroundStyle(selected ? Brand.live : Brand.text3)
                    }
                    .accessibilityLabel(selected ? "Selected" : "Select \(p.name)")
                }
                HStack(spacing: 16) {
                    pill(p.ratioLabel, "in-hold-out-hold")
                    pill("\(p.rounds)", "rounds")
                    pill(Format.minutes(p.totalSeconds/60), "length")
                }
                Button { previewing = p } label: {
                    Label("Try now", systemImage: "play.fill").font(.subheadline)
                }
                .buttonStyle(GlassButtonStyle())
            }
            .contentShape(Rectangle())
            .contextMenu {
                if p.isCustom {
                    Button { editing = p } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) {
                        context.delete(p); try? context.save()
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
    }

    private func pill(_ v: String, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(v).font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text)
            Text(l).font(.caption2).foregroundStyle(Brand.text3).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
