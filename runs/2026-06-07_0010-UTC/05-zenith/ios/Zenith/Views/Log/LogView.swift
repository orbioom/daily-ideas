import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Observation.date, order: .reverse) private var observations: [Observation]
    @State private var showingAdd = false
    @State private var editTarget: Observation?

    private var uniqueTargets: Int { Set(observations.map(\.targetName)).count }
    private var avgRating: Double {
        guard !observations.isEmpty else { return 0 }
        return Double(observations.reduce(0) { $0 + $1.rating }) / Double(observations.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if observations.isEmpty {
                        ScrollView {
                            EmptyStateView(icon: "book",
                                           title: "No observations yet",
                                           message: "Log what you see and the conditions you saw it in. Your record builds over time.")
                                .padding(.top, 60)
                        }
                    } else {
                        List {
                            summaryRow
                            ForEach(observations) { o in
                                Button { editTarget = o } label: { ObservationRow(observation: o) }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                            }
                            .onDelete(perform: delete)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Observing log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log observation")
                }
            }
            .sheet(isPresented: $showingAdd) { ObservationEditView(observation: nil, prefillTarget: nil) }
            .sheet(item: $editTarget) { o in ObservationEditView(observation: o, prefillTarget: nil) }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(observations.count)", label: "Sessions")
            StatTile(value: "\(uniqueTargets)", label: "Targets", accent: Brand.info)
            StatTile(value: Fmt.one(avgRating), label: "Avg rating", accent: Brand.warn)
        }
        .listRowBackground(Color.clear).listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 10, trailing: 0))
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(observations[i]) }
        try? context.save(); Haptics.tap()
    }
}

struct ObservationRow: View {
    let observation: Observation
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: observation.targetType.symbol)
                    .foregroundStyle(observation.targetType.tint).frame(width: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(observation.targetName.isEmpty ? "Target" : observation.targetName)
                        .font(.headline).foregroundStyle(Brand.text)
                    if !observation.constellation.isEmpty {
                        Text(observation.constellation).font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                StarRating(value: observation.rating)
            }
            HStack(spacing: 8) {
                if observation.magnification > 0 {
                    Chip(text: Fmt.mag(observation.magnification), system: "plus.magnifyingglass")
                }
                Chip(text: "Bortle \(observation.bortle)", system: "moon")
                Chip(text: Fmt.shortDate(observation.date))
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(observation.targetName), rated \(observation.rating) of 5, \(Fmt.date(observation.date))")
    }
}
