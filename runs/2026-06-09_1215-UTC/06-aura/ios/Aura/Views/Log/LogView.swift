import SwiftUI
import SwiftData

struct LogView: View {
    @Query(sort: \Attack.start, order: .reverse) private var attacks: [Attack]
    @State private var showEditor = false

    /// Attacks grouped by month, newest month first.
    private var grouped: [(key: Date, value: [Attack])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: attacks) { attack -> Date in
            cal.dateInterval(of: .month, for: attack.start)?.start ?? attack.start
        }
        return dict.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if attacks.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "list.bullet.rectangle",
                                       title: "No attacks logged",
                                       message: "When a headache strikes, log it here. Your history and trends build from these entries.")
                            .glassCard()
                            .padding(20)
                    }
                } else {
                    List {
                        ForEach(grouped, id: \.key) { month, items in
                            Section(Format.monthYear.string(from: month)) {
                                ForEach(items) { attack in
                                    NavigationLink {
                                        AttackDetailView(attack: attack)
                                    } label: {
                                        AttackRow(attack: attack)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.tap()
                        showEditor = true
                    } label: {
                        Label("Log attack", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                AttackEditorView(existing: nil)
            }
        }
    }
}

/// A single attack row: date, intensity, type, duration, trigger chips.
struct AttackRow: View {
    let attack: Attack

    private var durationText: String {
        if attack.isOngoing { return "Ongoing" }
        if let m = attack.durationMinutes { return Format.duration(minutes: m) }
        return "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                IntensityDot(intensity: attack.intensity)
                Text(attack.type.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Spacer()
                if attack.isOngoing {
                    TagChip(text: "Ongoing", systemImage: "clock", tint: Brand.danger)
                } else {
                    Text(durationText)
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text2)
                }
            }
            HStack(spacing: 8) {
                Text(Format.dayTime.string(from: attack.start))
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text3)
                Spacer()
            }
            if !attack.triggers.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(attack.triggers.prefix(4).sorted(by: { $0.name < $1.name }), id: \.persistentModelID) { t in
                        TagChip(text: t.name, tint: Brand.info)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(attack.type.label), intensity \(attack.intensity) of 10, \(durationText), \(Format.dayTime.string(from: attack.start))")
    }
}
