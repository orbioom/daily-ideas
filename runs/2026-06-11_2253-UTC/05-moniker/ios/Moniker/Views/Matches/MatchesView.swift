import SwiftUI
import SwiftData

struct MatchesView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("babyLastName") private var babyLastName = ""
    @Query private var verdicts: [Verdict]
    @State private var genderFilter: NameGender? = nil

    private var allMatches: [MatchEngine.Match] { MatchEngine.matches(verdicts: verdicts) }
    private var matches: [MatchEngine.Match] {
        guard let g = genderFilter else { return allMatches }
        return allMatches.filter { $0.card.gender == g }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allMatches.isEmpty {
                    EmptyStateView(icon: "heart.slash",
                                   title: "No matches yet",
                                   message: "When both of you like the same name, it shows up here — ranked by how much you both love it. Head to Swipe to get going.")
                } else {
                    List {
                        Section {
                            ForEach(matches) { match in
                                matchRow(match)
                            }
                        } header: {
                            Text("\(allMatches.count) shared name\(allMatches.count == 1 ? "" : "s")")
                        }
                        if matches.isEmpty {
                            Text("No \(genderFilter?.label.lowercased() ?? "") matches yet.")
                                .foregroundStyle(Theme.inkSoft(scheme))
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Matches")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Gender", selection: $genderFilter) {
                        Text("All").tag(NameGender?.none)
                        ForEach(NameGender.allCases) { g in
                            Text(g.label).tag(NameGender?.some(g))
                        }
                    }
                    .pickerStyle(.menu)
                }
                if !allMatches.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: MatchEngine.shareText(matches: allMatches, babyLastName: babyLastName)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share shortlist")
                    }
                }
            }
        }
    }

    private func matchRow(_ match: MatchEngine.Match) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.genderColor(match.card.gender).opacity(0.16))
                Text(String(match.card.name.prefix(1)))
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.genderColor(match.card.gender))
            }
            .frame(width: 48, height: 48)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(babyLastName.isEmpty ? match.card.name : "\(match.card.name) \(babyLastName)")
                    .font(.headline)
                    .foregroundStyle(Theme.ink(scheme))
                Text("\(match.card.origin) · \(match.card.meaning)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
                    .lineLimit(2)
            }
            Spacer()
            heatBadge(match.heat)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(match.card.name), \(heatLabel(match.heat))")
    }

    private func heatBadge(_ heat: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<2, id: \.self) { i in
                Image(systemName: i < heat ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(Theme.butter)
            }
        }
        .accessibilityHidden(true)
    }

    private func heatLabel(_ heat: Int) -> String {
        switch heat {
        case 2: return "you both love it"
        case 1: return "one of you loves it"
        default: return "you both like it"
        }
    }
}
