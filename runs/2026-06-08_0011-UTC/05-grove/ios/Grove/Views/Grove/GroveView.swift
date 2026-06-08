import SwiftUI
import SwiftData

struct GroveView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FocusSession.date, order: .reverse) private var sessions: [FocusSession]

    @State private var selected: FocusSession?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)

    private var grouped: [(Date, [FocusSession])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: sessions) { cal.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0]!.sorted { $0.date < $1.date }) }
    }
    private var stats: FocusStats { FocusStats.make(from: sessions) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if sessions.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "tree.fill", title: "Your grove is empty",
                                       message: "Complete a focus session to plant your first tree.")
                        Button("Load sample grove") {
                            SampleData.load(into: context); Haptics.success()
                        }
                        .buttonStyle(GlassButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            GlassCard {
                                HStack {
                                    StatTile(value: "\(stats.treesPlanted)", label: "Trees")
                                    Divider().frame(height: 36).overlay(Brand.hairline)
                                    StatTile(value: Format.minutes(stats.totalMinutes), label: "Focused")
                                    Divider().frame(height: 36).overlay(Brand.hairline)
                                    StatTile(value: "\(stats.streakDays)", label: "Streak")
                                }
                            }
                            ForEach(grouped, id: \.0) { day, items in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(Format.day.string(from: day))
                                        .font(Brand.mono(12, weight: .medium)).tracking(0.8)
                                        .foregroundStyle(Brand.text3)
                                    LazyVGrid(columns: columns, spacing: 4) {
                                        ForEach(items) { s in
                                            Button { selected = s } label: {
                                                TreeView(progress: 1,
                                                         species: TreeSpecies(rawValue: s.species) ?? .shrub,
                                                         withered: !s.success, size: 78)
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel("\(s.success ? "Healthy" : "Withered") \(TreeSpecies(rawValue: s.species)?.name ?? "tree"), \(s.tagName), \(Format.minutes(s.minutes))")
                                        }
                                    }
                                }
                                .glassCard()
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Grove")
            .sheet(item: $selected) { s in TreeDetailSheet(session: s) }
        }
    }
}

struct TreeDetailSheet: View {
    let session: FocusSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 18) {
                    TreeView(progress: 1, species: TreeSpecies(rawValue: session.species) ?? .shrub,
                             withered: !session.success, size: 200)
                        .padding(.top, 20)
                    Text(TreeSpecies(rawValue: session.species)?.name ?? "Tree")
                        .font(.title2.weight(.bold)).foregroundStyle(Brand.text)
                    GlassCard {
                        VStack(spacing: 12) {
                            row("Status", session.success ? "Healthy" : "Withered")
                            Divider().overlay(Brand.hairline)
                            row("Tag", session.tagName)
                            Divider().overlay(Brand.hairline)
                            row("Focused", Format.minutes(session.minutes))
                            Divider().overlay(Brand.hairline)
                            row("Planned", "\(session.plannedMinutes) min")
                            Divider().overlay(Brand.hairline)
                            row("When", Format.dayTime.string(from: session.date))
                        }
                    }
                    Button(role: .destructive) {
                        context.delete(session); try? context.save(); Haptics.warning(); dismiss()
                    } label: { Label("Remove tree", systemImage: "trash").frame(maxWidth: .infinity) }
                        .buttonStyle(GlassButtonStyle())
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Tree")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func row(_ l: String, _ v: String) -> some View {
        HStack { Text(l).foregroundStyle(Brand.text2)
            Spacer(); Text(v).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text) }
    }
}
