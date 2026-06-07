import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Catch.date, order: .reverse) private var catches: [Catch]
    @AppStorage("useMetric") private var useMetric = false
    @State private var showingAdd = false

    private var biggest: Catch? { catches.max { $0.lengthInches < $1.lengthInches } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if catches.isEmpty {
                        ScrollView {
                            EmptyStateView(icon: "fish",
                                           title: "No catches yet",
                                           message: "Log your first fish with the conditions and the fly that worked.")
                                .padding(.top, 60)
                        }
                    } else {
                        List {
                            summaryRow
                            ForEach(catches) { c in
                                Button { editTarget = c } label: { CatchRow(entry: c) }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: delete)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Catch log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log a catch")
                }
            }
            .sheet(isPresented: $showingAdd) { CatchEditView(entry: nil) }
            .sheet(item: $editTarget) { c in CatchEditView(entry: c) }
        }
    }

    @State private var editTarget: Catch?

    private var summaryRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(catches.count)", label: "Catches")
            StatTile(value: biggest.map { Units.length($0.lengthInches, metric: useMetric) } ?? "—",
                     label: "Biggest", accent: Brand.magic)
            StatTile(value: "\(RiffleLogic.bySpecies(catches).count)", label: "Species", accent: Brand.info)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 10, trailing: 0))
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(catches[i]) }
        try? context.save(); Haptics.tap()
    }
}

struct CatchRow: View {
    let entry: Catch
    @AppStorage("useMetric") private var useMetric = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "fish").foregroundStyle(Brand.info)
                    .frame(width: 24).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.species.isEmpty ? "Fish" : entry.species)
                        .font(.headline).foregroundStyle(Brand.text)
                    if !entry.location.isEmpty {
                        Text(entry.location).font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                if entry.lengthInches > 0 {
                    Text(Units.length(entry.lengthInches, metric: useMetric))
                        .font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                }
            }
            HStack(spacing: 8) {
                if !entry.patternName.isEmpty {
                    Chip(text: entry.patternName, system: "ant")
                }
                Chip(text: entry.weather.label, system: entry.weather.symbol)
                if entry.waterTempF > 0 {
                    Chip(text: Units.temp(entry.waterTempF, metric: useMetric), system: "thermometer.medium")
                }
                Chip(text: Fmt.shortDate(entry.date))
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.species), \(Units.length(entry.lengthInches, metric: useMetric)) on \(entry.patternName), \(Fmt.date(entry.date))")
    }
}
