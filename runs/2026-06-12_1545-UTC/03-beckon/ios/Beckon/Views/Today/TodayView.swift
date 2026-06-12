import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \Intention.createdAt, order: .reverse) private var intentions: [Intention]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sessionTarget: SessionTarget?
    @State private var showAdd = false
    @State private var breathe = false

    struct SessionTarget: Identifiable { let id = UUID(); let intention: Intention; let phase: Phase }

    private var active: [Intention] { intentions.filter { $0.state == .active } }
    private var streak: Int { PracticeEngine.streak(intentions: intentions) }
    private var recommended: Phase { Phase.recommended() }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if active.isEmpty {
                    EmptyStateView(symbol: "sparkles",
                                   title: "Set your first intention",
                                   message: "Choose something you're calling into your life, write your affirmation, and begin the 369 ritual.",
                                   actionTitle: "New intention") { showAdd = true }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            dailyCard
                            ForEach(active) { intent in
                                IntentionTodayCard(intention: intent, recommended: recommended) { phase in
                                    sessionTarget = SessionTarget(intention: intent, phase: phase)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if streak > 0 {
                        Label("\(streak)", systemImage: "flame.fill")
                            .font(.subheadline.weight(.bold)).foregroundStyle(Theme.accent)
                            .accessibilityLabel("\(streak) day streak")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New intention")
                }
            }
            .fullScreenCover(item: $sessionTarget) { target in
                SessionView(intention: target.intention, phase: target.phase)
            }
            .sheet(isPresented: $showAdd) { IntentionEditView(intention: nil) }
        }
    }

    private var dailyCard: some View {
        VStack(spacing: 14) {
            Text("Affirmation for today")
                .font(.caption.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            ZStack {
                Circle()
                    .fill(Theme.goldGradient)
                    .frame(width: 14, height: 14)
                    .scaleEffect(breathe && !reduceMotion ? 6 : 3)
                    .opacity(breathe && !reduceMotion ? 0.08 : 0.16)
                Text(AffirmationLibrary.dailyText())
                    .font(.system(.title3, design: .serif).weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(height: 120)
        }
        .frame(maxWidth: .infinity)
        .beckonCard()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) { breathe = true }
        }
    }
}

struct IntentionTodayCard: View {
    @Bindable var intention: Intention
    let recommended: Phase
    let start: (Phase) -> Void

    private var todayLog: PracticeLog? { intention.log(for: Date()) }
    private var allDone: Bool { todayLog?.isComplete ?? false }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                CategoryChip(category: intention.category)
                Spacer()
                Text("Day \(intention.completedDays + (allDone ? 0 : 1)) of \(intention.practiceLength)")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Text(intention.affirmation)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(3)

            HStack(spacing: 12) {
                ForEach(Phase.allCases) { phase in
                    Button { start(phase) } label: {
                        PhaseRing(phase: phase, count: todayLog?.count(for: phase) ?? 0)
                            .overlay(alignment: .topTrailing) {
                                if phase == recommended && (todayLog?.count(for: phase) ?? 0) < phase.target {
                                    Circle().fill(Theme.accent).frame(width: 9, height: 9).offset(x: -6, y: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            if allDone {
                Label("Today complete", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
            } else {
                Button { start(recommended) } label: {
                    Label("Write now · \(recommended.label) (\(recommended.target)×)", systemImage: "pencil.line")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
            }
        }
        .beckonCard()
    }
}
