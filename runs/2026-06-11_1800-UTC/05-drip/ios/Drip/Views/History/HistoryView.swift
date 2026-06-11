import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DrinkEntry.date, order: .reverse) private var entries: [DrinkEntry]
    @Environment(\.modelContext) private var ctx

    private var grouped: [(key: Date, entries: [DrinkEntry])] {
        let cal = Calendar.current
        var dict: [Date: [DrinkEntry]] = [:]
        for e in entries {
            let d = cal.startOfDay(for: e.date)
            dict[d, default: []].append(e)
        }
        return dict.map { (key: $0.key, entries: $0.value) }.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "drop.halffull")
                            .font(.system(size: 56))
                            .foregroundStyle(DripTheme.accent.opacity(0.3))
                            .accessibilityHidden(true)
                        Text("No drinks logged yet")
                            .font(.headline).foregroundStyle(DripTheme.text)
                        Text("Use Today tab to log your drinks.")
                            .foregroundStyle(DripTheme.subtle)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DripTheme.bg)
                } else {
                    List {
                        ForEach(grouped, id: \.key) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    DrinkRowView(entry: entry)
                                        .listRowBackground(DripTheme.bg)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                }
                            } header: {
                                HStack {
                                    Text(group.key.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(DripTheme.subtle)
                                    Spacer()
                                    Text(String(format: "%.1f std", group.entries.reduce(0) { $0 + $1.standardDrinks }))
                                        .font(.caption)
                                        .foregroundStyle(DripTheme.accent)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(DripTheme.bg)
                }
            }
            .background(DripTheme.bg)
            .navigationTitle("History")
        }
    }
}
