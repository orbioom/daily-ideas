import SwiftUI
import SwiftData

struct RitualsView: View {
    @Query(sort: \RitualCompletion.date, order: .reverse) private var completions: [RitualCompletion]
    @State private var selectedRitual: RitualTemplate?
    private var currentPhase: MoonPhase { MoonEngine.moonPhase() }
    private var todayRituals: [RitualTemplate] { RitualLibrary.rituals(for: currentPhase) }

    var body: some View {
        NavigationStack {
            ZStack {
                CrescentTheme.navy.ignoresSafeArea()
                List {
                    Section {
                        if todayRituals.isEmpty {
                            Text("No rituals for this phase yet")
                                .foregroundColor(CrescentTheme.silver)
                                .listRowBackground(CrescentTheme.cardBg)
                        } else {
                            ForEach(todayRituals) { ritual in
                                RitualRow(ritual: ritual, isCompleted: isCompleted(ritual))
                                    .listRowBackground(CrescentTheme.cardBg)
                                    .listRowSeparatorTint(CrescentTheme.silver.opacity(0.2))
                                    .onTapGesture { selectedRitual = ritual }
                            }
                        }
                    } header: {
                        Text(currentPhase.symbol + " " + currentPhase.rawValue + " Rituals")
                            .foregroundColor(CrescentTheme.gold)
                    }

                    Section {
                        ForEach(MoonPhase.allCases.filter { $0 != currentPhase }) { phase in
                            let phaseRituals = RitualLibrary.rituals(for: phase)
                            ForEach(phaseRituals) { ritual in
                                RitualRow(ritual: ritual, isCompleted: isCompleted(ritual))
                                    .listRowBackground(CrescentTheme.cardBg)
                                    .listRowSeparatorTint(CrescentTheme.silver.opacity(0.2))
                                    .onTapGesture { selectedRitual = ritual }
                            }
                        }
                    } header: {
                        Text("All Rituals")
                            .foregroundColor(CrescentTheme.gold)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Rituals")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedRitual) { ritual in
                RitualDetailView(ritual: ritual, isCompleted: isCompleted(ritual))
            }
        }
    }

    private func isCompleted(_ ritual: RitualTemplate) -> Bool {
        let cal = Calendar.current
        return completions.contains {
            $0.templateId == ritual.id && cal.isDateInToday($0.date)
        }
    }
}

struct RitualRow: View {
    let ritual: RitualTemplate
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(isCompleted ? "✓" : ritual.phase.symbol)
                .font(.title3)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(ritual.title)
                    .font(.callout)
                    .foregroundColor(CrescentTheme.pearl)
                Text(ritual.phase.rawValue + " • " + ritual.duration)
                    .font(.caption)
                    .foregroundColor(CrescentTheme.silver)
            }
            Spacer()
            if isCompleted {
                Text("Done")
                    .font(.caption)
                    .foregroundColor(CrescentTheme.gold)
            }
        }
        .padding(.vertical, 4)
    }
}
