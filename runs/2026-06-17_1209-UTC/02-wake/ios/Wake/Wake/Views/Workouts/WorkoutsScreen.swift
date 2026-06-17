import SwiftUI
import SwiftData

/// Library of workout templates: built-ins plus the user's custom workouts. Full CRUD.
struct WorkoutsScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SwimWorkout.createdAt, order: .reverse) private var workouts: [SwimWorkout]
    @AppStorage(PrefKey.isPro) private var isPro = false
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true

    @State private var showBuilder = false
    @State private var paywallReason: PaywallReason?

    /// Free tier cap on custom (user-created) workouts.
    private let freeCustomLimit = 2

    private var customCount: Int { workouts.filter { !$0.isBuiltIn }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        attemptNewWorkout()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New workout")
                }
            }
            .sheet(isPresented: $showBuilder) {
                WorkoutBuilderView()
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if workouts.isEmpty {
            EmptyStateView(symbol: "list.bullet.rectangle",
                           title: "No workouts",
                           message: "Built-in workouts usually load on first launch. Tap + to create your own.",
                           actionTitle: "Create a workout") {
                attemptNewWorkout()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    builtInSection
                    customSection
                }
                .padding(20)
            }
        }
    }

    private var builtInSection: some View {
        let builtIns = workouts.filter { $0.isBuiltIn }
        return Group {
            if !builtIns.isEmpty {
                sectionHeader("Built-in", symbol: "sparkles")
                ForEach(builtIns) { workout in
                    NavigationLink {
                        WorkoutDetailView(workout: workout)
                    } label: {
                        WorkoutCard(workout: workout)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var customSection: some View {
        let customs = workouts.filter { !$0.isBuiltIn }
        return Group {
            sectionHeader("Your workouts", symbol: "person.fill")
            if customs.isEmpty {
                Text("Workouts you build appear here.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)
            } else {
                ForEach(customs) { workout in
                    NavigationLink {
                        WorkoutDetailView(workout: workout)
                    } label: {
                        WorkoutCard(workout: workout)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(workout)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(18, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func attemptNewWorkout() {
        // Builder itself is a Pro feature; also enforce the free saved-workout cap.
        if !isPro {
            paywallReason = customCount >= freeCustomLimit ? .unlimited : .builder
            return
        }
        Haptics.tap(hapticsEnabled)
        showBuilder = true
    }

    private func delete(_ workout: SwimWorkout) {
        Haptics.warning(hapticsEnabled)
        context.delete(workout)
        try? context.save()
    }
}

/// A card summarizing a workout template.
struct WorkoutCard: View {
    let workout: SwimWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: workout.type.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(workout.type.hue)
                    .accessibilityHidden(true)
                Text(workout.name)
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
            HStack(spacing: 8) {
                Pill(text: "\(Int(workout.totalDistanceMeters)) m", color: Theme.accent, systemImage: "ruler")
                Pill(text: "\(workout.orderedSets.count) sets", color: Theme.accentDeep, systemImage: "list.number")
                Pill(text: "~\(UnitFormatter.clock(Double(WorkoutMath.estimatedDuration(of: workout.orderedSets))))",
                     color: Theme.inkSoft, systemImage: "clock")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(workout.name), \(Int(workout.totalDistanceMeters)) meters, \(workout.orderedSets.count) sets")
    }
}
