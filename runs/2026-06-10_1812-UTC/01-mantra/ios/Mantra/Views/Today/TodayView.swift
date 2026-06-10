import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("dailySetSize") private var dailySetSize = 5
    @Query private var affirmations: [Affirmation]
    @Query(sort: \PracticeLog.date, order: .reverse) private var logs: [PracticeLog]

    @State private var selection = 0
    @State private var didAffirm: Set<UUID> = []
    @State private var breathe = false

    private var dailySet: [Affirmation] {
        MantraEngine.dailySet(from: affirmations.filter { !$0.isCustom }, count: dailySetSize)
    }

    private var streak: Int { MantraEngine.currentStreak(logs: logs) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(streak > 0 ? Brand.warn : Brand.text3)
                        Text("\(streak)")
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Current streak \(streak) days")
                }
            }
        }
    }

    @ViewBuilder private var content: some View {
        let set = dailySet
        if set.isEmpty {
            EmptyStateView(icon: "sun.max",
                           title: "Preparing your set",
                           message: "Your affirmations for today are being gathered. Pull down to refresh if this lingers.")
        } else {
            VStack(spacing: 0) {
                TabView(selection: $selection) {
                    ForEach(Array(set.enumerated()), id: \.element.id) { index, item in
                        card(for: item)
                            .tag(index)
                            .padding(.horizontal, 22)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(Brand.ease(), value: selection)

                HStack(spacing: 8) {
                    ForEach(0..<set.count, id: \.self) { i in
                        Circle()
                            .fill(i == selection ? Brand.text : Brand.text3.opacity(0.35))
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.vertical, 14)
                .accessibilityHidden(true)
            }
        }
    }

    private func card(for item: Affirmation) -> some View {
        let affirmed = didAffirm.contains(item.id)
        return VStack(spacing: 26) {
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                Image(systemName: item.category.icon)
                    .foregroundStyle(item.category.tint)
                Eyebrow(text: item.category.rawValue)
            }
            ZStack {
                Circle()
                    .fill(item.category.tint.opacity(0.14))
                    .frame(width: 230, height: 230)
                    .scaleEffect(breathe && !reduceMotion ? 1.06 : 0.94)
                    .blur(radius: 2)
                Text(item.text)
                    .font(.system(.title, design: .serif).weight(.medium))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxHeight: 320)

            Spacer(minLength: 8)

            HStack(spacing: 14) {
                Button {
                    toggleFavorite(item)
                } label: {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(item.isFavorite ? Brand.danger : Brand.text2)
                        .frame(width: 56, height: 56)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                }
                .accessibilityLabel(item.isFavorite ? "Remove from favorites" : "Add to favorites")

                Button {
                    affirm(item)
                } label: {
                    Label(affirmed ? "Affirmed" : "I affirm this",
                          systemImage: affirmed ? "checkmark.circle.fill" : "sparkles")
                }
                .buttonStyle(InkButtonStyle())
                .disabled(affirmed)
            }
            .padding(.bottom, 6)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .glassCard(padding: 22)
        .onAppear {
            guard !reduceMotion, !breathe else { return }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { breathe = true }
        }
    }

    private func toggleFavorite(_ item: Affirmation) {
        item.isFavorite.toggle()
        Haptics.selection()
        try? context.save()
    }

    private func affirm(_ item: Affirmation) {
        guard !didAffirm.contains(item.id) else { return }
        context.insert(PracticeLog(text: item.text, category: item.category))
        try? context.save()
        didAffirm.insert(item.id)
        Haptics.success()
    }
}
