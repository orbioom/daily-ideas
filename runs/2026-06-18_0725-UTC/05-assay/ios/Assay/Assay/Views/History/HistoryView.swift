import SwiftUI
import SwiftData

/// List of logged panels (draw dates) → panel detail.
struct HistoryView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query private var results: [LabResult]
    @State private var showLog = false

    private var sex: BiologicalSex { settings.biologicalSex }
    private var panels: [Panel] { LabAnalytics.panels(from: results) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if panels.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.plus",
                        title: "No panels logged",
                        message: "Your blood draws will appear here as a timeline once you log them.",
                        ctaTitle: "Log a panel",
                        action: { showLog = true }
                    )
                } else {
                    List {
                        ForEach(panels) { panel in
                            NavigationLink {
                                PanelDetailView(panelId: panel.id)
                            } label: {
                                panelRow(panel)
                            }
                            .listRowBackground(Theme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Panels")
            .sheet(isPresented: $showLog) { LogPanelSheet() }
        }
    }

    private func panelRow(_ panel: Panel) -> some View {
        let summary = StatsEngine.summarize(panelResults: panel.results, sex: sex)
        return HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(dayNumber(panel.drawDate))
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.accent)
                Text(monthShort(panel.drawDate))
                    .font(Theme.rounded(11, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(width: 48)
            .padding(.vertical, 6)
            .background(Theme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(Fmt.date(panel.drawDate))
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(panel.labName.isEmpty ? "\(panel.results.count) markers" : "\(panel.labName) · \(panel.results.count) markers")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if let s = summary {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(s.optimalCount + s.inRangeCount)/\(s.classifiedCount)")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(s.outOfRangeCount == 0 ? Theme.good : Theme.ink)
                    Text("in range")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func dayNumber(_ d: Date) -> String {
        String(Calendar.current.component(.day, from: d))
    }
    private func monthShort(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM"
        return f.string(from: d).uppercased()
    }
}
