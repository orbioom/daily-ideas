import SwiftUI
import SwiftData

/// Search the whole catalog and set either partner's verdict directly.
struct BrowseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query private var verdicts: [Verdict]
    @State private var search = ""
    @State private var genderFilter: NameGender? = nil

    private var results: [NameCard] {
        var base = NameCatalog.all
        if let g = genderFilter { base = base.filter { $0.gender == g } }
        let trimmed = search.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            base = base.filter {
                $0.name.localizedCaseInsensitiveContains(trimmed) ||
                $0.origin.localizedCaseInsensitiveContains(trimmed) ||
                $0.meaning.localizedCaseInsensitiveContains(trimmed)
            }
        }
        return base.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty {
                    EmptyStateView(icon: "magnifyingglass",
                                   title: "No names found",
                                   message: "Try a different search or clear the gender filter.")
                } else {
                    List {
                        ForEach(results) { card in
                            NavigationLink(value: card) {
                                browseRow(card)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Browse \(NameCatalog.all.count)")
            .searchable(text: $search, prompt: "Name, origin, or meaning")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Gender", selection: $genderFilter) {
                        Text("All").tag(NameGender?.none)
                        ForEach(NameGender.allCases) { g in
                            Text(g.label).tag(NameGender?.some(g))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationDestination(for: NameCard.self) { card in
                NameDetailView(card: card)
            }
        }
    }

    private func browseRow(_ card: NameCard) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.genderColor(card.gender))
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.headline)
                    .foregroundStyle(Theme.ink(scheme))
                Text(card.meaning)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
                    .lineLimit(1)
            }
            Spacer()
            verdictDots(card)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.name), \(card.gender.label), \(card.meaning)")
    }

    private func verdictDots(_ card: NameCard) -> some View {
        HStack(spacing: 4) {
            ForEach(Partner.allCases) { partner in
                let v = MatchEngine.latestVerdict(verdicts: verdicts, nameID: card.id, partner: partner)
                Image(systemName: symbol(for: v?.decision))
                    .font(.caption)
                    .foregroundStyle(v?.decision == .pass ? Theme.inkSoft(scheme)
                                     : v == nil ? Theme.inkSoft(scheme).opacity(0.3)
                                     : Theme.partnerColor(partner))
            }
        }
        .accessibilityHidden(true)
    }

    private func symbol(for decision: Decision?) -> String {
        switch decision {
        case .superlike: return "star.fill"
        case .like: return "heart.fill"
        case .pass: return "xmark"
        case nil: return "circle"
        }
    }
}

/// Detail page: set each partner's verdict explicitly.
struct NameDetailView: View {
    let card: NameCard
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query private var verdicts: [Verdict]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NameCardView(card: card, partner: .a)
                    .frame(height: 420)
                    .padding(.horizontal)

                ForEach(Partner.allCases) { partner in
                    partnerRow(partner)
                }

                if isMatch {
                    Label("You both like this name!", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.blush)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.blush.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Theme.background(scheme))
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isMatch: Bool {
        Partner.allCases.allSatisfy { partner in
            MatchEngine.latestVerdict(verdicts: verdicts, nameID: card.id, partner: partner)?.decision != Decision.pass &&
            MatchEngine.latestVerdict(verdicts: verdicts, nameID: card.id, partner: partner) != nil
        }
    }

    private func partnerRow(_ partner: Partner) -> some View {
        let current = MatchEngine.latestVerdict(verdicts: verdicts, nameID: card.id, partner: partner)?.decision
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(Theme.partnerColor(partner)).frame(width: 12, height: 12)
                Text(PartnerNames.name(partner))
                    .font(.headline)
                    .foregroundStyle(Theme.ink(scheme))
            }
            HStack(spacing: 10) {
                ForEach(Decision.allCases, id: \.self) { decision in
                    Button {
                        set(decision, for: partner)
                    } label: {
                        Text(decision.label)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(current == decision
                                        ? Theme.partnerColor(partner).opacity(0.2) : Theme.card(scheme),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(current == decision ? Theme.partnerColor(partner)
                                        : Theme.inkSoft(scheme).opacity(0.25), lineWidth: 1.5))
                            .foregroundStyle(Theme.ink(scheme))
                    }
                    .accessibilityAddTraits(current == decision ? .isSelected : [])
                    .accessibilityLabel("\(PartnerNames.name(partner)): \(decision.label)")
                }
            }
        }
        .padding()
        .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func set(_ decision: Decision, for partner: Partner) {
        for v in verdicts where v.nameID == card.id && v.partner == partner {
            context.delete(v)
        }
        context.insert(Verdict(nameID: card.id, partner: partner, decision: decision))
        if decision != .pass,
           let other = MatchEngine.latestVerdict(verdicts: verdicts, nameID: card.id, partner: partner.other),
           other.decision != .pass {
            Haptics.match()
        } else {
            Haptics.tap()
        }
    }
}
