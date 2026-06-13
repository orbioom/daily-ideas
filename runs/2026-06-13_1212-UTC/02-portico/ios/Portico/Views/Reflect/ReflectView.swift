import SwiftUI
import SwiftData

/// The Reflect tab: choose morning or evening, see today's status, pick a
/// template (Pro templates gated), and open the guided flow.
struct ReflectView: View {
    @Environment(ProStore.self) private var pro
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]

    @State private var kind: Reflection.Kind = defaultKindForNow()
    @State private var activeSet: PromptSet?
    @State private var showPaywall = false

    private static func defaultKindForNow() -> Reflection.Kind {
        let hour = Calendar.current.component(.hour, from: .now)
        return (hour >= 17 || hour < 4) ? .evening : .morning
    }

    private func todays(_ k: Reflection.Kind) -> Reflection? {
        let cal = Calendar.current
        return reflections.first { cal.isDateInToday($0.date) && $0.kind == k }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Picker("Reflection kind", selection: $kind) {
                            Text("Morning").tag(Reflection.Kind.morning)
                            Text("Evening").tag(Reflection.Kind.evening)
                        }
                        .pickerStyle(.segmented)

                        if let existing = todays(kind) {
                            existingCard(existing)
                        }

                        Text("Templates")
                            .font(Theme.rounded(14, .bold))
                            .foregroundStyle(Theme.inkSoft)

                        ForEach(PromptLibrary.all(for: kind)) { set in
                            templateRow(set)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $activeSet) { set in
                ReflectFlowView(kind: kind, existing: todays(kind), promptSet: set)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func existingCard(_ entry: Reflection) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Done today", systemImage: "checkmark.circle.fill")
                        .font(Theme.rounded(14, .bold))
                        .foregroundStyle(Theme.good)
                    Spacer()
                    VirtueBadge(virtue: entry.virtue)
                }
                Text(entry.summary)
                    .font(Theme.serif(17, .regular))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(3)
                Button {
                    Haptics.tap()
                    activeSet = PromptLibrary.set(for: entry.promptKey)
                        ?? PromptLibrary.defaultSet(for: kind)
                } label: {
                    Text("Edit today's reflection")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private func templateRow(_ set: PromptSet) -> some View {
        let locked = set.pro && !pro.isPro
        return Button {
            Haptics.tap()
            if locked { showPaywall = true } else { activeSet = set }
        } label: {
            Card {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(set.title)
                                .font(Theme.rounded(17, .bold))
                                .foregroundStyle(Theme.ink)
                            if locked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        Text("\(set.prompts.count) prompts")
                            .font(Theme.rounded(13, .regular))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: locked ? "lock.fill" : "chevron.right")
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(set.title), \(set.prompts.count) prompts\(locked ? ", locked, requires Pro" : "")")
    }
}
