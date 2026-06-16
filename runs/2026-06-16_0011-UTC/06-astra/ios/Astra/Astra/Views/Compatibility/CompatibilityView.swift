import SwiftUI
import SwiftData

struct CompatibilityView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Profile.createdDate) private var profiles: [Profile]

    @State private var firstID: UUID?
    @State private var secondID: UUID?
    @State private var paywallReason: PaywallReason?
    @State private var showAddProfile = false

    private var first: Profile? { profiles.first { $0.id == firstID } }
    private var second: Profile? { profiles.first { $0.id == secondID } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.skyGradient.ignoresSafeArea()
                Starfield(starCount: 35).ignoresSafeArea()
                content
            }
            .navigationTitle("Compatibility")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAddProfile) { ProfileEditorView(profile: nil) }
            .onAppear(perform: defaultSelections)
        }
    }

    @ViewBuilder
    private var content: some View {
        if !isPro {
            locked
        } else if profiles.count < 2 {
            EmptyStateView(
                symbol: "heart.circle.fill",
                title: "Add a second chart",
                message: "Compatibility compares two charts. Add at least one more to see your synastry.",
                actionTitle: "Add a chart"
            ) { showAddProfile = true }
            .padding()
        } else {
            loaded
        }
    }

    private var loaded: some View {
        ScrollView {
            VStack(spacing: 18) {
                pickers
                if let a = first, let b = second {
                    if a.id == b.id {
                        sameSelectionNote
                    } else {
                        resultSection(a: a, b: b)
                    }
                }
            }
            .padding(16)
        }
    }

    private var pickers: some View {
        HStack(spacing: 12) {
            personPicker(title: "First", selection: $firstID)
            Image(systemName: "heart.fill")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            personPicker(title: "Second", selection: $secondID)
        }
    }

    private func personPicker(title: String, selection: Binding<UUID?>) -> some View {
        Menu {
            ForEach(profiles) { p in
                Button(p.name) { selection.wrappedValue = p.id }
            }
        } label: {
            VStack(spacing: 6) {
                let chosen = profiles.first { $0.id == selection.wrappedValue }
                ProfileAvatar(initial: chosen?.initial ?? "?", seed: chosen?.colorSeed ?? 0, size: 48)
                Text(chosen?.name ?? "Choose")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(title.uppercased())
                    .font(Theme.rounded(10, .bold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .cardSurface()
        }
        .accessibilityLabel("\(title) person")
    }

    private var sameSelectionNote: some View {
        Text("Pick two different people to compare.")
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .padding()
    }

    private func resultSection(a: Profile, b: Profile) -> some View {
        let result = CompatibilityEngine.compare(a, b, baseOrb: settings.defaultOrb)
        return VStack(spacing: 16) {
            scoreCard(result: result, a: a, b: b)
            summaryCard(result.summary)
            breakdownCard(result.rows)
            countsCard(result)
        }
    }

    private func scoreCard(result: CompatibilityResult, a: Profile, b: Profile) -> some View {
        VStack(spacing: 12) {
            Text("Synastry score")
                .font(Theme.rounded(12, .bold))
                .foregroundStyle(Theme.inkFaint)
            ZStack {
                Circle()
                    .stroke(Theme.hairline, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(result.score) / 100)
                    .stroke(scoreColor(result.score), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(result.score)")
                        .font(Theme.serif(40, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("/ 100")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            .frame(width: 150, height: 150)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Compatibility score \(result.score) out of 100")

            Text("\(a.name) & \(b.name)")
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .cardSurface()
    }

    private func summaryCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "The read", systemImage: "text.book.closed.fill")
            Text(text)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .cardSurface()
    }

    private func breakdownCard(_ rows: [CompatibilityRow]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Breakdown", systemImage: "list.bullet.rectangle")
                .padding(.bottom, 8)
            ForEach(rows) { row in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: row.positive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(row.positive ? Theme.good : Theme.warn)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                        Text(row.detail).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
                if row.id != rows.last?.id {
                    Divider().overlay(Theme.hairline)
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func countsCard(_ result: CompatibilityResult) -> some View {
        HStack(spacing: 12) {
            StatChip(caption: "Flowing", value: "\(result.harmonious)", tint: Theme.good)
            StatChip(caption: "Tense", value: "\(result.challenging)", tint: Theme.warn)
            StatChip(caption: "Aspects", value: "\(result.aspects.count)")
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 65...100: return Theme.good
        case 45..<65: return Theme.gold
        default: return Theme.warn
        }
    }

    private var locked: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Compatibility")
                    .font(Theme.serif(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Compare any two charts cross-aspect by cross-aspect for a real synastry score and a grounded breakdown. It's part of Astra Pro.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: "Unlock Compatibility (\(Pro.priceLabel))", systemImage: "lock.open.fill") {
                    paywallReason = .compatibility
                }
            }
            .padding(28)
        }
    }

    private func defaultSelections() {
        if firstID == nil {
            firstID = ProfileResolver.primary(from: profiles, primaryID: settings.primaryProfileID)?.id
        }
        if secondID == nil {
            secondID = profiles.first { $0.id != firstID }?.id
        }
    }
}

#Preview {
    CompatibilityView()
        .modelContainer(PreviewContainer.shared)
        .environmentObject(AppSettings())
}
