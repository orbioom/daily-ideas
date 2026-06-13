import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(ProStore.self) private var pro
    @Query private var results: [GameResult]
    @State private var starting: TriviaCategory?
    @State private var launch: GameLaunch?
    @State private var showPaywall = false

    static let freePracticePerDay = 5

    private var todayPracticeCount: Int {
        let key = QuizEngine.dayKey(Date())
        return results.filter { $0.mode == .practice && $0.dayKey == key }.count
    }
    private var accuracyByCat: [TriviaCategory: (Double, Int)] {
        var dict: [TriviaCategory: (Double, Int)] = [:]
        for item in StatsEngine.categoryAccuracy(results) { dict[item.category] = (item.accuracy, item.games) }
        return dict
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        if !pro.isPro {
                            HStack {
                                Image(systemName: "info.circle").foregroundStyle(Theme.inkSoft)
                                Text("\(max(0, Self.freePracticePerDay - todayPracticeCount)) free practice rounds left today")
                                    .font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                        ForEach(TriviaCategory.allCases) { cat in
                            Button { tap(cat) } label: { categoryCard(cat) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                }
            }
            .navigationTitle("Categories")
            .sheet(item: $starting) { cat in
                CategoryStartSheet(category: cat, isPro: pro.isPro) { questions, difficulty in
                    starting = nil
                    launch = GameLaunch(questions: questions, mode: .practice, category: cat)
                }
            }
            .fullScreenCover(item: $launch) { g in
                QuizContainerView(questions: g.questions, mode: g.mode, category: g.category)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func tap(_ cat: TriviaCategory) {
        if !pro.isPro && todayPracticeCount >= Self.freePracticePerDay { showPaywall = true; return }
        Haptics.tap()
        starting = cat
    }

    private func categoryCard(_ cat: TriviaCategory) -> some View {
        let stat = accuracyByCat[cat]
        return Card {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.accentSoft).frame(width: 48, height: 48)
                    Image(systemName: cat.icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(cat.label).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                    Text("\(QuestionBank.count(cat)) questions").font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if let stat, stat.1 > 0 {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(Int(stat.0 * 100))%").font(Theme.rounded(18, .bold)).foregroundStyle(Theme.good)
                        Text("accuracy").font(Theme.rounded(10, .medium)).foregroundStyle(Theme.inkSoft)
                    }
                } else {
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }
}

struct CategoryStartSheet: View {
    @Environment(\.dismiss) private var dismiss
    let category: TriviaCategory
    let isPro: Bool
    let onStart: ([PlayableQuestion], Difficulty?) -> Void

    @State private var length = 10
    @State private var difficulty: Difficulty? = nil

    private var available: Int { QuestionBank.count(category) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: category.icon).font(.system(size: 26)).foregroundStyle(Theme.accent)
                        Text(category.label).font(Theme.serif(26, .bold)).foregroundStyle(Theme.ink)
                        Spacer()
                    }
                    .padding(.top, 8)

                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Round length").font(Theme.rounded(14, .bold)).foregroundStyle(Theme.inkSoft)
                            Picker("Length", selection: $length) {
                                Text("10").tag(10)
                                Text("15").tag(15)
                                Text("20").tag(20)
                            }
                            .pickerStyle(.segmented)
                            .disabled(!isPro)
                            if !isPro { Text("Longer rounds are a Pro perk.").font(Theme.rounded(12, .regular)).foregroundStyle(Theme.inkFaint) }
                        }
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Difficulty").font(Theme.rounded(14, .bold)).foregroundStyle(Theme.inkSoft)
                            Picker("Difficulty", selection: $difficulty) {
                                Text("Any").tag(Difficulty?.none)
                                ForEach(Difficulty.allCases) { d in Text(d.label).tag(Difficulty?.some(d)) }
                            }
                            .pickerStyle(.segmented)
                            .disabled(!isPro)
                            if !isPro { Text("Filter by difficulty with Pro.").font(Theme.rounded(12, .regular)).foregroundStyle(Theme.inkFaint) }
                        }
                    }

                    Spacer()

                    Button {
                        let count = isPro ? min(length, max(5, available)) : 10
                        let qs = QuizEngine.practice(category: category, difficulty: isPro ? difficulty : nil, count: count)
                        Haptics.tap()
                        onStart(qs, difficulty)
                    } label: {
                        Label("Start round", systemImage: "play.fill")
                            .font(Theme.rounded(18, .bold)).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
            .navigationTitle("New round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
