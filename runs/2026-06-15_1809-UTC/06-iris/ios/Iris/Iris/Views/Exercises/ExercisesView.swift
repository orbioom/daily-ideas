import SwiftUI

struct ExercisesView: View {
    @AppStorage("isPro") private var isPro = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro
                    ForEach(RoutineCategory.allCases) { category in
                        categorySection(category)
                    }
                    Spacer(minLength: 8)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Exercises")
            .navigationDestination(for: EyeRoutine.self) { routine in
                RoutineDetailView(routine: routine)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Guided routines")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Text("Follow the calm focus dot to relax, strengthen and refocus tired eyes.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func categorySection(_ category: RoutineCategory) -> some View {
        let routines = RoutineCatalog.routines(in: category)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.symbol).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(category.rawValue).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                    Text(category.blurb).font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            if routines.isEmpty {
                Text("More routines coming to this category.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(routines) { routine in
                        routineRow(routine)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func routineRow(_ routine: EyeRoutine) -> some View {
        let unlocked = RoutineCatalog.isFree(routine) || isPro
        if unlocked {
            NavigationLink(value: routine) {
                rowContent(routine, unlocked: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(routine.name), \(routine.totalMinutesLabel)")
        } else {
            Button {
                paywallReason = .routineLocked
            } label: {
                rowContent(routine, unlocked: false)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(routine.name), \(routine.totalMinutesLabel), Pro feature")
        }
    }

    private func rowContent(_ routine: EyeRoutine, unlocked: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 46, height: 46)
                Image(systemName: routine.category.symbol)
                    .font(.system(size: 19))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(routine.name).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                    if !unlocked { ProLockChip() }
                }
                Text(routine.summary)
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Text("\(routine.exercises.count) exercises · \(routine.totalMinutesLabel)")
                    .font(Theme.rounded(11, .medium)).foregroundStyle(Theme.inkFaint)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .cardSurface()
    }
}
