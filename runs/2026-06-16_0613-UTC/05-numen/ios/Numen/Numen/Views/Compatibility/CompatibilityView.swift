import SwiftUI
import SwiftData
import Charts

struct CompatibilityView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var idA: String = ""
    @State private var idB: String = ""
    @State private var result: CompatibilityResult?
    @State private var isLoading = false

    private var profileA: Profile? { profiles.first { $0.persistentModelID.storageIdentifier == idA } }
    private var profileB: Profile? { profiles.first { $0.persistentModelID.storageIdentifier == idB } }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                content
            }
            .navigationTitle("Compatibility")
        }
    }

    @ViewBuilder private var content: some View {
        if !isPro {
            ProLockedView(
                symbol: "heart.text.square.fill",
                title: "Compatibility is a Pro feature",
                message: "Compare any two charts and get a transparent harmony score with a per-number breakdown."
            )
        } else if profiles.count < 2 {
            EmptyStateView(
                symbol: "person.2.slash.fill",
                title: "Need two profiles",
                message: "Add at least two profiles to compare their charts."
            )
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    pickers
                    if isLoading {
                        ProgressView("Comparing charts…").tint(Theme.accent)
                            .frame(maxWidth: .infinity, minHeight: 160)
                    } else if let result, profileA != nil, profileB != nil {
                        scoreRing(result)
                        chartCard(result)
                        breakdown(result)
                        summaryCard(result)
                    } else {
                        EmptyStateView(
                            symbol: "arrow.left.arrow.right.circle",
                            title: "Pick two people",
                            message: "Choose two different profiles above to see their harmony."
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private var pickers: some View {
        HStack(spacing: 12) {
            personPicker(title: "First", selection: $idA, exclude: idB)
            Image(systemName: "heart.fill").foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            personPicker(title: "Second", selection: $idB, exclude: idA)
        }
        .padding(.top, 6)
        .onChange(of: idA) { _, _ in Task { await recompute() } }
        .onChange(of: idB) { _, _ in Task { await recompute() } }
        .onAppear(perform: prefill)
    }

    private func personPicker(title: String, selection: Binding<String>, exclude: String) -> some View {
        VStack(spacing: 6) {
            Text(title).font(Theme.rounded(11, .semibold)).foregroundStyle(Theme.inkSoft)
            Menu {
                ForEach(profiles) { profile in
                    let id = profile.persistentModelID.storageIdentifier
                    Button {
                        selection.wrappedValue = id
                    } label: {
                        if id == selection.wrappedValue {
                            Label(profile.displayName, systemImage: "checkmark")
                        } else {
                            Text(profile.displayName)
                        }
                    }
                    .disabled(id == exclude)
                }
            } label: {
                HStack {
                    Text(menuLabel(for: selection.wrappedValue))
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerM))
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerM).stroke(Theme.hairline, lineWidth: 1))
            }
            .accessibilityLabel("\(title) person: \(menuLabel(for: selection.wrappedValue))")
        }
    }

    private func menuLabel(for id: String) -> String {
        profiles.first { $0.persistentModelID.storageIdentifier == id }?.displayName ?? "Choose"
    }

    private func scoreRing(_ result: CompatibilityResult) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(Theme.hairline, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(result.overall) / 100)
                    .stroke(Theme.goldGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(result.overall)")
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text("harmony").font(Theme.rounded(11, .medium)).foregroundStyle(Theme.inkSoft)
                }
            }
            .frame(width: 150, height: 150)
            .padding(.top, 8)
            Text(result.band.rawValue)
                .font(Theme.serif(.title3))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerL))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerL).stroke(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Harmony score \(result.overall) out of 100, \(result.band.rawValue)")
    }

    private func chartCard(_ result: CompatibilityResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agreement by facet")
                .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
            Chart(result.pairs) { pair in
                BarMark(
                    x: .value("Score", pair.score),
                    y: .value("Facet", pair.position.rawValue)
                )
                .foregroundStyle(Theme.goldGradient)
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text("\(pair.score)")
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .chartXScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel().foregroundStyle(Theme.inkSoft)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Theme.ink)
                }
            }
            .frame(height: 160)
            .accessibilityLabel("Bar chart of agreement scores by facet")
            .accessibilityValue(result.pairs.map { "\($0.position.rawValue) \($0.score) percent" }.joined(separator: ", "))
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerL))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerL).stroke(Theme.hairline, lineWidth: 1))
    }

    private func breakdown(_ result: CompatibilityResult) -> some View {
        VStack(spacing: 10) {
            ForEach(result.pairs) { pair in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(pair.position.rawValue)
                            .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(pair.valueA) · \(pair.valueB)")
                            .font(.system(.callout, design: .serif))
                            .foregroundStyle(Theme.accent)
                        Text("\(pair.score)%")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Text(pair.note)
                        .font(.footnote).foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerM))
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerM).stroke(Theme.hairline, lineWidth: 1))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(pair.position.rawValue), \(pair.valueA) and \(pair.valueB), \(pair.score) percent. \(pair.note)")
            }
        }
    }

    private func summaryCard(_ result: CompatibilityResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.headline)
                .font(Theme.serif(.title3)).foregroundStyle(.white)
            Text(result.summary)
                .font(Theme.serif(.body)).foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: Theme.cornerL))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerL).stroke(Theme.accent.opacity(0.4), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func prefill() {
        guard idA.isEmpty || idB.isEmpty else { return }
        if idA.isEmpty {
            idA = ProfileLookup.selected(in: profiles, selectedID: settings.selectedProfileID)?
                .persistentModelID.storageIdentifier ?? (profiles.first?.persistentModelID.storageIdentifier ?? "")
        }
        if idB.isEmpty {
            idB = profiles.first { $0.persistentModelID.storageIdentifier != idA }?
                .persistentModelID.storageIdentifier ?? ""
        }
        Task { await recompute() }
    }

    @MainActor
    private func recompute() async {
        guard let a = profileA, let b = profileB, idA != idB else {
            result = nil
            return
        }
        isLoading = true
        try? await Task.sleep(nanoseconds: 250_000_000)
        result = CompatibilityEngine.compatibility(between: a, and: b, config: settings.engineConfig)
        isLoading = false
        Haptics.impact(.soft, enabled: settings.hapticsEnabled)
    }
}
